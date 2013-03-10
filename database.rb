# encoding: utf-8

class Database < Set
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
            next if find(name)
            self.add Item.primitive(name, data.values.first)
        end
    end

    def load_crafts data
        # TODO: nadpisywanie i kasowanie starych recept, po sygnaturkach
        data.each do |recipe|
            name = recipe.keys.first # YAMLowy format tak ma
            definition = recipe.values.first
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

    def resolve_items names
        names.map do |name|
            self.find(name) || Item.pending(name)
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
                    fp.puts %Q(#{ing.safe_name} -> #{craft.result.safe_name} [label=#{count}];)
                end
            end
        end
    end
end
