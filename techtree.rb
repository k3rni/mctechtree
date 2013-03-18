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
autoload :Graph, './graph'

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
            [:craft, (count.to_f / best_craft.craft.makes), best_craft.resolve]
        end
    end

    def explain depth=0
        if item.primitive
            "#{' ' * depth}#{count} #{item.name}"
        else
            "#{' ' * depth}#{(count.to_f / best_craft.craft.makes)} #{best_craft.explain(depth+1)}"
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

class Simplifier
    attr_accessor :raw, :crafts, :craft_seq

    def initialize(solution)
        @solution = solution
        @crafts = Hash.new { |h, key| h[key] = 0 }
        @craft_seq = Hash.new { |h, key| h[key] = 0 }
        @raw = Hash.new { |h, key| h[key] = 0 }
    end

    def process solution, depth, multiplier = 1
        verb, count, tree = solution
        # puts "#{' '*depth}PROCESS: #{verb} * #{count}"
        send verb, depth, multiplier, count, tree
    end

    def get depth, mul, count, item
        # puts "#{' '*depth}GET #{mul} #{count} #{item}"
        @raw[item] += (mul * count)
    end

    def craft depth, mul, count, tree
        # puts "#{' '*depth}CRAFT #{mul} #{count}"
        recipe, tail = tree
        # puts "#{' '*depth}RECIPE #{recipe}"
        @craft_seq[recipe] = [@craft_seq[recipe] || 0, depth].max
        @crafts[recipe] += mul*count
        tail.each do |num, rule|
            process rule, depth+1, mul*count
        end
    end

    def solve
        process @solution, 0
        show_raw
        show_crafts
        nil
    end

    def show_raw
        puts "Resources required:"
        raw.sort_by{|item,count| item.name}.each do |item, count|
            puts "#{item.name} * #{count.ceil}"
        end
    end

    def show_crafts
        ordering = craft_seq.sort_by { |craft, i| i }.reverse
        j, last = 1, ordering.first[1] + 1# max waga
        puts "Recipe:"
        ordering.each do |craft, order|
            count = crafts[craft]
            msg = [(if order < last
                      "#{j}."
                    else
                      ' ' * "#{j}.".size
                    end),
                # NOTE: słabo radzi sobie z ratio < 1
                "craft #{(count * craft.makes).round} #{craft.result} ",
                ("using #{craft.machine} " if craft.machine),
                "from #{craft.describe_ingredients(count)}"
            ].join ''
            j += 1 if order < last
            last = order
            puts msg
        end
    end

end


DB = Database.new
Dir.glob('db/**/*.yml').each do |filename|
    DB.load_definitions YAML.load_file(filename)
end
DB.fixup_pending
DB.dump_graph File.open('techtree.dot', 'w')

def solve name, count=1
    Simplifier.new(ItemResolver.new(DB.find(name), count).resolve).solve
end

solve 'quantum body armor'
binding.pry
