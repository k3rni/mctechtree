module Addons
  module ForbidMachine
    module ItemResolver
      def children
        @children.map do |obj|
          if forbid_machine_params.include? obj.craft.machine
            nil
            # TODO: replace this craftresolver with an itemresolver?
          else
            obj
          end
        end.compact
      end
    end
  end

  module MinTier
    module ItemResolver
      def primitive
        item.primitive || item.tier <= min_tier_params
      end

      def cost
        if primitive
          count # * 1 (not determining cost recursively)
        else
          super
        end
      end
    end
  end

  module ExcludeCluster
  end

  def self.build_resolver mode, old, options
    modname = options.keys.first
    params = options.delete modname
    Class.new(old) do
      define_method "#{modname}_params".to_sym do params end
      include "addons/#{modname}/#{mode}".classify.constantize
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
