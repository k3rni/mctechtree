module Shapes
  def strip_shapes ingredients
    shapes = {}
    new_ingredients = ingredients.map do |name|
      match = name.match(/^(?:(.*)\|)?(.*)$/)
      if match[1]
        shapes[match[1]] = match[2]
      end
      match[2]
    end
    [shapes, new_ingredients]
  end

  def resolve_shapes shape_map, ingredients
    Hash[shape_map.map do |key, name|
      [key, ingredients.select do |item|
        # prefix match
        name[Regexp.new("^#{item.name}")]
      end.first]
    end]
  end
end
