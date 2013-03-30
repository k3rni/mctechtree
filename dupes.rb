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

target = ARGV[0] || 'db/**/*.yml'
DB = Database.new
Dir.glob(target).each do |filename|
    DB.load_definitions YAML.load_file(filename)
end
# DB.fixup_pending
puts DB.size

codes = {}
DB.each_crafted.each do |item|
    item.crafts.each do |craft|
	codes[craft.hash] ||= Set.new
	codes[craft.hash].add craft
    end
end

codes.each do |hash, crafts|
    next if crafts.size == 1
    puts "Duplicate crafts: #{crafts.inspect}"
end
