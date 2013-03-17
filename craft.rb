# encoding: utf-8

require 'zlib'

class Craft
    attr_accessor :machine, :result, :makes, :ingredients

    def to_s
        ["Craft(",
         "result=#{self.result},",
         ("machine=#{machine}," if machine),
         ("makes=#{self.makes}," if makes > 1),
         "ingredients=#{ingredients.map(&:to_s).join('+')}",
         ")"
        ].join('')
    end

    def hash
        Zlib.crc32 to_s
    end

    def initialize attrs={}
        attrs.each { |key, val| self.send "#{key}=", val }
    end

    def self.create machine, result, makes, ingredients
        self.new(machine: machine, result: result, makes: makes, ingredients: ingredients)
    end

    def count_ingredients
        Hash[ingredients.group_by(&:name).map { |name,items| [items.first, items.size] }]
    end

    def replace_ingredients old, new
        ingredients.map! { |obj| (obj == old ? new : obj) }
    end

    def describe_ingredients mul=1
        count_ingredients.map do |item, count|
            "#{(count*mul).ceil} * #{item.name}"
        end.join(', ')
    end
end
