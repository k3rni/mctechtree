def exact_craft need, makes
  p, q = need.divmod(makes)
  if q == 0
    p
  else
    p + 1
  end
end

class UncraftableItemError < StandardError; end

class ItemResolver
    attr_accessor :item, :count, :children
    @@craft_constructor = Proc.new { |*args| CraftResolver.new(*args) }
    
    def initialize(item, count)
      @item = item
      @count = count
      @children = item.crafts.map do |craft| 
        @@craft_constructor.call(craft, count)
      end
    end

    def primitive
      item.primitive
    end

    def craftable
      primitive || craftable_children.size > 0
    end

    def cost
      if primitive
        count * item.cost
      else
        count * min_child_cost
      end
    end

    def craftable_children
      children.select(&:craftable)
    end

    def min_child_cost
      craftable_children.map(&:cost).min
    end
    
    def best_craft
      craftable_children.select { |c| c.cost == min_child_cost }.first
    end

    def resolve
      raise UncraftableItemError if !craftable
      if primitive
        [:get, count, item]
      else
        # [:craft, (count.to_f / best_craft.craft.makes), best_craft.resolve]
        # puts "EC #{best_craft.result} need #{count} / makes #{best_craft.makes} = #{exact_craft count, best_craft.makes}"
        [:craft, exact_craft(count, best_craft.makes), best_craft.resolve]
      end
    end

    def explain depth=0
        if primitive
            "#{' ' * depth}#{count} #{item.name}"
        else
            "#{' ' * depth}#{exact_craft(count, best_craft.makes)} #{best_craft.explain(depth+1)}"
            # "#{' ' * depth}#{(count.to_f / best_craft.craft.makes)} #{best_craft.explain(depth+1)}"
        end
    end

end

class CraftResolver
    attr_accessor :craft, :count, :children
    @@item_constructor = Proc.new { |*args| ItemResolver.new(*args) }

    def initialize(craft, count)
        @craft = craft
        @count = count
        @children = craft.count_ingredients.map do |item, needed|
          @@item_constructor.call(item, needed)
        end
    end

    def craftable
      children.all?(&:craftable)
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
