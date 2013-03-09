#! /usr/bin/env ruby
# encoding: utf-8

require 'bundler'
Bundler.setup
Bundler.require
require 'delegate'
require 'yaml'
require 'set'

class UndefinedItemError < StandardError; end

class CraftBuilder < SimpleDelegator
    def makes count, machine, ingredients
        craft = Craft.create(machine, __getobj__, count, ingredients)
        self.crafts << craft
        craft
    end
end

class Database < Set
    def find(name)
        select { |obj| obj.name == name }.first
    end

    def load_definitions data
        load_primitives(data['primitives'])
        load_crafts(data['crafts'])
        self
    end

    def load_primitives names
        names.each do |name|
            next if find(name)
            self.add Item.primitive(name)
        end
    end

    def load_crafts data
        data.each do |recipe|
            name = recipe.keys.first # YAMLowy format tak ma
            definition = recipe.values.first
            item = find(name)
            ingredients = resolve_items(definition['ingredients'])
            if item
                item.add_craft do |craft|
                    craft.makes(definition['makes'], definition['machine'], ingredients)
                end
            else
                item = Item.crafted name do |craft|
                    craft.makes(definition['makes'], definition['machine'], ingredients)
                end
                self.add item
            end
        end
    end

    def resolve_items names
        names.map do |name|
            self.find(name) || Item.pending(name)
        end
    end
end

class Craft
    attr_accessor :machine, :result, :count, :ingredients

    def to_s
        ["Craft(",
         "result=#{self.result},",
         ("machine=#{machine}," if machine),
         "ingredients=#{ingredients.map(&:to_s).join('+')}",
         ")"
        ].join('')
    end

    def initialize attrs={}
        attrs.each { |key, val| self.send "#{key}=", val }
    end

    def self.create machine, result, count, ingredients
        self.new(machine: machine, result: result, count: count, ingredients: ingredients)
    end
end

class Item
    attr_accessor :name, :primitive
    attr_reader :crafts

    def initialize attrs={}
        attrs.each { |key, val| self.send "#{key}=", val }
        @crafts = []
    end

    def to_s
        if primitive
            name.upcase
        else
            name
        end
    end

    def self.primitive name
        self.new(name: name, primitive: true)
    end

    def self.crafted name
        self.new(name: name, primitive: false).tap do |obj|
            crafts = CraftBuilder.new(obj)
            yield(crafts)
        end
    end

    def self.pending name
        raise UndefinedItemError.new(name)
    end

    def add_craft
        yield(CraftBuilder.new(self))
    end

    def tree
        if primitive
            self
        else

        end
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
