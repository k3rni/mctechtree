class Breed < Craft
  attr_accessor :meta
  def initialize result, attrs={}
    self.meta = {}
    self.result = result
    self.makes = 1
    attrs.each do |key, val|
      begin
        self.send "#{key}=", val
      rescue NoMethodError
        binding.pry if key == 'parents'
        self.meta[key] = val
      end
    end
  end

  def parents= val
    self.ingredients = val
  end

  def chance
    self.meta['chance']
  end

  def biome
    self.meta['biome']
  end

  def success_99
    # 1 - ( ( 1 - chance ) ^ generations )
    # solved by Maxima
    # generations = log(1 - A) / log(1 - chance)
    # where A is desired probability, here 90%
    Math.log(1 - 0.99) / Math.log(1 - self.chance/100.0)
  end

  def to_s
    "#{self.class}(" + [
      "result=#{self.result}",
      "ingredients=#{count_ingredients.map{|k,v| "#{k}*#{v}"}.join('+')}",
      meta.map{|k,v| "#{k}=#{v}"},
    ].flatten.compact.join(' ') + ")"
  end

end
