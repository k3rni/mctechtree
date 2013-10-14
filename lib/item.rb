# encoding: utf-8

require 'forwardable'

class CraftBuilder < SimpleDelegator
  def makes count, machine, ingredients, group, extra
    craft = Craft.create(machine, __getobj__, count, ingredients, group, extra)
    self.crafts << craft
    craft
  end
end

class PendingItem
  attr_accessor :name

  def initialize name
    @name = name
  end

  def hash
    name.hash
  end

  def <=> other
    self.name <=> other.name
  end

  def to_s
    "!#{name}"
  end

  def safe_name
    "!#{ActiveSupport::Inflector.underscore name}".gsub(/\W/, '_')
  end

  def <=> other
    self.name <=> other.name
  end

  def ==(other)
    self.name == other.name
  end
end

class Item
  attr_accessor :name, :primitive, :cost, :stacks, :group, :compatible, :tier
  attr_reader :crafts, :crafts_into

  def initialize attrs={}
    attrs.each do |key, val| 
      self.send "#{key}=", val
    end
    @crafts = []
    @crafts_into = Set.new
    self.stacks = 64 if stacks.nil?
  end

  def hash
    name.hash
  end

  def to_s
    [
      (primitive ? name.upcase : name),
      ("@#{cost}" unless cost.nil?)
    ].join('')
  end

  def safe_name
    # ostatni gsub bo dot marudzi
    ActiveSupport::Inflector.underscore(name).gsub(/\W/, '_').gsub(/(^[0-9])/, "n_\\1")
  end

  def stack_info count
    return nil if @stacks == false
    num, rem = count.divmod(@stacks)
    plural = 's' if num > 1
    if num == 0
      nil
    elsif rem == 0
      # NOTE: marne i18n
      "#{num} stack#{plural}"
    else
      "#{num} stack#{plural} + #{rem}"
    end
  end

  def <=> other
    self.name <=> other.name
  end

  def ==(other)
    self.name == other.name
  end

  def groups
    Set.new([group] + crafts.map(&:group)).to_a
  end

  def self.primitive name, cost, stacks, group
    self.new(name: name, primitive: true, cost: cost, stacks: stacks, group: group)
  end

  def self.crafted name, group, extra={}
    self.new({name: name, primitive: false, group: group}.merge(extra)).tap do |obj|
      crafts = CraftBuilder.new(obj)
      yield(crafts)
    end
  end

  def self.pending name
    PendingItem.new(name)
  end

  def crafted_from
    Set.new(crafts.map { |cr| cr.count_ingredients.keys }.flatten)
  end

  def max_tier
    crafts.map do |cr|
      cr.count_ingredients.keys.map(&:tier)
    end.map(&:max).min
  end

  def add_craft
    yield(CraftBuilder.new(self))
  end

  def resolver
    ItemResolver.new(self)
  end
end

# NOTE: delegate everything to first item, expose rest in a method 
class ForgeItem < SimpleDelegator
  attr_accessor :items
  def initialize srcitems
    @items = srcitems
    @delegate_sd_obj = @items.first
  end
end
