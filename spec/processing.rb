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
  context 'processing' do
    it 'expands single-item processes' do
      pending
    end

    it 'expands many-item processes' do
      pending
    end

    it 'allows skipping certain output items' do
      pending
    end
  end
end
