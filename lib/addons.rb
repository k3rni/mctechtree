module Addons
  module ForbidMachine
    module ItemResolver
      def primitive
        item.crafts.all? do |craft|
          forbid_machine_params.include? craft.machine
        end || super
      end

      def children
        super.reject do |cr|
          forbid_machine_params.include? cr.craft.machine
        end
      end
    end
  end

  module MinTier
    module ItemResolver
      def primitive
        item.tier <= min_tier_params || super
      end

    end
  end

  module ExcludeCluster
    module ItemResolver
      def children
        super.reject do |cr|
          exclude_cluster_params.include? cr.craft.group
        end
      end
    end
  end

  def self.build_resolver mode, old, options
    modname = options.keys.first
    params = options.delete modname
    Class.new(old) do
      define_method "#{modname}_params".to_sym do params end
      include "addons/#{modname}/#{mode}".classify.constantize
    end.tap do |cls|
      new_classname = "#{modname.to_s.classify}#{(old.name || mode.to_s).classify.demodulize}"
      Addons.const_set new_classname.to_sym, cls
    end
  end

  def self.item_resolver_modules
    self.constants.select do |submod|
      self.const_get(submod).constants.include? :ItemResolver
    end.map(&:to_s).map(&:underscore)
  end

  def self.craft_resolver_modules
    self.constants.select do |submod|
      self.const_get(submod).constants.include? :CraftResolver
    end.map(&:to_s).map(&:underscore)
  end
end
