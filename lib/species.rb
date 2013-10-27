class Species < Item
  attr_accessor :metadata

  def initialize attrs={}
    self.metadata = {}
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
end
