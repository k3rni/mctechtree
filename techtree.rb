#! /usr/bin/env ruby
# encoding: utf-8

require 'bundler'
Bundler.setup
Bundler.require
require 'optparse'
require 'ostruct'
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
require './lib/errors'

options = OpenStruct.new(skip: [], skip_clusters: [], skip_tiers: false)
OptionParser.new do |opts|
  opts.on('-X', '--exclude PATTERN', 'skip loading files by pattern') do |pattern|
    options.skip << pattern
  end 
  opts.on('-x', '--exclude-tiers PATTERN', 'skip loading definitions by tier') do |pattern|
    options.skip_clusters += pattern.split(',')
  end
  opts.on('--skip-tiers', 'omit tier calculation') do |v|
    options.skip_tiers = v
  end
end.parse!

DB = Database.new
Dir.glob('db/**/*.yml').each do |filename|
  if options.skip.any? { |pat| File.fnmatch? pat, filename }
    puts "Skipping #{filename}"
    next
  end
  definitions = YAML.load_file(filename)
  if options.skip_clusters.include? definitions['cluster'] or options.skip_clusters.include? definitions['parent']
    puts "Cluster-skipping #{filename}" 
    next
  end
  puts "Loading #{filename}"
  DB.load_definitions definitions
end
DB.fixup_pending
DB.detect_name_clashes
DB.fill_reverse
DB.classify_tiers if ARGV.include? '--tiers'
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
  result = Solver.new(solutions, options).solve
  if result.valid
    result.describe
  else
    false
  end
end

def make_item_resolver options
  item_resolver_options = options.select { |key, val| Addons.item_resolver_modules.include? key.to_s }
  craft_resolver_options = options.select { |key, val| Addons.craft_resolver_modules.include? key.to_s }

  mir, mcr = nil
  mir = Class.new(ItemResolver) do
    @@craft_constructor = Proc.new { |*args| mcr.cached(*args) }
  end
  while item_resolver_options.size > 0
    mir = Addons.build_resolver :item_resolver, mir, item_resolver_options
  end

  mcr = Class.new(CraftResolver) do
    @@item_constructor = Proc.new { |*args| mir.cached(*args) }
  end
  while craft_resolver_options.size > 0
    mcr = Addons.build_resolver :craft_resolver, mcr, craft_resolver_options
  end

  mir
end


# solve 'molten redstone*1000'
binding.pry
