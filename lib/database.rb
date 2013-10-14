# encoding: utf-8

autoload :Graph, './lib/graph'
autoload :Filter, './lib/filter'


class Database < Set
  include Graph
  include Primitives
  include Crafts
  include Filter
  include Shapes
  include Templates
  include Forge
  include Processing

  def initialize(*args)
    super(*args)
        @packs = {} # disputable, packs are one level above a database.
    @pending = Set.new
    @conflicts = Set.new
    @equivalents = Hash.new { |h, key| h[key] = Set.new }
    @equivalent_categories = Hash.new { |h, key| h[key] = Set.new }
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
    %w(defaults equivalents primitives crafts processing packs).each do |key|
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

  def fixup_pending
    @pending.select! do |item|
      if (newitem = find(item.name))
        replace_pending item, newitem
        false # drop pending item
      else
        true
      end
    end
    pending_from_dictionary
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
      item = self.find(name) || already_pending(name) || add_pending_item(name)
      [item] * count
    end.flatten
    end

    def load_packs data, cluster=nil
      data.each do |pack|
        @packs[pack['name']] = pack['requires']
      end
  end
  
  def already_pending name
    item = @pending.select { |obj| obj.name == name }.first 
  end

  def add_pending_item name
    Item.pending(name).tap { |obj| @pending.add obj }
  end

  def detect_name_clashes
    if @conflicts.size > 0
      raise NamingConflictError.new(@conflicts.sort_by { |v| v[1] }.map do |mode,name,cluster1,cluster2|
        "#{mode}[#{name}]:#{cluster1},#{cluster2}" 
      end.join("\n"))
    end
  end
  
  def fill_reverse
    each do |item|
      item.crafted_from.each do |src|
        src.crafts_into.add item
      end
    end
  end

  def select_unsolved
    select { |item| item.tier == nil || item.tier > 20 }
  end

  def tier_histogram
    tiers = map(&:tier)
    Hash[tiers.uniq.map { |t| [t, tiers.select{|r| r == t}.size] }]
  end

  def classify_tiers
    primitives.each { |item| item.tier = 0 }
    fan_out(primitives, 1)
    changed = true
    while changed do
      changed = false
      crafted.each do |item|
        max_tier = item.max_tier
        if item.tier != max_tier + 1
          item.tier = max_tier + 1
          changed = true
        end
      end
    end
  end

  def fan_out items, tier
    next_set = Set.new
    items.each do |item|
      item.crafts_into.each do |dst|
        if dst.tier == nil 
          dst.tier = tier
          next_set.add dst
        elsif dst.tier < tier
          dst.tier = tier
        end
      end
    end
    fan_out next_set, tier+1 if next_set.size > 0
  end

end
