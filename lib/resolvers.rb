def exact_craft need, makes
  p, q = need.divmod(makes)
  if q == 0
    p
  else
    p + 1
  end
end

class ItemResolver
    attr_accessor :item, :count, :children
    
    def initialize(item, count=1)
      @item = item
      @count = count
      @children = item.crafts.map do |craft| 
        CraftResolver.new(craft, count)
      end
    end

    def cost
      if item.primitive
        count * item.cost
      else
        count * min_child_cost
      end
    end

    def min_child_cost
      @children.map(&:cost).min
    end
    
    def best_craft
      @children.select { |c| c.cost == min_child_cost }.first
    end

    def resolve
      if item.primitive
        [:get, count, item]
      else
        # [:craft, (count.to_f / best_craft.craft.makes), best_craft.resolve]
        # puts "EC #{best_craft.result} need #{count} / makes #{best_craft.makes} = #{exact_craft count, best_craft.makes}"
        [:craft, exact_craft(count, best_craft.makes), best_craft.resolve]
      end
    end

    def explain depth=0
        if item.primitive
            "#{' ' * depth}#{count} #{item.name}"
        else
            "#{' ' * depth}#{exact_craft(count, best_craft.makes)} #{best_craft.explain(depth+1)}"
            # "#{' ' * depth}#{(count.to_f / best_craft.craft.makes)} #{best_craft.explain(depth+1)}"
        end
    end

end

class CraftResolver
    attr_accessor :craft, :count, :children

    def initialize(craft, count)
        @craft = craft
        @count = count
        @children = craft.count_ingredients.map do |item, needed|
            ItemResolver.new(item, needed)
        end
    end

    def cost
      # NOTE: waga musi być bez exact_craft
      sum_children_costs.to_f * count / makes
    end

    def makes
      craft.makes
    end

    def result
      craft.result
    end

    def sum_children_costs
        @children.map(&:cost).inject(0){ |a,b| a + b }
    end

    def resolve
        [craft, @children.map { |ir| [ir.count, ir.resolve] }]
    end

end

