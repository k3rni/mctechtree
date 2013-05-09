require 'bundler'

Bundler.setup
Bundler.require
autoload :Item, './lib/item'
autoload :Craft, './lib/craft'
autoload :Database, './lib/database'

describe Database do
  before :each do
    @db = Database.new
  end


  PAINTBRUSH = %(paintbrush ($(color)):
    ingredients: [$(color) wool, stick*2]
    color: [R/red, O/orange, Y/yellow, G/green, B/blue, P/purple]  
  )
  TURTLES = %($(peripheral) $(tool) turtle:
    ingredients: [P|$(peripheral), turtle, T|$(tool)]
    shape: ~ ~ ~ T t P ~ ~ ~
    tool: [~, mining/diamond pickaxe, farming/diamond hoe, melee/diamond sword, felling/diamond axe, digging/diamond shovel]
    peripheral: [~, crafty/crafting table, wireless/wireless modem]
  )
  GEM_PROCESSING = %(- inputs: [$(gem) dust*4, industrial TNT*24]
  outputs: [$(gem)*3, dark ashes*12]
  gem: [ruby, sapphire, green sapphire, emerald, olivine]
  vars: [gem]
  )


  context "templates" do
    context "recipes" do
      def recipe_names recipes
        recipes.map { |r| r.keys.first }
      end

      it 'expands single-key templates' do
        template = YAML.load PAINTBRUSH
        recipes = @db.transform_template template
        recipes.should have(6).items
        recipe_names(recipes).should include('paintbrush (R)', 'paintbrush (P)')
        recipe_names(recipes).should_not include('paintbrush (red)') # wrong key expansion
      end

      it 'expands multi-key templates' do
        template = YAML.load TURTLES
        recipes = @db.transform_template template
        recipes.should have(17).items
        recipe_names(recipes).should include('crafty melee turtle', 'wireless felling turtle', 'digging turtle', 'crafty turtle')
        recipe_names(recipes).should_not include('turtle') # all-nil combo
        recipe_names(recipes).should_not include('diamond hoe turtle', 'crafting table turtle') # wrong key expansion
      end
    end

    context "non-recipes" do
      it 'expands templates' do
        template = YAML.load(GEM_PROCESSING).first
        items = @db.transform_template template
        items.should have(5).items
      end
    end

  end
end
