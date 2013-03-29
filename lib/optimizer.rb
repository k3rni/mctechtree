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
      # puts rc.inspect
      new_crafts = crafts.dup
      rc.each do |ing, count|
        craft = crafts.select { |k, v| k.result == ing }.first[0] rescue nil
        next if craft.nil? # raw
        new_count = exact_craft(count, craft.makes)
        # puts "#{craft} #{count} -> #{new_count}"
        if crafts[craft] != [new_count, count].min
          new_crafts[craft] = [new_count, count].min
          # przelicz znowu raw
        end
      end

      new_raw = Counter.new
      crafts.each do |craft, count|
        craft.count_ingredients.each do |ing, icnt|
          next unless ing.primitive
          # puts "#{ing} #{raw[ing]} -> #{count*icnt}"
          new_raw[ing] += count * icnt
        end
      end
      # puts "RAW"
      # puts self.raw.inspect
      # puts new_raw.inspect
      # puts "CRAFT"
      # puts self.crafts.inspect
      # puts new_crafts.inspect
      break if self.raw == new_raw && self.crafts == new_crafts
      self.raw = new_raw
      self.crafts = new_crafts
    end
  end
end
