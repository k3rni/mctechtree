# encoding: utf-8

require 'zlib'
require 'active_support/core_ext/array'

class Craft
    attr_accessor :machine, :result, :makes, :ingredients, :group
    attr_accessor :shape, :shape_map
		attr_accessor :requires
    attr_accessor :overrides
    attr_accessor :tag

    def to_s
        "#{self.class}(" + [
         "result=#{self.result}",
         ("makes=#{self.makes}" if makes > 1),
         "ingredients=#{count_ingredients.map{|k,v| "#{k}*#{v}"}.join('+')}",
         metadata.map{|k,v| "#{k}=#{v}"},
        ].flatten.compact.join(' ') + ")"
    end

    def metadata
       %w(machine group requires overrides tag).map do |key|
         v = send(key)
         v.nil? ? nil : [key, v]
       end.compact
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
        self.shape_map = Hash[shape_map.map { |key, obj| [key, (obj == old ? new : obj)] }] unless shape_map.nil?
    end

    def describe_ingredients mul=1
        count_ingredients.map do |item, count|
          if item.liquid
            op = 'mB'
          else
            op = ' *'
          end
          "#{(count*mul).ceil}#{op} #{item.name}"
        end.join(', ')
    end

    def needs? item
        count_ingredients.keys.include? item
    end

    def deep_needs? item
        needs?(item) || count_ingredients.keys.any? do |ing|
          if ing.primitive
            false
          else
            ing.crafts.any? { |cr| cr.deep_needs?(item) }
          end
        end
    end

    def grid
      return nil if shape.nil?
      # TODO: reprezentacja shapeless?
      return [ingredients] if shape == :shapeless
      items = shape.split.map do |prefix| 
        prefix.nil? ? nil : ((shape_map && shape_map[prefix]) || find_ingredient_by_prefix(prefix))
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
      %w(keeps compatible structure).include? key
    end

    # A craft is overriden when another craft for the same item (must be compatible)
    # declares either of:
    # * that it overrides all other crafts from a group(cluster)
    # * overrides a specific recipe, by use of a tag
    def matches_overrides keys
      keys.any? do |key| 
        key == "#{group}/#{tag}" ||
        key == group
      end
    end
end
