require 'bundler'
Bundler.setup
Bundler.require
$:.unshift File.dirname(__FILE__)

Object.autoload :Item, './lib/item'
Object.autoload :Craft, './lib/craft'
Object.autoload :Database, 'lib/database'
Object.autoload :ItemResolver, './lib/resolvers'
Object.autoload :CraftResolver, './lib/resolvers'
Object.autoload :Optimizer, './lib/optimizer'
Object.autoload :Solver, './lib/solver'
Object.autoload :Addons, './lib/addons'
require './lib/errors'
require './app'
require 'yaml'

DB = Database.new
Dir.glob('db/**/*.yml').each do |filename|
    DB.load_definitions ::YAML.load_file(filename)
end
DB.fixup_pending
DB.detect_name_clashes
DB.classify_tiers

TechTreeApp.db = DB
run TechTreeApp
