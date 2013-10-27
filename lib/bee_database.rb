class BeeDatabase < Database
  def load_definitions data
    group = data['cluster']
    %w(defaults species breeding).each do |key|
      send "load_#{key}", data[key] || {}, group
    end
    forget_defaults
    self
  end

  def parse_entry data
    name = data.keys.first
    properties = data.values.first
    [name, properties]
  end

  def load_species definitions, group=nil
    definitions.each do |data|
      name, properties = parse_entry(data)
      if (old == find(name))
        # TODO: conflict?
        next
      else
        species = Species.new name, properties
        self.add species
      end
    end
  end

  def load_breeding definitions, group=nil
    definitions.each do |data|
      name, properties = parse_entry(data)
      # TODO: template?
      load_single_breed name, properties, group
    end
  end

  def load_single_breed name, properties, group=nil
    breed = find(name)
    
    unless breed
      breed = Breed.new name, group 
      self.add breed
    end
    # TODO: conflicts?
    breed.add_breeding properties
  end
end
