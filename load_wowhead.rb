#! /usr/bin/env ruby

$:.unshift "./lib"

require 'bundler'
Bundler.setup
require 'pry'
require 'fileutils'
require 'wowhead/scraper'
require 'yaml'

data = Marshal.load(File.read('alchemy-apprentice.obj'))

profs = Set.new(Wowhead::PROFESSIONS.keys)
profs = [:alchemy]

FileUtils.mkdir_p "db/wow/"
File.open("db/wow/herbs.yml", 'w') do |fp|
  fp.write(YAML.dump_stream(
    'primitives' => Wowhead.get_herbs
  ))
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
