# encoding: utf-8

class UndefinedItemError < StandardError; end

class CraftBuilder < SimpleDelegator
    def makes count, machine, ingredients, extra
        craft = Craft.create(machine, __getobj__, count, ingredients, extra)
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
    attr_accessor :name, :primitive, :cost, :stacks, :group
    attr_reader :crafts

    def initialize attrs={}
        attrs.each { |key, val| self.send "#{key}=", val }
        @crafts = []
        stacks = 64 if stacks.nil?
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

    def stack_info count
      return nil if @stacks == false
      num, rem = count.divmod(@stacks)
      plural = 's' if num > 1
      if num == 0
        nil
      elsif rem == 0
        # NOTE: marne i18n
        "#{num} stack#{plural}"
      else
        "#{num} stack#{plural} + #{rem}"
      end
    end

    def <=> other
        self.name <=> other.name
    end

    def self.primitive name, cost, stacks, group=nil
        self.new(name: name, primitive: true, cost: cost, stacks: stacks, group: group)
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
