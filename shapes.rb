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

DB.each_crafted.each do |item|
    item.crafts.each do |craft|
	puts "Missing shape: #{craft}" if craft.grid.nil?
    end
end
