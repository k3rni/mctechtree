require 'color'
require 'haml'
require 'i18n'
require 'json'

module D3Graph
  def dump_graph fp
    grouping = self.to_a.group_by(&:group)
    @cluster_colors = make_cluster_colors grouping
    @cluster_centers = make_cluster_centers grouping
    @nodes = []
    @edges = []
    dump_items
    graph_setup(fp) do
      sio = StringIO.new
      sio.puts [@nodes, @edges].to_json
      sio.string
    end
  end

  def graph_setup fp, &block
    template = Haml::Engine.new(File.read('d3_base.haml'))
    fp.puts template.render(binding, {cluster_colors: @cluster_colors}, &block)
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

  def dump_items 
    grouping = self.to_a.group_by(&:group)
    grouping.each do |group, grpitems|
      grpitems.each do |item|
        # TODO: wielkość noda od ilości wychodzących craftów
        item_color = @cluster_colors[group]
        if item.primitive
          item_color = intensify(item_color)
        end
        @nodes << { id: item.safe_name, name: item.name, color: item_color, craft: false, cluster: group }
        dump_item_crafts item
        unused = %Q(
            sigInst.addNode('#{item.safe_name}', {
              label: "#{item.name}",
              x: #{@cluster_centers[group].x} + Math.random(),
              y: #{@cluster_centers[group].y} + Math.random(),
              color: "#{item_color}",
              cluster: "#{group}",
              size: #{[5 - item.tier/2.0, 1.0].max}
              });
        )
      end
    end
  end

  def dump_crafts fp
    self.each do |item|
      dump_item_crafts fp, item
    end
  end

  def dump_item_crafts item
    item.crafts.each_with_index do |craft, i|
      @nodes << {id: "craft_#{craft.hash}_#{i}", name: "#{craft.machine || 'craft'}", craft: true}

      unused = %Q(
        sigInst.addNode('craft_#{craft.hash}_#{i}', {
          label: "#{craft.machine || 'craft'}",
          x: Math.random(),
          y: Math.random(),
          cluster: "#{item.group}",
          color: '#fff',
          size: 1
        })
      )
      @edges << { source: "craft_#{craft.hash}_#{i}", target: "#{craft.result.safe_name}" }
      unused =  %Q(
        sigInst.addEdge('#{craft.hash}_#{i}', 'craft_#{craft.hash}_#{i}', '#{craft.result.safe_name}', {
           color: 'target'
        });
      )
      craft.count_ingredients.each do |ing, count|
        @edges << { source: "#{ing.safe_name}", target: "craft_#{craft.hash}_#{i}" }
        unused = %Q(
          sigInst.addEdge('#{craft.hash}_#{ing.safe_name}_#{i}', '#{ing.safe_name}', 'craft_#{craft.hash}_#{i}', {label: #{count}});
        )
      end
    end
  end
end
