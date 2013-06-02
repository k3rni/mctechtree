#! /usr/bin/env ruby

require 'pathname'
require 'set'
require 'yaml'

def build_sprites data
  ss = data['sprite-sheet']
  sprites = Hash.new# { |h,k| h[k] = Set.new }
  data['columns'].to_a.each do |col, names|
    names.zip(0...names.size).each do |name, i|
      next if name.nil?
      sprites[name] = [col, i]
    end
  end

  data['rows'].to_a.each do |row, names|
    names.zip(0...names.size).each do |name, j|
      next if name.nil?
      sprites[name] = [j, row] 
    end
  end
  make_spritesheet sprites, ss['rows'], ss['cols'], ss['filename'], 16, 16, 2
end

def make_spritesheet sprites, rows, cols, filename, w=16, h=16, scale=1
  buf = StringIO.new
  buf.puts %Q(i.icon {
    display: inline-block;
    width: #{(w*scale).to_i}px;
    height: #{(h*scale).to_i}px;
    background-size: #{(rows*w*scale).to_i}px #{(cols*h*scale).to_i}px;
    background-repeat: no-repeat;
  })

  sprites.each do |name, coords|
    x, y = coords
      buf.puts %Q(i.#{css_name(name)} {
        background-image: url('sprites/#{filename}');
        background-position:  -#{(x*w*scale).to_i}px -#{(y*h*scale).to_i}px ;
      })
  end
  buf.string
end

def css_name name
  safe = name.downcase.gsub(/\W/, '-')
  if name =~ /^[0-9]/
    "n#{safe}"
  else
    safe
  end
end

def write_sample dstfilename, data
  File.open(dstfilename, 'w') do |fp|
    fp.puts %Q(<html>
       <head>
       <link rel="stylesheet" href="#{data['cluster']}.css">
       </head>
       <body>)
    all_keys = Set.new
    all_keys += data['rows'].values.flatten if data['rows']
    all_keys += data['columns'].values.flatten if data['columns']
    all_keys.each do |key|
      next if key.nil?
      fp.puts %Q(<i class="icon #{css_name key}"></i>#{key}<br/>)
    end
    fp.puts %Q(
       </body>
    </html>)
  end
end

Dir.glob('db/**/*.yml').each do |filename|
  data = YAML.load_file(filename)
  next unless data.include? 'sprite-sheet'
  puts data['cluster']
  write_sample "./#{data['cluster']}.html", data
  File.open("./#{data['cluster']}.css", 'w') { |fp| fp.puts build_sprites(data) }
end
