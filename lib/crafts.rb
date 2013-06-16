module Crafts
  def crafted
    select { |item| item.crafts.size > 0 }
  end

  def load_crafts definitions, group=nil
    # TODO: disable other recipes, by signature
    definitions.each do |recipe|
      if is_template? recipe
        recipes = transform_template recipe
        recipes.each { |craft| load_single_craft craft, group }
      else
        load_single_craft recipe, group
      end
    end
  end

  def load_single_craft recipe, group=nil
    name, makes, machine, ingredients, extra = parse_recipe(recipe)
    item = find(name)
    compat = extra['compatible'] || @defaults['compatible']

    if !item
      item = Item.crafted name, group, compatible: compat do |craft|
        craft.makes(makes, machine, ingredients, group, extra)
      end
      self.add item
    elsif conflicts?(item, extra, group)
      @conflicts.add [:craft, name, group, item.group]
    else
      item.add_craft do |craft|
        craft.makes(makes, machine, ingredients, group, extra)
      end
    end
  end

  def parse_recipe recipe, group=nil
    if recipe.is_a? Hash
      name = recipe.keys.first # YAMLowy format tak ma
      definition = recipe.values.first
    elsif recipe.is_a?(Array) && recipe.size == 2 # para nazwa, ingredients ze skróconej definicji
      name = recipe.first
      definition = recipe.last
    elsif recipe.is_a?(Array) && recipe.size == 5 && recipe.last.is_a?(Hash)
      # gotowy recipe (np. z craft_process)
      return recipe
    end
    # TODO: stacks dla przedmiotów craftowanych
    if definition.is_a? Hash
      shape_map, ingredients = strip_shapes(definition.delete('ingredients'))
      # turn ingredient list elements from names into items
      ingredients = resolve_items(ingredients)
      # and the shape map too
      shape_map = resolve_shapes(shape_map, ingredients)
      makes = definition.delete('makes') || 1
      machine = definition.delete('machine')
      extra = definition
      extra['shape_map'] = shape_map unless shape_map.empty?
    elsif definition.is_a? Array
      ingredients = resolve_items(definition)
      makes = 1
      machine = nil
      extra = {}
    else
      raise BadDefinitionError.new(name)
    end
    [name, makes, machine, ingredients, extra]
  end


end
