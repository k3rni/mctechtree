require 'bundler'
Bundler.setup
require 'net/http'
require 'v8'
require 'pry'
require 'addressable/uri'
require 'addressable/template'
require 'nokogiri'

LISTVIEW = %Q(
  function Listview(data) {
    global_listview.data = data;
  }
)
def setup_context
  V8::Context.new.tap do |c|
    c.eval('window={location: {}, document: {}}')
    c.eval(File.read('jquery-core.js'))
    c.eval('$ = jQuery');
  end
end

Ranks = { apprentice: [0, 74],
  journeyman: [75, 149],
  expert: [150, 224],
  artisan: [225, 299],
  master: [300, 374],
  grand_master: [375,449],
  illustrious: [450, 524],
  zen: [525, 600]
}

Wowhead_professions = {
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
  archeology: "9.794",
  cooking: "9.185",
  first_aid: "9.129",
  # fishing, riding zbędne
}
Wowhead_template = Addressable::Template.new("http://www.wowhead.com/spells={profession}?filter=minrs={minrs};maxrs={maxrs}")

def wowhead_url profession, rank
  Wowhead_template.expand(
    profession: Wowhead_professions[profession],
    minrs: Ranks[rank].first, maxrs: Ranks[rank].last
  )
end

def get_definitions profession, rank
  url = wowhead_url(profession, rank)
  doc = Nokogiri::HTML(Net::HTTP.get(url))
  code = doc.css('#lv-spells ~ script').text
  ctx = setup_context
  g_items = ctx.eval('g_items = {}')
  g_spells = ctx.eval('g_spells = {}')
  global_listview = ctx.eval('global_listview = {}')
  listview = ctx.eval(LISTVIEW)
  ctx.eval(code)

  recipes = global_listview.data.data.map do |obj|
    Hash[obj.map { |key, value| [key, value] }]
  end
  items = Hash[g_items.map do |key, value|
    [key, Hash[value.map { |k, v| [k, v] }]]
  end]

  spells = Hash[g_spells.map do |key, value|
    [key, Hash[value.map { |k, v| [k, v] }]]
  end]

  { items: items, spells: spells, recipes: recipes }
end

# iterujemy po recipes
# recipe.creates => result i makes
# recipe.reagents => ingredients
# metadane: 
#   learnedat: wymagany skill
#   nskillup: ile punktów dodaje
#   source: trainer, starter, drop, vendor, quest, discovery
#   jeśli source=vendor, trzeba klepnąć w stronę spell=recipe.id, wygrzebać pasujący pattern, wygrzebać faction. reputacja chyba tylko w html tooltipie jest 
#   jeśli source=drop, znaleźć pattern jw, zagregować location
#   quality (na itemie) - common, uncommon, rare, epic
binding.pry
