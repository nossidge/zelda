#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Monkey patch the RGL gem's Graph module.
# This is so that we can pass a Nodes object, and make a graph from it.
# Used in this project to display tightly-coupled relationships in red.
# Also removed unneeded tags, to shrink the file size.
################################################################################

module RGL
  module Graph

    # Add an argument for a 'nodes' object.
    #   We use this to display tightly coupled edges in a different colour.
    # Add 'params' argument for consistency with later methods.
    def write_to_graphic_file(nodes, fmt='png', dotfile='graph', params = {})
      image_file = dotfile + '.' + fmt
      dot_file = write_to_dot_file(nodes, dotfile, params)
      system("dot -T#{fmt} #{dot_file} -o #{image_file}")
      image_file
    end

    # Write to a dot file, but not an image file.
    def write_to_dot_file(nodes, dotfile='graph', params = {})
      dot = "#{dotfile}.dot"
      File.open("#{dotfile}.dot", 'w') do |f|
        f << self.to_dot_graph(params, nodes).to_s << "\n"
      end
      dot
    end

    ############################################################################

    # This may well break if there's no nodes.
    def to_dot_graph(params = {}, nodes = nil)
      params['name'] ||= self.class.name.gsub(/:/, '_')
      fontsize       = params['fontsize'] ? params['fontsize'] : '10'
      graph          = (directed? ? DOT::Digraph : DOT::Graph).new(params)
      edge_class     = directed? ? DOT::DirectedEdge : DOT::Edge

      # Move 'fontsize' to the global nodes section, rather than individual.
      # Also, remove all graph nodes in the dot. We only need edges.
      graph << DOT::Node.new(
          'name'     => 'node',
          'fontsize' => fontsize
      )

      each_edge do |u, v|
        if not nodes.nil?
          edge_type = nodes.edge_type(v.split(' = ')[0], u.split(' = ')[0])
        end
        color = edge_type == 'tight' ? 'red' : 'black'
        graph << edge_class.new(
            'from'  => vertex_id(u),
            'to'    => vertex_id(v),
            'color' => color
        )
      end

      graph
    end
  end
end

################################################################################
