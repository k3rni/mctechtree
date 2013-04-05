require 'color'
require 'haml'
require 'i18n'

module SigmaGraph
  def dump_graph fp
    grouping = self.to_a.group_by(&:group)
    @cluster_colors = make_cluster_colors grouping
    @cluster_centers = make_cluster_centers grouping
    @edges = []
    graph_setup(fp) do
      sio = StringIO.new
      dump_items sio
      dump_edges sio
      sio.string
    end
  end

  def graph_setup fp, &block
    template = Haml::Engine.new(File.read('sigma_base.haml'))
    fp.puts template.render(binding, {cluster_colors: @cluster_colors}, &block)
  end
  
  def dump_edges fp
    @edges.each { |s| fp.puts s }
  end

  def make_cluster_colors groups
    step = 1.0/groups.size
    i = 0
    Hash[groups.map do |name, items|
      [name, Color::HSL.from_fraction(i * step, 0.9, 0.7).html].tap { i += 1 }
    end]
  end

  def make_cluster_centers groups
    step = 2 * Math::PI / groups.size
    i = 0
    radius = 3
    Hash[groups.map do |name, items|
      [name, OpenStruct.new(x: radius * Math.cos(i*step), y: radius * Math.sin(i*step))].tap { i += 1}
    end]
  end

  def intensify color, diff=10
    col = Color::RGB.from_html(color)
    col.adjust_saturation(diff).html
  end

  def dump_items fp
    grouping = self.to_a.group_by(&:group)
    grouping.each do |group, grpitems|
      with_subgraph(fp, group) do
        grpitems.each do |item|
          # TODO: wielkość noda od ilości wychodzących craftów
          item_color = @cluster_colors[group]
          if item.primitive
            item_color = intensify(item_color)
          end
          fp.puts %Q(
            sigInst.addNode('#{item.safe_name}', {
              label: "#{item.name}",
              x: #{@cluster_centers[group].x} + Math.random(),
              y: #{@cluster_centers[group].y} + Math.random(),
              color: "#{item_color}",
              cluster: "#{group}",
              size: #{[5 - item.tier/2.0, 1.0].max}
              });
          )
          dump_item_crafts fp, item
        end
      end
    end
  end

  def with_subgraph fp, name
    # fp.puts "subgraph cluster_#{name} {" if name
    yield
    # fp.puts "}" if name
  end

  def dump_crafts fp
    self.each do |item|
      dump_item_crafts fp, item
    end
  end

  def dump_item_crafts fp, item
    item.crafts.each_with_index do |craft, i|
      # fp.puts %Q(craft_#{craft.hash} [label="#{craft.machine ? craft.machine : 'craft'}" shape=oval];)
      fp.puts %Q(
        sigInst.addNode('craft_#{craft.hash}_#{i}', {
          label: "#{craft.machine || 'craft'}",
          x: Math.random(),
          y: Math.random(),
          cluster: "#{item.group}",
          color: '#fff',
          size: 1
        })
      )
      # fp.puts %Q(craft_#{craft.hash} -> #{craft.result.safe_name} [label="#{craft.makes}"];)
      @edges << %Q(
        sigInst.addEdge('#{craft.hash}_#{i}', 'craft_#{craft.hash}_#{i}', '#{craft.result.safe_name}', {
           color: 'target'
        });
      )
      craft.count_ingredients.each do |ing, count|
        # fp.puts %Q(#{ing.safe_name} -> craft_#{craft.hash} [label="#{count}"];)
        @edges << %Q(
          sigInst.addEdge('#{craft.hash}_#{ing.safe_name}_#{i}', '#{ing.safe_name}', 'craft_#{craft.hash}_#{i}', {label: #{count}});
        )
      end
    end
  end
end
