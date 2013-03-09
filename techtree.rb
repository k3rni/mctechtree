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
        @children = item.crafts.map do |craft| 
            CraftResolver.new(craft, count)
        end
    end

    def cost
        if item.primitive
            count
        else
            count * min_child_cost
        end
    end

    def min_child_cost
        @children.map(&:cost).min
    end

    def resolve
        if item.primitive
            [:get, count, item]
        else
            best_craft = @children.select { |c| c.cost == min_child_cost }.first
            [:craft, (count / best_craft.craft.makes).ceil, best_craft.resolve]
        end
    end

end

class CraftResolver
    attr_accessor :craft, :count, :children

    def initialize(craft, count)
        @craft = craft
        @count = count
        @children = craft.count_ingredients.map do |item, needed|
            ItemResolver.new(item, needed)
        end
    end

    def cost
        sum_children_costs.to_f * count / (craft.makes)
    end

    def sum_children_costs
        @children.map(&:cost).inject(0){ |a,b| a + b }
    end

    def resolve
        [craft, @children.map { |ir| [ir.count, ir.resolve] }]
    end

end

def load_data data, database=nil
    database ||= Database.new
    database
end

db = Database.new
db.load_definitions(YAML.load_file('vanilla.yml'))
  .load_definitions(YAML.load_file('ic2.yml'))
binding.pry
