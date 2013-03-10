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
    
    def initialize(item, count=1)
        @item = item
        @count = count
        @children = item.crafts.map do |craft| 
            CraftResolver.new(craft, count)
        end
    end

    def cost
        if item.primitive
            count * item.cost
        else
            count * min_child_cost
        end
    end

    def min_child_cost
        @children.map(&:cost).min
    end
    
    def best_craft
        @children.select { |c| c.cost == min_child_cost }.first
    end

    def resolve
        if item.primitive
            [:get, count, item]
        else
            [:craft, (count.to_f / best_craft.craft.makes).ceil, best_craft.resolve]
        end
    end

    def explain depth=0
        if item.primitive
            "#{' ' * depth}#{count} #{item.name}"
        else
            "#{' ' * depth}#{(count.to_f / best_craft.craft.makes).ceil} #{best_craft.explain(depth+1)}"
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

    def explain depth=0
        [ "craft #{craft.result.name} ",
          ("using #{craft.machine} " if craft.machine),
          "from (\n",
          @children.map do |ir| 
            ir.explain(depth+1) 
          end.join(",\n#{' '*depth}"),
          ")"
        ].join('')
    end

end

def load_data data, database=nil
    database ||= Database.new
    database
end

db = Database.new
db.load_definitions(YAML.load_file('vanilla.yml'))
  .load_definitions(YAML.load_file('ic2.yml'))
  .load_definitions(YAML.load_file('ic2-armor.yml'))

db.dump_graph File.open('techtree.dot', 'w')
binding.pry
