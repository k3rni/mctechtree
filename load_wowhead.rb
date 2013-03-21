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
profs = [:alchemy]
itemkinds = [:herbs, :ores, :cooking_ingredients, :elemental, :cloth, :enchanting, :leather]

FileUtils.mkdir_p "db/wow/"
itemkinds.shuffle.each do |kind|
    puts "base/#{kind}"
    items = Wowhead.send("get_#{kind}")
    File.open("db/wow/#{kind}.yml", 'w') do |fp|
      fp.write(YAML.dump_stream(
        'primitives' => items
      ))
    end
end

exit

profs.each do |prof|
  Wowhead::RANKS.keys.each do |rank|
    puts "#{prof}/#{rank}"
    path = "db/wow/#{prof}"
    FileUtils.mkdir_p path
    begin
      recipes = Wowhead.get_recipes prof, rank
    rescue 
      puts $!.class
      raise
    end
    File.open(File.join(path, "#{rank}.yml"), 'w') do |fp|
      fp.write(YAML.dump_stream(
        'cluster' => prof,
        'crafts' => recipes
      ))
    end
  end
end
