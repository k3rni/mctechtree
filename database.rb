# encoding: utf-8

class UndefinedItemsError < StandardError; end
class BadDefinitionError < StandardError; end

class Database < Set
    include Graph
    def initialize(*args)
        super(*args)
        @pending = Set.new
    end

    def find(name)
        select { |obj| obj.name == name }.first
    end

    def load_definitions data
      group = data['cluster']
      load_primitives(data['primitives'] || {}, group)
      load_crafts(data['crafts'] || {}, group)
      self
    end


    def load_primitives definitions, group=nil
      definitions.each do |data|
        name, stacks, cost = parse_primitive(data)
        name = data.keys.first
        item = Item.primitive(name, data.values.first, stacks, group)
        self.add item
      end
    end

    def load_crafts definitions, group=nil
        # TODO: nadpisywanie i kasowanie starych recept, po sygnaturkach
        definitions.each do |recipe|
          name, makes, machine, ingredients, extra = parse_recipe(recipe)
          item = find(name)
          if item
            item.add_craft do |craft|
              craft.makes(makes, machine, ingredients, extra)
            end
          else
            item = Item.crafted name, group do |craft|
              craft.makes(makes, machine, ingredients, extra)
            end
            self.add item
          end
        end
    end

    def parse_primitive data
      if data.is_a? Hash
        name = data.keys.first
        definition = data.values.first
      end
      if definition.is_a? Numeric
        cost = definition
        stacks = 64
      elsif definition.is_a? Hash
        cost = definition['cost']
        stacks = definition['stacks'] || 64
      end
      [name, stacks, cost]
    end

    def parse_recipe recipe, group=nil
      if recipe.is_a? Hash
        name = recipe.keys.first # YAMLowy format tak ma
        definition = recipe.values.first
      elsif recipe.is_a? Array # para nazwa, ingredients ze skróconej definicji
        name = recipe.first
        definition = recipe.last
      end
      if definition.is_a? Hash
        ingredients = resolve_items(definition.delete('ingredients'))
        makes = definition.delete('makes') || 1
        machine = definition.delete('machine')
        extra = definition
      elsif definition.is_a? Array
        ingredients = resolve_items(definition)
        makes = 1
        machine = nil
        extra = {}
      else
        raise BadDefinitionError.new(name)
      end
      [name, makes, machine, ingredients, extra]
    end

    def fixup_pending
        @pending.select! do |item|
            if (newitem = find(item.name))
                replace_pending item, newitem
                false # wywal z pending
            else
                true
            end
        end
    end

    def replace_pending old, new
        self.each do |item|
            item.crafts.each do |craft|
                craft.replace_ingredients old, new
            end
        end
    end

    def resolve_items names
        names.map do |name|
          if name =~ /(.+?)\*(\d+)/
              name, count = $1, $2.to_i
          else
              count = 1
          end
          item = self.find(name) 
          if item.nil?
              item = @pending.select { |obj| obj.name == name }.first || Item.pending(name).tap { |obj| @pending.add obj }
          end
          [item] * count
        end.flatten
    end

end
