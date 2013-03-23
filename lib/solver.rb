require 'ostruct'

class Solver
    attr_accessor :raw, :crafts, :craft_seq, :stash

    def initialize(solutions)
        @solutions = solutions
        @crafts = Hash.new { |h, key| h[key] = 0 }
        @stash = Hash.new { |h, key| h[key] = 0 }
        @craft_seq = Hash.new { |h, key| h[key] = 0 }
        @raw = Hash.new { |h, key| h[key] = 0 }
    end

    def process solution, depth, multiplier = 1
        verb, count, tree = solution
        # puts "#{' '*depth}PROCESS: #{verb} * #{count}"
        send verb, depth, multiplier, count, tree
    end

    def get depth, mul, count, item
        puts "#{' '*depth}GET[#{item}] += #{mul} * #{count}"
        @raw[item] += (mul * count)
    end

    # TODO: 
    # 1. craft sprawdza ile jest resulta w stashu
    # 2. jeśli wystarczająco, odejmuje ze stasha i nie craftuje
    # 3. jeśli niewystarczająco, craftuje tyle ile trzeba i dodaje do stasha
    def craft depth, mul, count, tree
        puts "#{' '*depth}CRAFT #{mul} #{count}"
        recipe, tail = tree
        @craft_seq[recipe] = [@craft_seq[recipe] || 0, depth].max
        # ile potrzebuję?
        if request_craft recipe, mul, count
            tail.each do |num, rule|
                process rule, depth+1, n
            end
        end
    end

    # jeśli craft potrzebny, dolicz go w odpowiedniej ilości i zwróć true
    # jeśli niepotrzebny, zwróć false
    def request_craft recipe, mul, count
        needed = [exact_craft(mul * count, recipe.makes), count].max
        if stash[recipe] > needed
            stash[recipe] -= needed
            return false
        end
        # potrzebujemy needed - stash[recipe] itemów, zaokrąglonych do możliwości craftowych
    end


    def obsolete_craft depth, mul, count, tree
        puts "#{' '*depth}DOCRAFT #{mul} #{count}"
        recipe, tail = tree
        puts "#{' '*depth}RECIPE #{recipe}"
        @craft_seq[recipe] = [@craft_seq[recipe] || 0, depth].max

        new_count = exact_craft(mul * count, recipe.makes)
        puts "#{' '*depth}NUM #{@crafts[recipe]} + C(#{count}) or NC(#{new_count})"
        added_count = [count, new_count].max #!
        @crafts[recipe] += added_count
        @craft_acc[recipe] += added_count
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
      show_stash
      nil
    end

    def raw_resources
      raw.sort_by { |item, count| item.name }.map do |item, count|
        stack_info = item.stack_info count.ceil
        [item.name, count.ceil, stack_info]
      end
    end

    def craft_sequence
        ordering = craft_seq.sort_by { |craft, i| i }.reverse
        j, last = 1, ordering.first[1] + 1# max waga
        ordering.map do |craft, order|
          # NOTE: poprawione o craft_acc
          count = crafts[craft]
          row = OpenStruct.new(
            count: (count * craft.makes).round,
            num: (order < last ? j : nil),
            machine: craft.machine,
            result: craft.result,
            ingredients: craft.describe_ingredients(count)
          )
          j += 1 if order < last
          last = order
          row
        end
    end

    def show_raw
        puts "Resources required:"
        raw_resources.each do |name, count, stack_info|
          puts [name, '*', count,
                (" (#{stack_info})" if stack_info)].join ''
        end
    end

    def show_crafts
      last_num = nil
      craft_sequence.each do |row|
        msg = [
          (row.num != nil ? "#{row.num}. " : ' ' * "#{last_num}. ".size),
          ("using #{row.machine} " if row.machine),
          "craft #{row.count} #{row.result} ",
          "from #{row.ingredients}"
        ].join ''
        last_num = row.num
        puts msg
      end
    end

    def show_acc
        puts "Total crafted"
        @craft_acc.each do |craft, count|
            puts [craft.result, "*" , count].join(" ") 
        end
    end

end

