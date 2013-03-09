# encoding: utf-8

class UndefinedItemError < StandardError; end

class CraftBuilder < SimpleDelegator
    def makes count, machine, ingredients
        craft = Craft.create(machine, __getobj__, count, ingredients)
        self.crafts << craft
        craft
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

    def <=> other
        self.name <=> other.name
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
end
