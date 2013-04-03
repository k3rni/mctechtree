# encoding: utf-8

require 'zlib'
require 'active_support/core_ext/array'

class Craft
    attr_accessor :machine, :result, :makes, :ingredients, :shape, :group

    def to_s
        ["Craft(",
         "result=#{self.result},",
         ("machine=#{machine}," if machine),
         ("makes=#{self.makes}," if makes > 1),
         "ingredients=#{count_ingredients.map{|k,v| "#{k}*#{v}"}.join('+')},",
         "group=#{self.group}",
         ")"
        ].join('')
    end

    def hash
        Zlib.crc32 to_s
    end

    def initialize attrs={}
        attrs.each do |key, val|
          self.send "#{key}=", val unless Craft.unsupported? key
        end
    end

    def self.create machine, result, makes, ingredients, group, extra={}
        opts = {machine: machine, result: result, makes: makes, ingredients: ingredients, group: group}.merge extra
        if opts.delete('shapeless')
          opts[:shape] = :shapeless
        end
        self.new opts
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

    def grid
      return nil if shape.nil?
      # TODO: reprezentacja shapeless?
      return [ingredients] if shape == :shapeless
      items = shape.split.map do |prefix| 
        prefix.nil? ? nil : find_ingredient_by_prefix(prefix) 
      end
      if items.size == 9
        return items.in_groups_of 3
      elsif items.size == 4
        return items.in_groups_of 2
      end
    end

    def find_ingredient_by_prefix prefix
      ingredients.select { |item| item.name =~ %r(^#{prefix}) }.first
    end

    def self.unsupported? key
      %w(keeps compatible).include? key
    end
end
