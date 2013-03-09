#! /usr/bin/env ruby
# encoding: utf-8

require 'bundler'
Bundler.setup
Bundler.require
require 'delegate'

# FileUtils.rm_rf Neo4j::Config[:storage_path] 

class CraftBuilder < SimpleDelegator
    def makes count, machine, ingredients
        craft = Craft.create(machine, __getobj__, count, ingredients)
        self.crafts << craft
        craft
    end
end

class Craft
    attr_accessor :machine, :result, :count, :ingredients

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

    def self.primitive name
        self.new(name: name, primitive: true)
    end

    def self.crafted name
        self.new(name: name, primitive: false).tap do |obj|
            crafts = CraftBuilder.new(obj)
            yield(crafts)
        end
    end
end

cobble = Item.primitive "cobblestone"
wood = Item.primitive "wood"
planks = Item.crafted "planks" do |crafts|
    crafts.makes(4, nil, [wood])
end
binding.pry


