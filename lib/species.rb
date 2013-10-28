class PendingSpecies < PendingItem; end

class Species < Item
  attr_accessor :metadata

  def initialize name, attrs={}
    self.metadata = {}
    self.name = name
    if attrs.include? 'origin'
      self.primitive = true
      self.cost = 1
    end
    attrs.each do |key, val|
      begin
        self.send "#{key}=", val
      rescue NoMethodError
        self.metadata[key] = val
      end
    end

    @crafts = []
    @crafts_into = Set.new
  end

  def add_breeding properties
    Breed.new(self, properties).tap do |breed|
      self.crafts << breed
    end
  end

  def self.pending name
    PendingSpecies.new(name)
  end

end
