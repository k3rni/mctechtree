module Primitives
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
end
