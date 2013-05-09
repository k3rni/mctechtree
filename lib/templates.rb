module Templates
  KEY_PAT = /\$\(([^)]+)\)/
  def is_template? recipe
    name = recipe.keys.first
    definition = recipe.values.first
    definition.include?('vars') || name =~ KEY_PAT
  end

  def transform_template template
    if template.size == 1 # craft-like recipe "name: params"

      name = template.keys.first
      definition = template.values.first
    else # hash - any other form
      name = nil
      definition = template
    end
    keys = find_keys(name, definition)
    substitutions = Hash[keys.map { |key| [key, definition.delete(key)] }]
    expansions = []
    build_substitutions(name, definition, substitutions, keys.first, keys[1..-1], &expansions.method(:push))
    expansions.flatten
  end

  def find_keys name, definition
    keys = name.scan(KEY_PAT).flatten
    if keys.empty?
      keys = definition.delete('vars')
    end
    return keys
  end

  def build_substitutions name, definition, substitutions, key, rest, was_nil=false
    substitutions[key].each do |s|
      if s.nil?
        label = ''
        expansion = nil
      elsif s.index('/')
        label, expansion = s.split('/')
      else
        label = expansion = s
      end
      # if there's no substitutions left (rest is nil), this creates a fully-solved recipe
      # otherwise it will still contain $(substitutions), and get passed on
      placeholder = "$(#{key})"
      new_name = replace_string(name, placeholder, label) if name
      new_def = definition.merge(Hash[
        definition.map do |defkey, defval|
          if (exp = method("replace_#{defkey}") rescue nil)
            [defkey, exp.call(defval, placeholder, expansion)]
          elsif defval.is_a? Array
            [defkey, replace_list_names(defval, placeholder, expansion)]
          elsif defval.is_a? String
            [defkey, replace_string(defval, placeholder, expansion)]
          end
        end
      ])
      # new_def = definition.merge({
      #   # TODO: this should probably replace all metadata, per type and not only ing and shape
      #   'ingredients' => replace_list_names(definition['ingredients'], "$(#{key})", expansion),
      #   'shape' => replace_shape_names(definition['shape'], "$(#{key})", expansion)
      # })
      if rest.nil? || rest.size == 0
        # avoid a combination that was all nils
        if !(was_nil && expansion.nil?) 
          yield({new_name => new_def})
        end
      else
        # recursively call with a partially solved recipe
        build_substitutions(new_name, new_def, substitutions, rest.first, rest[1..-1], expansion.nil?) { |obj| yield obj }
      end
    end
  end

  def replace_string text, old, new
    text.sub(old, new).strip.gsub('  ', ' ')
  end

  def replace_list_names list, old, new
    oldrx = %r{^(\w+\|)?#{Regexp.escape old}$}
      if list.nil?
        nil
      elsif new.nil?
        list.reject { |el| el =~ oldrx }
      else
        list.map { |el| el.gsub(old, new) }
      end
  end

  def replace_shape shape, old, new
    if shape.nil?
      nil
    elsif new.nil?
      shape.gsub(old, '~') 
    else
      shape.gsub(old, new).gsub('  ', ' ')
    end
  end
end
