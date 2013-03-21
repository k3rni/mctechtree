#! /usr/bin/env ruby

$:.unshift "./lib"

require 'bundler'
Bundler.setup
require 'pry'
require 'fileutils'
require 'wowhead/config'
require 'wowhead/parser'
require 'wowhead/scraper'
require 'yaml'

# TODO: przewalić to do makefile jakiegoś
profs = Set.new(Wowhead::PROFESSIONS.keys)
itemkinds = Wowhead::TRADE_URLS.keys # a tak naprawdę metody get_

def load_base kind
    items = Wowhead.send("get_#{kind}")
    STDOUT.write(YAML.dump_stream(
      'primitives' => items
    ))
end

def load_prof prof, rank
  begin
    recipes = Wowhead.get_recipes prof, rank
  rescue 
    raise
  end
  STDOUT.write(YAML.dump_stream(
    'cluster' => prof.to_s,
    'crafts' => recipes
  ))
end

target = ARGV[0].to_sym
if profs.include? target
  load_prof target, ARGV[1].to_sym # z rank
elsif itemkinds.include? target
  load_base target
else
  exit 1
end
