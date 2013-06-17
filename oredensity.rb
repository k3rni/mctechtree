#! /usr/bin/env ruby

require 'yaml'
require 'pry'

def load_ores
  data = YAML.load_file 'oreids.yml'
  data.invert
end

def load_block_stats ore_dict
  stats = Hash.new { |h, k| h[k] = 0}
  File.open('block_report.txt').each do |line|
    if line =~ /^\((\d+(?::\d+)?)\)\s+(.*?)\s*:\s+(\d+)/
      blockid, name, count = $1, $2, $3.to_f
      if name == "Future Block!"
        name = ore_dict[blockid]
      end
      stats[name] += count
    end
  end
  stats
end

oredict = load_ores
stats = load_block_stats oredict
total = stats.values.inject(0) { |a, b| a+b }
puts stats.inspect
binding.pry
