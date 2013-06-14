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
      [ key, 
        ingredients.map do |item|
          # longest prefix match
          match = name[Regexp.new("^#{item.name}")]
          [item, match.nil? ? 0 : match.size]
        end
        .max{ |pair| pair[1] }
        .first
      ]
    end]
  end
end
