require 'active_support/core_ext/hash'
require 'net/http'
require 'v8'
require 'addressable/uri'
require 'addressable/template'
require 'nokogiri'

module Wowhead
  LISTVIEW = %Q(
      function Listview(data) {
        global_listview.data = data;
      }
  )

  RANKS = { apprentice: [0, 74],
    journeyman: [75, 149],
    expert: [150, 224],
    artisan: [225, 299],
    master: [300, 374],
    grand_master: [375,449],
    illustrious: [450, 524],
    zen: [525, 600]
  }

  SOURCES = {
    10 => :starter,
    6 => :trainer,
    2 => :drop,
    5 => :vendor,
    1 => :crafted,
    7 => :discovery,
    4 => :quest
  }
  PROFESSIONS = {
    alchemy: "11.171",
    blacksmithing: "11.174",
    enchanting: "11.333",
    engineering: "11.202",
    # herbalism: "11.182", # zbieractwo, więc niepotrzebne
    inscription: "11.773",
    jewelcrafting: "11.755",
    leatherworking: "11.165",
    # mining: "11.186", # zbieractwo jw
    # skinning: "11.393",
    tailoring: "11.197",
    # archeology: "9.794",
    cooking: "9.185",
    first_aid: "9.129",
    # fishing, riding zbędne
  }

  RECIPES_TEMPLATE = Addressable::Template.new("http://www.wowhead.com/spells={profession}?filter=minrs={minrs};maxrs={maxrs}")

  ZONES_URL = Addressable::URI.parse "http://www.wowhead.com/zones"
  TRADE_URLS = {
    # herbs: Addressable::URI.parse "http://www.wowhead.com/objects=-3",
    # TODO: dostosować. loading code do poniższych powinien być identyczny
    herbs: Addressable::URI.parse "http://www.wowhead.com/items=7.9",
    ores: Addressable::URI.parse "http://www.wowhead.com/objects=-4",
    cooking: Addressable::URI.parse "http://www.wowhead.com/items=7.8",
    elemental: Addressable::URI.parse "http://www.wowhead.com/items=7.10",
    cloth: Addressable::URI.parse "http://www.wowhead.com/items=7.5",
    enchanting: Addressable::URI.parse "http://www.wowhead.com/items=7.12",
    leather: Addressable::URI.parse "http://www.wowhead.com/items=7.6",
    leather: Addressable::URI.parse "http://www.wowhead.com/items=7.6",
  }
  class << self
    def recipes_url profession, rank
      RECIPES_TEMPLATE.expand(
        profession: PROFESSIONS[profession],
        minrs: RANKS[rank].first, maxrs: RANKS[rank].last
      )
    end

    def setup_context
      V8::Context.new.tap do |c|
        c.eval('window={location: {}, document: {}}')
        c.eval(File.read('jquery-core.js'))
        c.eval('$ = jQuery');
      end
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
      url = recipes_url(profession, rank)
      doc = Nokogiri::HTML(Net::HTTP.get(url))
      code = doc.css('#lv-spells ~ script').text
      ctx = setup_context
      g_items = ctx.eval('g_items = {}')
      g_spells = ctx.eval('g_spells = {}')
      global_listview = ctx.eval('global_listview = {}')
      ctx.eval(LISTVIEW)
      ctx.eval(code)

      recipes = to_ruby_val global_listview.data.data
      items = to_ruby_val g_items
      spells = to_ruby_val g_spells
      # { items: items, spells: spells, recipes: recipes }
      parse_recipes recipes, items
    end

    def extract_recipe_metadata obj
      { 
        colors: obj['colors'],
        learned_at: obj['learnedat'],
        skillups: obj['nskillup'],
        sources: if obj['source']
                   obj['source'].map {|srcid| Wowhead::SOURCES[srcid].to_s }
                 else
                   nil
                 end
      }
    end

    def lookup_item itemlist, objid
      return nil if objid.nil?
      itemlist[objid]['name_enus']
    end

    def format_reagents reagent_list
      reagent_list.map do |item, count|
        if count == 1
          item
        else
          "#{item}*#{count}"
        end
      end
    end

    def parse_recipes raw_recipes, raw_items
      raw_recipes.map do |obj|
        itemnum, count, _x = obj['creates']
        metadata = extract_recipe_metadata obj
        result_name = lookup_item raw_items, itemnum
        next if result_name.nil?
        reagents = obj['reagents'].to_a.map do |itemid, num|
          [lookup_item(raw_items, itemid), num]
        end
        {result_name => { makes: count, ingredients: format_reagents(reagents), meta: metadata.stringify_keys }.stringify_keys}
      end.compact
    end

    def get_herbs
      url = HERBS_URL
      doc = Nokogiri::HTML(Net::HTTP.get(url))
      code = doc.css('#lv-objects ~ script').text
      ctx = setup_context
      global_listview = ctx.eval('global_listview = {}')
      ctx.eval(LISTVIEW)
      ctx.eval(code)

      objects = to_ruby_val global_listview.data.data
      zones = get_zones
      parse_herbs objects, zones
    end

    def parse_herbs raw_herbs, zones
      raw_herbs.map do |obj|
        name = obj['name']
        meta = { 
          skill: obj['skill'], 
          location: obj['location'].to_a.map { |z| zones[z]['name'] rescue nil }.compact
        }
        {name => {cost: 1}.merge(meta).stringify_keys}
      end
    end

    def get_zones
      url = ZONES_URL
      doc = Nokogiri::HTML(Net::HTTP.get(url))
      code = doc.css('#lv-zones ~ script').text
      ctx = setup_context
      global_listview = ctx.eval('global_listview = {}')
      ctx.eval(LISTVIEW)
      ctx.eval(code)

      raw_zones = to_ruby_val global_listview.data.data
      parse_zones raw_zones
    end

    def parse_zones zonedefs
      Hash[zonedefs.map do |zone|
        [zone['id'], { 'name' => zone['name'] }]
        # reszta? może, na razie zbędne
      end]
    end

    def get_ores
      # TODO
    end

    def get_cooking_ingredients
      # mięsa, ryby, warzywa itp
      # TODO
    end
  end
end
