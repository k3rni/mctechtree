module Optimizer

  private

  def real_counts ordering
    make_counter.tap do |obj|
      ordering.each do |craft, order|
        craft.count_ingredients.each do |ing, icnt|
          obj[ing] += icnt * crafts[craft]
        end
      end
    end
  end

  def optimize options={}
    min_tier = options[:min_tier] || 0
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

      new_raw = make_counter
      crafts.each do |craft, count|
        craft.count_ingredients.each do |ing, icnt|
          # next unless (ing.primitive || ing.tier <= min_tier)
          # next unless raw.include? ing # fails to work with proxied items
          # puts "## #{ing} IN #{raw} ? #{raw.keys.map{|o| o == ing}}"
          skip = self.raw.keys.any?{ |obj| obj == ing}
          next unless skip

          # puts "#{ing} #{raw[ing]} -> #{count*icnt}"
          new_raw[ing] += count * icnt
        end
      end
      # puts "RAW"
      # puts "OLD #{self.raw.inspect}"
      # puts "NEW #{new_raw.inspect}"
      # puts "CRAFT"
      # puts self.crafts.inspect
      # puts new_crafts.inspect
      # break if self.raw.drop_zeros == new_raw.drop_zeros && self.crafts.drop_zeros == new_crafts.drop_zeros
      break if same_item_counters(self.raw, new_raw) && same_craft_counters(self.crafts, new_crafts)
      self.raw = new_raw.drop_zeros
      self.crafts = new_crafts.drop_zeros
    end
    self.raw = new_raw.drop_zeros
    self.crafts = new_crafts.drop_zeros
  end

  def same_item_counters left, right
    # TODO: move this into Counter
    a = Hash[left.drop_zeros.map { |k, v| [k.name, v] }]
    b = Hash[right.drop_zeros.map { |k, v| [k.name, v] }]
    a == b
  end

  def same_craft_counters left, right
    a = Hash[left.drop_zeros.map { |k, v| [k.result.name, v] }]
    b = Hash[right.drop_zeros.map { |k, v| [k.result.name, v] }]
    a == b
  end

  def make_counter
    Counter.new
  end
end
