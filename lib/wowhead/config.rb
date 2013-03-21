require 'addressable/template'
require 'addressable/uri'
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

  QUALITY = {
      0 => :poor,
      1 => :common,
      2 => :uncommon,
      3 => :rare,
      4 => :epic,
      5 => :legendary,
      6 => :artifact,
      7 => :heirloom
  }

  RECIPES_TEMPLATE = Addressable::Template.new("http://www.wowhead.com/spells={profession}?filter=minrs={minrs};maxrs={maxrs}")
  ITEM_TEMPLATE = Addressable::Template.new("http://www.wowhead.com/item={id}")

  ZONES_URL = Addressable::URI.parse "http://www.wowhead.com/zones"
  TRADE_URLS = {
    # TODO: dostosować. loading code do poniższych powinien być identyczny
    herbs: Addressable::URI.parse("http://www.wowhead.com/items=7.9"),
    herbs_with_locations: Addressable::URI.parse("http://www.wowhead.com/objects=-3"),
    ores: Addressable::URI.parse("http://www.wowhead.com/items=7.7"),
    ores_with_locations: Addressable::URI.parse("http://www.wowhead.com/objects=-4"),
    cooking: Addressable::URI.parse("http://www.wowhead.com/items=7.8"),
    elemental: Addressable::URI.parse("http://www.wowhead.com/items=7.10"),
    cloth: Addressable::URI.parse("http://www.wowhead.com/items=7.5"),
    enchanting: Addressable::URI.parse("http://www.wowhead.com/items=7.12"),
    leather: Addressable::URI.parse("http://www.wowhead.com/items=7.6"),
  }
  class << self
    def recipes_url profession, rank
      RECIPES_TEMPLATE.expand(
        profession: PROFESSIONS[profession],
        minrs: RANKS[rank].first, maxrs: RANKS[rank].last
      )
    end

    def trades_url type
        TRADE_URLS[type]
    end

    def item_url itemid
        ITEM_TEMPLATE.expand(id: itemid)
    end
  end
end
