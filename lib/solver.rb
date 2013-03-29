require 'ostruct'

class Counter < Hash
  def initialize
    super { |hash, key| hash[key] = 0 }
  end
end
module Optimizer

  private

  def real_counts ordering
    Counter.new.tap do |obj|
      ordering.each do |craft, order|
        craft.count_ingredients.each do |ing, icnt|
          obj[ing] += icnt * crafts[craft]
        end
      end
    end
  end

  def optimize
    ordering = craft_seq.sort_by { |craft, i| i }

    while true do
      rc = real_counts(ordering)
      puts rc.inspect
      new_crafts = crafts.dup
      rc.each do |ing, count|
        craft = crafts.select { |k, v| k.result == ing }.first[0] rescue nil
        next if craft.nil? # raw
        new_count = exact_craft(count, craft.makes)
        puts "#{craft} #{count} -> #{new_count}"
        if crafts[craft] != [new_count, count].min
          new_crafts[craft] = [new_count, count].min
          # przelicz znowu raw
        end
      end

      new_raw = Counter.new
      crafts.each do |craft, count|
        craft.count_ingredients.each do |ing, icnt|
          next unless ing.primitive
          puts "#{ing} #{raw[ing]} -> #{count*icnt}"
          new_raw[ing] += count * icnt
        end
      end
      puts "RAW"
      puts self.raw.inspect
      puts new_raw.inspect
      puts "CRAFT"
      puts self.crafts.inspect
      puts new_crafts.inspect
      break if self.raw == new_raw && self.crafts == new_crafts
      self.raw = new_raw
      self.crafts = new_crafts
    end
  end
end
class Solver
    include Optimizer
    attr_accessor :raw, :crafts, :craft_seq

    def initialize(solutions)
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
      optimize
      self
    end

    def describe
      show_raw
      show_crafts
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

