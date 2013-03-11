# encoding: utf-8

class UndefinedItemError < StandardError; end

class CraftBuilder < SimpleDelegator
    def makes count, machine, ingredients
        craft = Craft.create(machine, __getobj__, count, ingredients)
        self.crafts << craft
        craft
    end
end

class PendingItem
    attr_accessor :name

    def initialize name
        @name = name
    end

    def hash
        to_s.hash
    end

    def <=> other
        self.name <=> other.name
    end

    def to_s
        "!#{name}"
    end

    def safe_name
        "!#{ActiveSupport::Inflector.underscore name}".gsub(' ', '_')
    end
end

class Item
    attr_accessor :name, :primitive, :cost, :group
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
        # ostatni gsub bo dot marudzi
        ActiveSupport::Inflector.underscore(name).gsub(' ', '_').gsub(/(^[0-9])/, "n_\\1")
    end

    def <=> other
        self.name <=> other.name
    end

    def self.primitive name, cost, group=nil
        self.new(name: name, primitive: true, cost: cost, group: group)
    end

    def self.crafted name, group=nil
        self.new(name: name, primitive: false, group: group).tap do |obj|
            crafts = CraftBuilder.new(obj)
            yield(crafts)
        end
    end

    def self.pending name
        PendingItem.new(name)
    end

    def add_craft
        yield(CraftBuilder.new(self))
    end

    def resolver
        ItemResolver.new(self)
    end
end
