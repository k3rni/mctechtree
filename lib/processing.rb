module Processing
  def load_processing definitions, group=nil
    definitions.each do |process|
      inputs = process.delete('inputs')
      outputs = process.delete('outputs')
      if outputs.size == 1
        load_single_craft craft_process(inputs, outputs, process), group
      else
        raise
      end
    end
  end

  def craft_process inputs, outputs, extra
     name = outputs.first
     if name =~ /(.+?)\*(\d+)/
       name, makes = $1, $2.to_i
     else
       makes = 1
     end
     machine = extra.delete('machine') || @defaults['machine']
     # NOTE: code duplication with parse_recipe
     shape_map, ingredients = strip_shapes(inputs)
     ingredients = resolve_items(ingredients)
     shape_map = resolve_shapes(shape_map, ingredients)
     extra['shape_map'] = shape_map unless shape_map.empty?
     [name, makes, machine, ingredients, extra]
  end
end
