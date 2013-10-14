module Filter
  class RestrictedItemProxy < SimpleDelegator
    def crafts
      # Similar to what Addons::ExcludeCluster does. Might be a better solution actually. Or worse.
      super.select { |craft| @@clusters.include? craft.group }.map { |craft| @@craft_class.new(craft) }
    end

    def hash
      name.hash
    end

    def self.set_clusters value
      @@clusters = value
    end

    def self.set_craft_class value
      @@craft_class = value
    end
  end

  class RestrictedCraftProxy < SimpleDelegator
    def ingredients
      super.map { |item| @@item_class.new(item) }
    end

    def result
      @@item_class.new(super)
    end

    def count_ingredients 
      # XXX: ugly and non-DRY :(
      # however, without this, all non-delegated items on Item that call
      # count_ingredients would use the old version.
      Hash[ingredients.group_by(&:name).map { |name,items| [items.first, items.size] }]
    end

    def self.set_clusters value
      @@clusters = value
    end

    def self.set_item_class value
      @@item_class = value
    end
  end

  def filter_clusters pack
    # pack is a list of cluster names that we KEEP
    clusters = @packs[pack]
    # Blah, resolver dependency all over again. Maybe just stick it there?
    item_class = Object.const_set "#{pack.titlecase}RestrictedItemProxy".to_sym, Class.new(RestrictedItemProxy)
    item_class.set_clusters(clusters)
    craft_class = Object.const_set "#{pack.titlecase}RestrictedCraftProxy".to_sym, Class.new(RestrictedCraftProxy)
    craft_class.set_clusters(clusters)
    item_class.set_craft_class craft_class 
    craft_class.set_item_class item_class

    Database.new.tap do |db|
      db.merge self.select { |obj| clusters.include? obj.group }.map { |obj| item_class.new(obj) }
      fix_hierarchy db, clusters
    end
  end

  private

  def fix_hierarchy newdb, clusters
    hierarchy = newdb.instance_variable_get :@hierarchy
    (clusters + [nil]).each do |cls|
      hierarchy[cls] = @hierarchy[cls].select { |group| clusters.include? group }
    end
  end
end
