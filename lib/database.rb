# encoding: utf-8

class UndefinedItemsError < StandardError; end
class BadDefinitionError < StandardError; end
class NamingConflictError < StandardError; end
class DuplicatePrimitiveError < StandardError; end

autoload :Graph, './lib/graph'
class Database < Set
    include Graph
    def initialize(*args)
        super(*args)
        @pending = Set.new
	@conflicts = Set.new
        @equivalents = Hash.new { |h, key| h[key] = Set.new }
    end

    def find(name)
        select { |obj| obj.name == name }.first
    end

    def crafted
      select { |item| item.crafts.size > 0 }
    end

    def primitives
      select { |item| item.primitive }
    end

    def load_definitions data
      group = data['cluster']
      %w(equivalents primitives craft_templates crafts).each do |key|
        send "load_#{key}", data[key] || {}, group
      end
      self
    end

    def load_primitives definitions, group=nil
      definitions.each do |data|
        name, stacks, cost = parse_primitive(data)
        name = data.keys.first
	if (old = find(name))
	    # no need to flag it, identically named primitives are always equivalent
	    # @conflicts.add [:primitive, name, group, old.group] 
	    next
	else
    	    item = Item.primitive(name, cost, stacks, group)
	end
        self.add item
      end
    end

    def conflicts existing, extra, group
      compatible = extra['compatible']
      return false if compatible == 'all' || existing.compatible == 'all'
      existing.group != group && (compatible.nil? || compatible != existing.group)
    end

    def load_crafts definitions, group=nil
      # TODO: disable and override other recipes, by signature
      definitions.each do |recipe|
        name, makes, machine, ingredients, extra = parse_recipe(recipe)
        item = find(name)

        if item && conflicts(item, extra, group)
          @conflicts.add [:craft, name, group, item.group]
        elsif item
          item.add_craft do |craft|
            craft.makes(makes, machine, ingredients, extra)
          end
        else
          item = Item.crafted name, group, compatible: extra.delete('compatible') do |craft|
            craft.makes(makes, machine, ingredients, extra)
          end
          self.add item
        end
      end
    end

    def load_equivalents definitions, group=nil
      definitions.each do |names|
        nn = Set.new(names)
        nn.each do |name|
          @equivalents[name].merge(nn - [name])
        end
      end
    end

    def load_craft_templates data, group=nil
      pat = /\$\(([^)]+)\)/
      data.each do |recipe|
        name = recipe.keys.first
        definition = recipe.values.first
        keys = name.scan(pat).flatten
        if keys.empty? # name doesn't contain substitutes
          keys = definition.delete('vars')
        end
        substitutions = Hash[keys.map { |key| [key, definition.delete(key)] }]
        all_crafts = []
        build_substitutions(name, definition, substitutions, keys.first, keys[1..-1]) { |obj| all_crafts << obj }
        load_crafts all_crafts, group
      end
    end

    def build_substitutions name, definition, substitutions, key, rest, was_nil=false
        substitutions[key].each do |s|
          if s.nil?
            label = ''
            mat = nil
          elsif s.index('/')
            label, mat = s.split('/')
          else
            label = mat = s
          end
          # if there's no substitutions left (rest is nil), this creates a fully-solved recipe
          # otherwise it will still contain $(substitutions), and get passed on
          new_name = name.sub("$(#{key})", label).strip.gsub('  ', ' ')
          new_def = definition.merge({
            # TODO: this should probably replace all metadata, per type and not only ing and shape
            'ingredients' => replace_list_names(definition['ingredients'], "$(#{key})", mat),
            'shape' => replace_shape_names(definition['shape'], "$(#{key})", mat)
          })
          if rest.nil? || rest.size == 0
            # avoid a combination that was all nils
            if !(was_nil && mat.nil?) 
              yield({new_name => new_def})
            end
          else
            # recursively call with a partially solved recipe
            build_substitutions(new_name, new_def, substitutions, rest.first, rest[1..-1], mat.nil?) { |obj| yield obj }
          end
        end
    end

    def replace_list_names list, old, new
      if list.nil?
        nil
      elsif new.nil?
        list.reject { |el| el == old }
      else
        list.map { |el| el.gsub(old, new) }
      end
    end

    def replace_shape_names shape, old, new
      if shape.nil?
        nil
      elsif new.nil?
        shape.gsub(old, '~') 
      else
        shape.gsub(old, new).gsub('  ', ' ')
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
        stacks = definition['stacks'] 
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
      # TODO: stacks dla przedmiotów craftowanych
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
                false # drop pending item
            else
                true
            end
        end
        # anything left? try the equivalents list
        @pending.select! do |item|
          if (eq = @equivalents[item.name])
            new_item = eq.map { |name| find(name) }.compact.first
            if new_item.nil?
              true
            else
              replace_pending item, new_item
              false
            end
          else
            true
          end
        end
        if @pending.size > 0
          raise UndefinedItemsError.new(@pending.to_a.join(','))
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

    def detect_name_clashes
      if @conflicts.size > 0
        raise NamingConflictError.new(@conflicts.sort_by { |v| v[1] }.map do |mode,name,cluster1,cluster2|
          "#{mode}[#{name}]:#{cluster1},#{cluster2}" 
        end.join("\n"))
      end
    end

    def classify_tiers
      unsolved = Set.new(self)
      primitives.each do |item|
        unsolved -= [item]
        item.tier = 0
      end

      while unsolved.size > 0
        unsolved.each do |item|
          craft_tiers = item.crafts.map do |craft| 
            t = craft.count_ingredients.map { |ing, count| ing.tier }
            if t.include? nil
              nil
            else
              t.max
            end
          end
          unless craft_tiers.include? nil
            min_tier = craft_tiers.flatten.compact.min
            item.tier = min_tier + 1
            unsolved -= [item]
          end
        end
      end
    end
end
