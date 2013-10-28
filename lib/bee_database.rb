class DuplicateSpeciesError < StandardError; end
class BeeDatabase < Database
  def load_definitions data
    group = data['cluster']
    %w(defaults species breeding equivalents).each do |key|
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
      if (old = find(name))
        raise DuplicateSpeciesError.new(name)
        next
      else
        species = Species.new name, properties.merge(group: group)
        self.add species
      end
    end
  end

  def load_breeding definitions, group=nil
    definitions.each do |data|
      name, properties = parse_entry(data)
      # TODO: template?
      load_single_breed name, properties.merge(group: group)
    end
  end

  def load_single_breed name, properties
    breed = find(name)
    
    unless breed
      species_prop = properties.dup
      species_prop.delete :parents
      breed = Species.new name, species_prop
      self.add breed
    end
    # TODO: conflicts?
    properties['parents'] = resolve_items properties['parents']
    breed.add_breeding properties
  end

  def add_pending_item name
    Species.pending(name).tap { |obj| @pending.add obj }
  end

end

class BeeSolver < Solver
  def describe
    show_base_species
    show_species_path
    nil
  end

  def show_base_species
      puts "Starting with:"
      raw_resources.each do |name, count, stack_info|
        puts name
      end
  end

  def craft_sequence
    ordering = craft_seq.sort_by { |craft, i| i }.reverse
    j, last = 1, ordering.first[1] + 1# max waga
    ordering.map do |craft, order|
      row = OpenStruct.new(
        num: (order < last ? j : nil),
        species: craft.result,
        generations: craft.success_99,
        chance: craft.chance,
        biomes: craft.biome,
        parents: craft.ingredients.join(' and ')
      )
      j += 1 if order < last
      last = order
      row
    end
  end

  def show_species_path
    last_num = nil
    craft_sequence.each do |row|
      msg = [
        (row.num.nil? ? ' ' * "#{last_num}. ".size : "#{row.num}. "),
        "breed #{row.species} ",
        "from #{row.parents} ",
        ("in #{row.biomes.join(',')} biome#{row.biomes.size > 1 ? 's' : ''} " if row.biomes),
        "for up to #{row.generations.ceil} generations (#{row.chance}%)",
      ].join ''
      last_num = row.num
      puts msg
    end
  end
end
