# encoding: utf-8


%w(graph crafts primitives shapes templates processing).each do |mod|
  autoload mod.capitalize.to_sym, "./lib/#{mod}"
end
class Database < Set
  include Graph
  include Primitives
  include Crafts
  include Shapes
  include Templates
  include Processing

  def initialize(*args)
    super(*args)
    @pending = Set.new
    @conflicts = Set.new
    @equivalents = Hash.new { |h, key| h[key] = Set.new }
    @hierarchy = Hash.new { |h, key| h[key] = Set.new }
    @defaults = {}
  end

  def find(name)
    select { |obj| obj.name == name }.first
  end

  def primitives
    select { |item| item.primitive }
  end

  def machines
    crafted.map { |item| item.crafts.map(&:machine) }.flatten.compact.uniq
  end

  def root_groups
    submods nil
  end

  def submods group
    @hierarchy[group].to_a.compact
  end

  def load_definitions data
    group = data['cluster']
    @hierarchy[data['parent']].add group
    # defaults has to go first
    %w(defaults equivalents primitives crafts processing).each do |key|
      send "load_#{key}", data[key] || {}, group
    end
    forget_defaults
    self
  end

  def load_defaults defaults, group=nil
    @defaults.merge! defaults
  end

  def forget_defaults
    @defaults = {}
  end

  def conflicts? existing, extra, group
    compatible = extra['compatible']
    if compatible == 'all'
      false
    elsif [group, 'all'].include? existing.compatible 
      false
    elsif existing.group == group
      false
    elsif existing.primitive
      false
    elsif compatible.nil?
      true
    elsif compatible != existing.group
      true
    else
      false
    end
  end

  def load_equivalents definitions, group=nil
    definitions.each do |names|
      nn = Set.new(names)
      nn.each do |name|
        @equivalents[name].merge(nn - [name])
      end
    end
  end

  def fixup_pending
    @pending.select! do |item|
      if (newitem = find(item.name))
        replace_pending item, newitem
        false # drop pending item
      else
        true
      end
    end
    # anything left? try the equivalents list
    @pending.select! do |item|
      if (eq = @equivalents[item.name])
        new_item = eq.map { |name| find(name) }.compact.first
        if new_item.nil?
          true
        else
          replace_pending item, new_item
          false
        end
      else
        true
      end
    end
    if @pending.size > 0
      raise UndefinedItemsError.new(@pending.to_a.join(','))
    end
  end

  def replace_pending old, new
    self.each do |item|
      item.crafts.each do |craft|
        craft.replace_ingredients old, new
      end
    end
  end

  def resolve_items names
    names.map do |name|
      if name =~ /(.+?)\*(\d+)/
        name, count = $1, $2.to_i
      else
        count = 1
      end
      item = self.find(name) 
      if item.nil?
        item = @pending.select { |obj| obj.name == name }.first || Item.pending(name).tap { |obj| @pending.add obj }
      end
      [item] * count
    end.flatten
  end

  def detect_name_clashes
    if @conflicts.size > 0
      raise NamingConflictError.new(@conflicts.sort_by { |v| v[1] }.map do |mode,name,cluster1,cluster2|
        "#{mode}[#{name}]:#{cluster1},#{cluster2}" 
      end.join("\n"))
    end
  end

  def select_unsolved
    select { |item| item.tier == nil || item.tier > 20 }
  end

  def classify_tiers
    unsolved = select_unsolved
    while select_unsolved.size > 0
      unsolved = select_unsolved
      changed = true
      while changed
        # keep running until nothing changes
        unsolved, changed = iterate_tiers unsolved
      end
    end
  end

  def iterate_tiers subset
    unsolved = Set.new(subset)
    visited = Set.new()
    changed = false
    primitives.each do |item|
      unsolved -= [item]
      item.tier = 0
    end

    unsolved.sort_by{|item| -item.crafts.size}.each do |item|
      visited.add item
      craft_tiers = item.crafts.map do |craft| 
        t = craft.count_ingredients.keys.reject{ |k| visited.include? k }.map { |ing| ing.tier }
        if t.include? nil
          nil
        else
          t.max
        end
      end.flatten
      unless craft_tiers.include? nil
        min_tier = craft_tiers.compact.min
        prev = item.tier
        item.tier = min_tier + 1
        changed = (item.tier != prev)
        unsolved -= [item]
      end
    end

    unsolved.each { |item| item.tier = 100 }
    return [unsolved, changed]
  end
end
