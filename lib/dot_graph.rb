module DotGraph
  def dump_graph fp
    fp.puts "digraph techtree {"
    graph_setup fp
    dump_items fp
    # dump_crafts fp
    fp.puts "}"
  end

  def graph_setup fp

  end

  def dump_items fp
    self.to_a.group_by(&:group).each do |group, grpitems|
      with_subgraph(fp, group) do
        grpitems.each do |item|
          fp.puts %Q(#{item.safe_name} [label="#{item.name}" shape=box #{" style=bold" if item.primitive}];)
          dump_item_crafts fp, item
        end
      end
    end
  end

  def with_subgraph fp, name
    fp.puts "subgraph cluster_#{name} {" if name
    yield
    fp.puts "}" if name
  end

  def dump_crafts fp
    self.each do |item|
      dump_item_crafts fp, item
    end
  end

  def dump_item_crafts fp, item
    item.crafts.each do |craft|
      fp.puts %Q(craft_#{craft.hash} [label="#{craft.machine ? craft.machine : 'craft'}" shape=oval];)
      fp.puts %Q(craft_#{craft.hash} -> #{craft.result.safe_name} [label="#{craft.makes}"];)
      craft.count_ingredients.each do |ing, count|
        # fp.puts %Q(#{ing.safe_name} -> #{craft.result.safe_name} [label="#{count}#{(' ' + craft.machine) if craft.machine}"];)
        fp.puts %Q(#{ing.safe_name} -> craft_#{craft.hash} [label="#{count}"];)
      end
    end
  end
end
