#! /usr/bin/env ruby
# encoding: utf-8

require 'bundler'
Bundler.setup
Bundler.require
require 'delegate'
require 'yaml'
require 'set'

autoload :Item, './item'
autoload :Craft, './craft'
autoload :Database, './database'

class ItemResolver
    attr_accessor :item, :count, :children
    
    def initialize(item, count)
        @item = item
        @count = count
    end

end

class CraftResolver; end

def load_data data, database=nil
    database ||= Database.new
    database
end

db = Database.new
db.load_definitions(YAML.load_file('vanilla.yml'))
  .load_definitions(YAML.load_file('ic2.yml'))
binding.pry
