# encoding: utf-8

class Craft
    attr_accessor :machine, :result, :count, :ingredients

    def to_s
        ["Craft(",
         "result=#{self.result},",
         ("machine=#{machine}," if machine),
         ("count=#{self.count}," if count > 1),
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

    def count_ingredients
        Hash[ingredients.group_by(&:name).map { |name,items| [items.first, items.size] }]
    end
end
