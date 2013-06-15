module Forge
  def load_equivalents definitions, group=nil
    definitions.each do |category, entries|
      # TODO: allow any depth
      entries.each do |key, names|
        cat = "#{category}:#{key}"
        @equivalents[cat] += names
        names.each do |name|
          @equivalent_categories[name] = cat
        end
      end
    end
  end

  def pending_from_dictionary
    # anything left? try the equivalents list
    @pending.select! do |item|
      if (new_item = find_equivalent(item.name))
        replace_pending item, new_item
        false # instructs select! to drop this item from the pending list
      else
        true # keep it 
      end
    end
  end

  def find_equivalent name
    category = @equivalent_categories[name]
    all_items = @equivalents[category].map { |name| find(name) }.compact
    if all_items.size == 0 # nie ma
      nil
    else
      ForgeItem.new(all_items)
    end
  end

end
