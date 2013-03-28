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
autoload :Solver, './lib/solver'


DB = Database.new
Dir.glob('db/**/*.yml').each do |filename|
  puts filename
    DB.load_definitions YAML.load_file(filename)
end
DB.fixup_pending
DB.dump_graph File.open('techtree.dot', 'w')

def solve *names
  if names.last.is_a? Hash
    options = names.pop 
  end
  # TODO: wykluczanie maszyn - jeśli odpowiednia opcja podana,
  # podmienić itemresolvera na używający craftresolvera wykluczającego podane maszyny
  # analogicznie: wykluczanie clusterów - podmieniamy itemresolver na taki
  # który nie znajdzie itemków z zakazanego clustera
  solutions = names.map do |name|
    if name =~ /(.+?)\*(\d+)/
      [$1, $2.to_i]
    else
      [name, 1]
    end
  end
  .map { |name, count| ItemResolver.new(DB.find(name), count).resolve }
  Solver.new(solutions).solve.describe
end

solve 'molten redstone*1000'
binding.pry
