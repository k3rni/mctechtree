#! /usr/bin/env ruby
# encoding: utf-8

require 'bundler'
Bundler.setup
Bundler.require
require 'delegate'
require 'yaml'
require 'set'

autoload :Item, './lib/item'
autoload :Craft, './lib/craft'
autoload :Database, './lib/database'
autoload :Graph, './lib/graph'
autoload :ItemResolver, './lib/resolvers'
autoload :CraftResolver, './lib/resolvers'
autoload :Solver, './lib/solver'


DB = Database.new
Dir.glob('db/**/*.yml').each do |filename|
    DB.load_definitions YAML.load_file(filename)
end
DB.fixup_pending
DB.dump_graph File.open('techtree.dot', 'w')

def solve *names
  solutions = names.map do |name|
    if name =~ /(.+?)\*(\d+)/
      [$1, $2.to_i]
    else
      [name, 1]
    end
  end.map { |name, count| ItemResolver.new(DB.find(name), count).resolve }
  Solver.new(solutions).solve.describe
end

solve 'copper cable*1'
binding.pry
