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


  context "templates" do
    it 'expands single-key recipe templates' do
      template = YAML.load PAINTBRUSH
      recipes = @db.transform_template template
      recipes.should have(6).items
      recipes.map{|r| r.keys.first}.should include('paintbrush (R)', 'paintbrush (P)')
      recipes.map{|r| r.keys.first}.should_not include('paintbrush (red)') # wrong key expansion
    end

    it 'expands multi-key recipe templates' do
      template = YAML.load TURTLES
      recipes = @db.transform_template template
      recipes.should have(17).items
      recipes.map{|r| r.keys.first}.should include('crafty melee turtle', 'wireless felling turtle', 'digging turtle', 'crafty turtle')
      recipes.map{|r| r.keys.first}.should_not include('turtle') # all-nil combo
      recipes.map{|r| r.keys.first}.should_not include('diamond hoe turtle', 'crafting table turtle') # wrong key expansion
    end

    it 'expands non-recipe templates' do
      pending
    end

  end
end
