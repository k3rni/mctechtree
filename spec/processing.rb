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

  WATER = %Q(- machine: chemical reactor
  inputs: [hydrogen cell*4, compressed air cell]
  outputs: [water cell*5]
            )
  ELECTROLYSIS = %Q(- inputs: [electrolyzed water cell*6]
  outputs: [hydrogen cell*4, compressed air cell, cell]
  skip-output: [cell]
  machine: industrial electrolyzer
                   )


  context 'processing' do
    it 'understands single-output processing' do
      recipe = YAML.load(WATER).first
      @db.load_single_process recipe, 'test'
      @db.should have(1).crafted
      item = @db.crafted.first
      item.name.should == 'water cell'
      item.should have(1).crafts
      craft = item.crafts.first
      craft.count_ingredients.keys.map(&:name).should include('hydrogen cell', 'compressed air cell')
      craft.machine.should == 'chemical reactor'
    end

    it 'understands multi-output processing' do
      recipe = YAML.load(ELECTROLYSIS).first
      @db.load_single_process recipe, 'test'
      @db.should have(2).crafted # not 3 - cell should be skipped
      @db.crafted.map(&:name).should include('hydrogen cell', 'compressed air cell')
      @db.find('cell').should be_nil
    end
  end
end
