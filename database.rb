# encoding: utf-8

class UndefinedItemsError < StandardError; end

class Database < Set
    def initialize(*args)
        super(*args)
        @pending = Set.new
    end

    def find(name)
        select { |obj| obj.name == name }.first
    end

    def load_definitions data
        load_primitives(data['primitives'])
        load_crafts(data['crafts'])
        self
    end


    def load_primitives data
        data.each do |data|
            name = data.keys.first
            item = Item.primitive(name, data.values.first)
            self.add item
        end
    end

    def load_crafts data
        # TODO: nadpisywanie i kasowanie starych recept, po sygnaturkach
        data.each do |recipe|
            name = recipe.keys.first # YAMLowy format tak ma
            definition = recipe.values.first
            old_item = nil
            item = find(name)
            ingredients = resolve_items(definition['ingredients'])
            if item
                item.add_craft do |craft|
                    craft.makes(definition['makes'] || 1, definition['machine'], ingredients)
                end
            else
                item = Item.crafted name do |craft|
                    craft.makes(definition['makes'] || 1, definition['machine'], ingredients)
                end
                self.add item
            end
        end
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
          item = self.find(name) 
          if item.nil?
              item = @pending.select { |obj| obj.name == name }.first || Item.pending(name).tap { |obj| @pending.add obj }
          end
          item
        end
    end

    def dump_graph fp
        fp.puts "digraph techtree {"
            dump_items fp
            dump_crafts fp
        fp.puts "}"
    end

    def dump_items fp
        self.each do |item|
            fp.puts %Q(#{item.safe_name} [label="#{item.name}"];)
        end
    end

    def dump_crafts fp
        self.each do |item|
            item.crafts.each do |craft|
                craft.count_ingredients.each do |ing, count|
                    fp.puts %Q(#{ing.safe_name} -> #{craft.result.safe_name} [label="#{count}#{(' ' + craft.machine) if craft.machine}"];)
                end
            end
        end
    end
end
