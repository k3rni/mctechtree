#! /usr/bin/env ruby
# encoding: utf-8

require 'bundler'
Bundler.setup
Bundler.require
require 'delegate'
require 'yaml'
require 'set'
require 'pry'

autoload :Item, './lib/item'
autoload :Craft, './lib/craft'
autoload :Database, './lib/database'
autoload :Graph, './lib/graph'
autoload :ItemResolver, './lib/resolvers'
autoload :CraftResolver, './lib/resolvers'
autoload :Optimizer, './lib/optimizer'
autoload :Solver, './lib/solver'


DB = Database.new
Dir.glob('db/**/*.yml').each do |filename|
    DB.load_definitions YAML.load_file(filename)
end
DB.fixup_pending
DB.detect_name_clashes
DB.classify_tiers
DB.dump_graph File.open('techtree.dot', 'w')

def build_solutions names
  names.map do |name|
    if name =~ /(.+?)\*(\d+)/
      [$1, $2.to_i]
    else
      [name, 1]
    end
  end
end

IR_OPTIONS = %w(forbid_machine min_tier)
CR_OPTIONS = %w()
def solve *names
  if names.last.is_a? Hash
    options = names.pop 
  else
    options = {}
  end
  item_resolver_options = options.select { |key, val| IR_OPTIONS.include? key.to_s }
  craft_resolver_options = options.select { |key, val| CR_OPTIONS.include? key.to_s }
  # TODO: wykluczanie maszyn - jeśli odpowiednia opcja podana,
  # podmienić itemresolvera na używający craftresolvera wykluczającego podane maszyny
  # analogicznie: wykluczanie clusterów - podmieniamy itemresolver na taki
  # który nie znajdzie itemków z zakazanego clustera

  mir, mcr = nil
  mir = Class.new(ItemResolver) do
    @@craft_constructor = Proc.new { |*args| mcr.new(*args) }
  end
  while item_resolver_options.size > 0
    mir = build_resolver mir, item_resolver_options
  end

  mcr = Class.new(CraftResolver) do
    @@item_constructor = Proc.new { |*args| mir.new(*args) }
  end
  while craft_resolver_options.size > 0
    mcr = build_resolver mir, craft_resolver_options
  end
  solutions = build_solutions(names).map { |name, count| mir.new(DB.find(name), count).resolve }
  Solver.new(solutions).solve.describe
end

module ForbidMachine
  def initialize *args
    super(*args)
    @children.select! { |c| c.craft.machine.nil? || !forbid_machine_params.include?(c.craft.machine) }
  end
end

module MinTier
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

def build_resolver old, options
  modname = options.keys.first
  params = options.delete modname
  Class.new(old) do
    define_method "#{modname}_params".to_sym do params end
    include modname.to_s.classify.constantize
  end
end

solve 'molten redstone*1000'
binding.pry
