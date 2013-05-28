#! /usr/bin/env ruby

require 'pathname'
require 'set'
require 'yaml'

def build_sprites data
  ss = data['sprite-sheet']
  sprites = Hash.new# { |h,k| h[k] = Set.new }
  data['columns'].to_a.each do |col, names|
    names.zip(1..names.size).each do |name, i|
      next if name.nil?
      sprites[name] = [col, i]
    end
  end

  data['rows'].to_a.each do |row, names|
    names.zip(1..names.size).each do |name, j|
      next if name.nil?
      sprites[name] = [row, j] 
    end
  end
  make_spritesheet sprites, ss['rows'], ss['cols'], ss['filename']
end

def make_spritesheet sprites, rows, cols, filename, w=16, h=16
  buf = StringIO.new
  buf.puts %Q(i.icon {
    display: inline-block;
    width: #{w}px;
    height: #{h}px;
  })

  sprites.each do |name, coords|
    x, y = coords
    buf.puts %Q(i.#{css_name(name)} {
      background: url('sprites/#{filename}') -#{x*w}px -#{y*h}px no-repeat;
    })
  end
  buf.string
end

def css_name name
  name.downcase.gsub(/\W/, '-')
end

Dir.glob('db/**/*.yml').each do |filename|
  data = YAML.load_file(filename)
  next unless data.include? 'sprite-sheet'
  puts build_sprites(data)
end
