require 'active_support/core_ext/hash'
require 'net/http'
require 'v8'
require 'addressable/uri'
require 'addressable/template'
require 'nokogiri'

module Wowhead
  class << self

    def setup_context &block
      V8::Context.new.tap do |c|
        c.eval 'window={location: {}, document: {}}' # DOM dla ubogich
        c.eval File.read('jquery-core.js')
        c.eval '$ = jQuery'
        # wowheadowe cuda, bez nich się czasem wywala
        c.eval 'fi_addUpgradeIndicator = {}'
        c.eval 'fi_extraCols = {}'
        c.eval 'fi_getExtraCols = function() {}'
        c.eval 'g_trackEvent = function() {}'
        c.eval '$WH = {sprintf: function() {}}'
        c.eval 'LANG = {}'
        block.call(c) if block != nil
      end
    end

    def default_context &block
      lv, g_items, g_spells = nil
      setup_context do |ctx|
        lv = ctx.eval('global_listview = {}')
        g_items = ctx.eval('g_items = {}')
        g_spells = ctx.eval('g_spells = {}')
        # występuje czasem na stronach z cenami
        g_currencies = ctx.eval('g_gatheredcurrencies = {}')
        ctx.eval(LISTVIEW)
        block.call(ctx)
      end
      [to_ruby_val(lv.data.data), to_ruby_val(g_items), to_ruby_val(g_spells)]
    end

    def to_ruby_val v8obj
      if v8obj.is_a? V8::Array
        to_ruby_array v8obj
      elsif v8obj.is_a? V8::Object
        to_ruby_hash v8obj
      else
        v8obj
      end
    end

    def to_ruby_hash v8obj
      Hash[v8obj.map { |key, value| [to_ruby_val(key), to_ruby_val(value)] }]
    end

    def to_ruby_array v8obj
      v8obj.map { |item| to_ruby_val(item) }
    end


    def get_recipes profession, rank
      code = fetch_code recipes_url(profession, rank), '#lv-spells ~ script'
      objects, items, spells = default_context do |ctx|
        ctx.eval(code)
      end

      parse_recipes objects, items, (profession == :enchanting)
    end

    def fetch_code url, selector
      doc = Nokogiri::HTML(Net::HTTP.get url)
      doc.css(selector).text
    end

    def reject_crafted items
      items.reject do |obj|
        values = obj.values.first # taki format
        values['sources'] && values['sources'].include?('crafted')
      end
    end

    def get_zones
      code = fetch_code ZONES_URL, '#lv-zones ~ script'
      # TODO: podmienić na default_context
      ctx = setup_context
      global_listview = ctx.eval('global_listview = {}')
      ctx.eval(LISTVIEW)
      ctx.eval(code)

      raw_zones = to_ruby_val global_listview.data.data
      parse_zones raw_zones
    end


    def basic_loader category
      code = fetch_code trades_url(category), '#lv-items ~ script'
      objects, items, spells = default_context do |ctx|
        ctx.eval(code)
      end

      @@zones ||= get_zones
      parse_objects(objects, items, @@zones)
    end

    def advanced_loader category, extracat, merge_func
      code = fetch_code trades_url(category), '#lv-items ~ script'
      objects, items, spells = default_context do |ctx|
        ctx.eval(code)
      end

      code = fetch_code trades_url(extracat), '#lv-objects ~ script'
      extra_objects, _i, _s = default_context do |ctx|
        ctx.eval(code)
      end

      # w herbs to i działa, ale w ores nazwy obiektów nie pokrywają się z nazwami itemów
      # np: tin ore -> tin vein, saronite ore -> rich/poor saronite deposit
      binding.pry
      merged_items = merge_func.call items, extra_objects

      @@zones ||= get_zones
      parse_objects(objects, merged_items, @@zones)
    end

    def get_ores
      reject_crafted advanced_loader(:ores, :ores_with_locations, method(:merge_herbs))
    end

    def get_herbs
      reject_crafted advanced_loader(:herbs, :herbs_with_locations, method(:merge_herbs))
    end
    
    def get_elemental
      # primale są crafted (ale nie z recki), nie można więc ich olać
      basic_loader :elemental
    end

    def get_devices
      basic_loader :devices
    end

    def method_missing name, *args
      if name =~ /get_(.*)/
        mode = $1.to_sym
        if TRADE_URLS.include?(mode)
          reject_crafted basic_loader(mode)
        end
      else
        super(name, *args)
      end
    end

  end
end
