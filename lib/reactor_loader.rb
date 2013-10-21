require 'uri'

class UnknownComponentError < StandardError; end

class BigIntStack
  def initialize num
    @num = num
  end

  def read_bits size
    mask = (1 << size) - 1 # all bits on at given length
    result = @num & mask
    @num >>= size
    result
  end

  def read_bool
    read_bits(1) != 0
  end

end

class ReactorLoader
  attr_reader :ingredients

  def initialize url
    @url = URI.parse(url)
    stack = BigIntStack.new(get_reactor_code.to_i(36))
    @ingredients = decode_reactor(stack)
  end

  def ingredient_query
    @ingredients.map do |name, count|
      if count == 1
        name
      else
        "#{name}*#{count}"
      end
    end
  end

  def get_reactor_code
    @url.query
  end
  
  PLANNER_V3_COMPONENTS = {
    1 => 'uranium cell',
    2 => 'dual uranium cell',
    3 => 'quad uranium cell',
    4 => 'depleted isotope cell',
    5 => 'neutron reflector',
    6 => 'thick neutron reflector',
    7 => 'heat vent',
    8 => 'reactor heat vent',
    9 => 'overclocked heat vent',
    10 => 'advanced heat vent',
    11 => 'component heat vent',
    12 => 'RSH-condensator',
    13 => 'LZH-condensator',
    14 => 'heat exchanger',
    15 => 'reactor heat exchanger',
    16 => 'component heat exchanger',
    17 => 'advanced heat exchanger',
    18 => 'reactor plating',
    19 => 'heat-capacity reactor plating',
    20 => 'containment reactor plating',
    21 => '10k coolant cell',
    22 => '30k coolant cell',
    23 => '60k coolant cell',
    24 => 'heating cell'
  }

  def lookup_component num
    # TODO: include GT sometime
    name = PLANNER_V3_COMPONENTS[num]
    if name.nil?
      raise UnknownComponentError.new num
    end
    name
  end

  def decode_reactor stack
    stack.read_bits(10) # initial heat, we don't care
    components = Hash.new { |h, k| h[k] = 0 }
    # coordinates aren't important, but size must be preserved
    (0..8).each do |i|
      (0..5).each do |j|
        v = stack.read_bits(7).to_i
        if v > 64
          stack_size = (v - 64) + 1
          v = stack.read_bits(7).to_i
        elsif v == 0
          next
        else
          stack_size = 1
        end
        components[lookup_component(v)] += stack_size
      end
    end
    components
  end
end
