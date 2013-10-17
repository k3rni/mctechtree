#! /usr/bin/env ruby
# encoding: utf-8

require 'bundler'
Bundler.setup
Bundler.require
require 'delegate'
require 'yaml'
require 'set'
require 'pry'

%w(item craft database graph optimizer solver addons).each do |mod|
  symbol = mod.gsub(/(?:\A|_)(.)/){ |m| $1.upcase }.to_sym
  autoload symbol, "./lib/#{mod}.rb"
end
autoload :ItemResolver, './lib/resolvers'
autoload :CraftResolver, './lib/resolvers'
require './lib/errors'

DB = Database.new

def gather_files paths, files
  [ paths.map { |pth| Dir.glob("#{pth}/*.yml") },
    files
  ].flatten
end

paths = ['db/**']
files = []
gather_files(paths, files).each do |filename|
  puts filename
  DB.load_definitions YAML.load_file(filename)
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
  if names.last.is_a? Database
    db = names.pop
  else
    db = DB
  end
  puts "Using #{db} (#{db.size})"
  item_resolver = make_item_resolver(options)
  solutions = build_solutions(names).map { |name, count| item_resolver.new(db.find(name), count).resolve }
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


# solve 'molten redstone*1000'
vdb = DB.filter_clusters 'vanilla'
binding.pry
