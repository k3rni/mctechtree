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
  GEMS = 

  context "templates" do
    it 'expands single-key recipe templates' do
      template = YAML.load PAINTBRUSH
      recipes = @db.transform_template template
      recipes.should have(6).items
      recipes.map(&:name).should include('paintbrush (red)', 'paintbrush (purple)')
      recipes.map(&:name).should_not include('painbrush (R)')
    end

    it 'expands multi-key recipe templates' do
      pending
    end

    it 'expands non-recipe templates' do
      pending
    end

  end
end
