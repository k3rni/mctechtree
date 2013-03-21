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
itemkinds = [:herbs, :ores, :cooking_ingredients, :elemental, :cloth, :enchanting_mats, :leather]

FileUtils.mkdir_p "wowhead"

def load_base kind
    puts "base/#{kind}"
    items = Wowhead.send("get_#{kind}")
    File.open("wowhead/#{kind}.yml", 'w') do |fp|
      fp.write(YAML.dump_stream(
        'primitives' => items
      ))
    end
end

def load_prof prof
  Wowhead::RANKS.keys.each do |rank|
    puts "#{prof}/#{rank}"
    path = "wowhead/#{prof}"
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

ARGV.each do |arg|
    if profs.include? arg.to_sym
	    load_prof arg.to_sym
    elsif itemkinds.include? arg.to_sym
	    load_base arg.to_sym
    else
	    puts "WTF #{arg}"
    end
end
