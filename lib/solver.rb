class Solver
    attr_accessor :raw, :crafts, :craft_seq

    def initialize(solutions)
        @solutions = solutions
        @crafts = Hash.new { |h, key| h[key] = 0 }
        @craft_seq = Hash.new { |h, key| h[key] = 0 }
        @raw = Hash.new { |h, key| h[key] = 0 }
    end

    def process solution, depth, multiplier = 1
        verb, count, tree = solution
        # puts "#{' '*depth}PROCESS: #{verb} * #{count}"
        send verb, depth, multiplier, count, tree
    end

    def get depth, mul, count, item
        # puts "#{' '*depth}GET #{mul} #{count} #{item}"
        @raw[item] += (mul * count)
    end

    def craft depth, mul, count, tree
        # puts "#{' '*depth}CRAFT #{mul} #{count}"
        recipe, tail = tree
        # puts "#{' '*depth}RECIPE #{recipe}"
        @craft_seq[recipe] = [@craft_seq[recipe] || 0, depth].max
        new_count = exact_craft(mul * count, recipe.makes)
        @crafts[recipe] += new_count
        tail.each do |num, rule|
            process rule, depth+1, new_count
        end
    end

    def solve
      @solutions.each do |sol|
        process sol, 0
      end
      self
    end

    def describe
      show_raw
      show_crafts
      nil
    end

    def show_raw
        puts "Resources required:"
        raw.sort_by{|item,count| item.name}.each do |item, count|
          stack_info = item.stack_info count.ceil
          puts ["#{item.name} * #{count.ceil}",
                (" (#{stack_info})" if stack_info)].join ''
        end
    end

    def show_crafts
        ordering = craft_seq.sort_by { |craft, i| i }.reverse
        j, last = 1, ordering.first[1] + 1# max waga
        puts "Recipe:"
        ordering.each do |craft, order|
          count = crafts[craft]
          msg = [
            (order < last ?  "#{j}." : ' ' * "#{j}.".size),
            ("using #{craft.machine} " if craft.machine),
            "craft #{(count * craft.makes).round} #{craft.result} ",
            "from #{craft.describe_ingredients(count)}"
          ].join ''
          j += 1 if order < last
          last = order
          puts msg
        end
    end

end

