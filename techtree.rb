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
autoload :Addons, './lib/addons'

DB = Database.new
Dir.glob('db/**/*.yml').each do |filename|
  puts filename
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

def solve *names
  if names.last.is_a? Hash
    options = names.pop 
  else
    options = {}
  end
  item_resolver = make_item_resolver(options)
  solutions = build_solutions(names).map { |name, count| item_resolver.new(DB.find(name), count).resolve }
  Solver.new(solutions, options).solve.describe
end

def make_item_resolver options
  item_resolver_options = options.select { |key, val| Addons.item_resolver_modules.include? key.to_s }
  craft_resolver_options = options.select { |key, val| Addons.craft_resolver_modules.include? key.to_s }
  # analogicznie: wykluczanie clusterów - podmieniamy itemresolver na taki
  # który nie znajdzie itemków z zakazanego clustera

  mir, mcr = nil
  mir = Class.new(ItemResolver) do
    @@craft_constructor = Proc.new { |*args| mcr.new(*args) }
  end
  while item_resolver_options.size > 0
    mir = Addons.build_resolver :item_resolver, mir, item_resolver_options
  end

  mcr = Class.new(CraftResolver) do
    @@item_constructor = Proc.new { |*args| mir.new(*args) }
  end
  while craft_resolver_options.size > 0
    mcr = Addons.build_resolver :craft_resolver, mcr, craft_resolver_options
  end

  mir
end


solve 'molten redstone*1000'
binding.pry
