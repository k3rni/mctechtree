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
  BIOCELL = %Q(bio cell: [cell, compressed plantclump])
  CELL = %Q(cell:
    makes: 16
    ingredients: [tin ingot*4]
    shape: |
      ~ t ~
      t ~ t
      ~ t ~
  )
  IO_PORT = %Q(ME IO port:
    ingredients: [glass*3, D|ME drive*2, C|ME cable, b|ME basic processor, iron*2]
    shape: g g g D C D i b i
  )

  context "recipe parser" do
    it "understands short recipe" do
      recipe = YAML.load BIOCELL
      name, makes, machine, ingredients, extra = @db.parse_recipe recipe
      name.should == 'bio cell'
      makes.should == 1
      machine.should be_nil
      ingredients.should have(2).items
      ingredients.map(&:name).should include('cell', 'compressed plantclump')
      extra.should be_empty
    end

    it "understands basic shape" do
      recipe = YAML.load CELL
      name, makes, machine, ingredients, extra = @db.parse_recipe recipe
      name.should == 'cell'
      makes.should == 16
      machine.should be_nil
      ingredients.should have(4).items
      ingredients.uniq.should have(1).items
      ingredients.first.name.should == 'tin ingot'
      extra.should include('shape')
      extra.should_not include('shape_map')
      extra['shape'].gsub(/\s+/, ' ').strip.should == '~ t ~ t ~ t ~ t ~'
    end

    it "understands prefixed shape" do
      recipe = YAML.load IO_PORT
      name, makes, machine, ingredients, extra = @db.parse_recipe recipe
      name.should == 'ME IO port'
      makes.should == 1
      machine.should be_nil
      ingredients.should have(9).items
      ingredients.map(&:name).should include('glass', 'ME drive', 'ME cable', 'ME basic processor', 'iron')
      extra.should include('shape')
      extra['shape'].gsub(/s+/, ' ').strip.should == 'g g g D C D i b i'
      extra.should include('shape_map')
      extra['shape_map'].should include('D', 'C', 'b')
      extra['shape_map']['D'].name.should == 'ME drive'
      extra['shape_map']['C'].name.should == 'ME cable'
      extra['shape_map']['b'].name.should == 'ME basic processor'
    end
  end
end
