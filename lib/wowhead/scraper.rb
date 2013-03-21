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
        c.eval 'fi_addUpgradeIndicator = {}'
        c.eval 'g_trackEvent = {}'
        block.call(c) if block != nil
      end
    end

    def default_context &block
        lv, g_items, g_spells = nil
        setup_context do |ctx|
            lv = ctx.eval('global_listview = {}')
            g_items = ctx.eval('g_items = {}')
            g_spells = ctx.eval('g_spells = {}')
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
        url = recipes_url profession, rank
        code = fetch_code url, '#lv-spells ~ script'
        ctx = setup_context
        g_items = ctx.eval('g_items = {}')
        g_spells = ctx.eval('g_spells = {}')
        lv = ctx.eval('global_listview = {}')
        ctx.eval(LISTVIEW)
        ctx.eval(code)

        recipes = to_ruby_val lv.data.data
        items = to_ruby_val g_items

        parse_recipes recipes, items
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

    def get_ores
        code = fetch_code trades_url(:ores), '#lv-items ~ script'
        objects, items, spells = default_context do |ctx|
            ctx.eval(code)
        end

        code = fetch_code trades_url(:ores_with_locations), '#lv-objects ~ script'
        extra_objects, _i, _s = default_context do |ctx|
            ctx.eval(code)
        end

        merged_items = merge_hl items, extra_objects, 'name_enus', 'name'

        @@zones ||= get_zones
        reject_crafted parse_objects(objects, merged_items, @@zones)
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

    def advanced_loader category, extracat
        code = fetch_code trades_url(category), '#lv-items ~ script'
        objects, items, spells = default_context do |ctx|
            ctx.eval(code)
        end

        code = fetch_code trades_url(extracat), '#lv-objects ~ script'
        extra_objects, _i, _s = default_context do |ctx|
            ctx.eval(code)
        end

        merged_items = merge_hl items, extra_objects, 'name_enus', 'name'

        @@zones ||= get_zones
        parse_objects(objects, merged_items, @@zones)
    end

    def get_cooking_ingredients
        reject_crafted basic_loader(:cooking)
    end

    def get_elemental
        reject_crafted basic_loader(:elemental)
    end

    def get_ores
        reject_crafted advanced_loader(:ores, :ores_with_locations)
    end

    def get_herbs
        reject_crafted advanced_loader(:herbs, :herbs_with_locations)
    end

    def get_cloth
        reject_crafted basic_loader(:cloth)
    end

    def get_enchanting
        reject_crafted basic_loader(:enchanting)
    end

    def get_leather
        reject_crafted basic_loader(:leather)
    end
  end
end
