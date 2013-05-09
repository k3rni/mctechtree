require 'ostruct'

class Counter < Hash
  def initialize
    super { |hash, key| hash[key] = 0 }
  end
end

class Solver
    include Optimizer
    attr_accessor :raw, :crafts, :craft_seq

    def initialize(solutions, options={})
        @options = options
        @solutions = solutions
        @crafts = Counter.new
        @craft_seq = Counter.new
        @raw = Counter.new
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
        # puts "#{' '*depth}NUM #{@crafts[recipe]} + #{count} or #{new_count}"
        max_count = [count, new_count].max
        @crafts[recipe] += max_count
        tail.each do |num, rule|
            process rule, depth+1, max_count
        end
    end


    def solve
      @solutions.each do |sol|
        process sol, 0
      end
      optimize(min_tier: @options[:min_tier])
      self
    end

    def describe
      show_raw
      show_crafts
      nil
    end

    def valid
      # only after solving
      @craft_seq.size > 0
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

end

