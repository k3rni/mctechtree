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
    attr_accessor :name, :primitive, :cost
    attr_reader :crafts

    def initialize attrs={}
        attrs.each { |key, val| self.send "#{key}=", val }
        @crafts = []
    end

    def to_s
        [
            (primitive ? name.upcase : name),
            ("@#{cost}" unless cost.nil?)
        ].join('')
    end

    def safe_name
        name.gsub(' ', '_')
    end

    def <=> other
        self.name <=> other.name
    end

    def self.primitive name, cost
        self.new(name: name, primitive: true, cost: cost)
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
