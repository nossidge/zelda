#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Holds a hash of Node objects.
################################################################################

module Zelda

  class Nodes
    include Enumerable

    attr_reader :nodes, :graph
    attr_reader :zone_traversal
    attr_accessor :quest_item_zone

    def initialize(letter = nil)
      @nodes = {}
      @graph = nil
      @max_id = 0
      @zone_traversal = []
      @quest_item_zone = nil
      self.add(letter) if !letter.nil?
    end

    ############################################################################

    # Set the same 'zone_traversal' as was used in the generating grammar.
    def set_zone_traversal(zone_traversal)
      @zone_traversal = zone_traversal
    end

    ############################################################################

    # Enumerate through each node.
    def each(&block)
      @nodes.each do |k,n|
        block.call(k,n)
      end
    end

    # Get just the nodes from the hash, without the key.
    def all
      @nodes.map{ |k,v| v }
    end

    # Count nodes.
    def size
      @nodes.size
    end

    # Return an array of Nodes, ordered by 'zone' attribute.
    def collect_by_zone
      self.sort_by do |k,n|
        [n.zone, n.tight_coupling]
      end.map do |i|
        i[1]
      end
    end

    # Return an array of the Nodes that have no tight_coupling.
    # Sort by 'zone', ancestor count and 'id'.
    def collect_normal_parents
      self.select do |k,n|
        n.tight_coupling.size == 0
      end.map do |i|
        i[1]
      end.sort_by do |n|
        [n.zone, ancestors(n).count, n.id]
      end
    end

    # Return an array of the Nodes that do have tight_coupling.
    def collect_tight_parents
      self.select do |k,n|
        n.tight_coupling.size > 0
      end.map do |i|
        i[1]
      end
    end

    # Hash in the form: { parent_id => child_node }
    #   There may be multiple instances of 'parent_id' and 'child_node'.
    def tight_parents_to_nodes
      output = Hash.new { |h,k| h[k] = [] }
      self.each do |k,n|
        n.tight_coupling.each do |pid|
          output[pid] << n
        end
      end
      output
    end

    ############################################################################

    # ID of each node must be unique.
    def next_id
      @max_id += 1
    end

    # 'parents' and 'tight_coupling' should be an array of node names [1,2].
    # When drawing the final graph, this will error if the nodes don't exist.
    # By default, the zone will be the highest zone of the parents, or 0.
    def add(letter, parents = [], tight_coupling = [], zone = 0, id = nil)
      id ||= next_id()
      if zone == 0 and ![*parents].empty?
        [*parents].each do |p|
          if not @nodes[p].nil?
            zone = @nodes[p].zone if @nodes[p].zone > zone
          end
        end
      end
      @nodes[id] = Node.new(id, letter, [*parents], [*tight_coupling], zone)
    end

    # Change the attributes of an existing node.
    def alter_letter(id, letter)
      @nodes[id].letter = letter
    end
    def alter_zone(id, zone)
      @nodes[id].zone = zone
    end

    # Change the parents of an existing node.
    def add_parent(id, parent_id, tight_coupling = false)
      @nodes[id].parents.push(parent_id).uniq!
      @nodes[id].tight_coupling.push(parent_id).uniq! if tight_coupling
    end
    def add_tight_coupling(id, parent_id)
      @nodes[id].tight_coupling.push(parent_id)
    end
    def remove_parent(id, parent_id)
      @nodes[id].parents.delete(parent_id)
    end
    def remove_tight_coupling(id, parent_id)
      @nodes[id].tight_coupling.delete(parent_id)
    end

    # Find each node with letter 'l', that has a parent with letter 'lp'.
    # Output is an array of arrays, e.g.
    # [ [parent1, node1],
    #   [parent1, node2],
    #   [parent3, node1],
    #   [parent3, node4],
    #   [parent5, node6] ]
    # Or, if no parent specified, an array of nodes, e.g.
    # [ node1,
    #   node2,
    #   node4,
    #   node6 ]
    def find_by_letter(l, lp = nil)
      output = []
      @nodes.each do |k,n|
        if n.letter == l
          if lp.nil?
            output.push n
          else
            n.parents.each do |p|
              if @nodes[p].letter == lp
                output.push [@nodes[p], n]
              end
            end
          end
        end
      end
      output
    end

    # Find the node with the specified 'id'.
    def find_by_id(id)
      @nodes[id]
    end

    # Find each node with the parent id 'pid'.
    def find_children(pid)
      output = []
      @nodes.each do |k,n|
        n.parents.each do |p|
          if @nodes[p].id == pid
            output.push n
          end
        end
      end
      output
    end

    # Find the edge type with id 'id' and parent 'id_p'.
    # Output 'tight', 'normal', or nil
    def edge_type(id, id_p)
      if @nodes[id.to_i].tight_coupling.include?(id_p.to_i)
        'tight'
      elsif @nodes[id.to_i].parents.include?(id_p.to_i)
        'normal'
      else
        nil
      end
    end

    # Write the structure to a DirectedAdjacencyGraph.
    def write_graph(type = 'id')
      @graph = RGL::DirectedAdjacencyGraph.new
      @nodes.each do |k,n|
        n.parents.each do |p|
          if type == 'id'
            @graph.add_edges RGL::Edge::DirectedEdge.new(@nodes[p].id, n.id)
          elsif type == 'desc'
            @graph.add_edges RGL::Edge::DirectedEdge.new(@nodes[p].desc, n.desc)
          end
        end
      end
    end
    def write_graph_desc
      write_graph(type='desc')
    end

    # Display the graph in image form.
    def dotty
      @graph.dotty
    end
    def write_to_dot_file(filename = 'dot_file', params = {})
      @graph.write_to_dot_file(self, filename, params)
    end
    def write_to_graphic_file(filename = 'dot_file', params = {})
      @graph.write_to_graphic_file(self, 'png', filename, params)
    end

    # Quick loop print of each node.
    def loop
      @nodes.each do |n|
        puts n.desc
      end
    end

    # Which zone is the quest item in?
    # Assumes just one 'iq' node.
    def calculate_quest_item_zone
      @quest_item_zone = find_by_letter('iq')[0].zone
    end

    ############################################################################

    # Array of the ancestors in the chain, all the way back to node 1.
    def ancestors(node)
      output = []
      node.parents.each do |pid|
        output << pid
        output += ancestors(self.find_by_id(pid))
      end
      output.uniq
    end

    ############################################################################

    # Replace a sequence of nodes with another sequence.
    # Replacements must be an array of 2 node arrays in the form:
    #  [
    #    [ Node.new(1,'s4'), Node.new(2,'a') ],
    #    [ Node.new(1,'CL'), Node.new(3,'CL',1), Node.new(2,'CL',3,3) ]
    #  ]
    def replace_sequence_with_sequence(reps)

      # Error if incorrect input.
      if reps[0].size > 2
        raise 'reps[0].size > 2'
        return nil
      end

      # Try to find the existing 'reps[0]' nodes in the existing 'nodes' structure.
      if reps[0].size == 2
        found = self.find_by_letter(reps[0][1].letter, reps[0][0].letter)
      elsif reps[0].size == 1
        found = self.find_by_letter(reps[0][0].letter)
      end
      return nil if found.empty?

      # Replace a random match.
      old_nodes = found.seed_sample

      # If there are two original old nodes.
      if reps[0].size == 2

        # Get the IDs of the existing nodes.
        old_ids = [old_nodes[0].id, old_nodes[1].id]

        # Remove the first as a parent of the second.
        self.remove_parent(old_nodes[1].id, old_nodes[0].id)
        self.remove_tight_coupling(old_nodes[1].id, old_nodes[0].id)

        # Replace the first old node's letter with the first new node's letter.
        rep_nodes = reps[1]
        self.alter_letter(old_ids[0], rep_nodes[0].letter)
        if rep_nodes[0].zone != 0
          self.alter_zone(old_ids[0], rep_nodes[0].zone)
        end

        # Also the second with the last.
        # Assumes the last new node is the ID 2. (*Is this still true?)
        self.alter_letter(old_nodes[1].id, rep_nodes[-1].letter)
        if rep_nodes[-1].zone != 0
          self.alter_zone(old_nodes[1].id, rep_nodes[-1].zone)
        end

        # Add the remainder of the array as nodes, with the parent as specified.
        new_ids = {rep_nodes[-1].id => old_nodes[1].id}
        new_ids[1] = old_ids[0]
        rep_nodes[1...-1].each do |r|

          # Add the new node, and get its designated unique ID.
          id = self.add(r.letter, [], [], r.zone).id

          # Map the rule ID to the correct ID.
          new_ids[r.id] = id
        end

      # If there's just one orignal old node.
      else

        # Replace the first old node's letter with the first new node's letter.
        rep_nodes = reps[1]
        self.alter_letter(old_nodes.id, rep_nodes[0].letter)
        if rep_nodes[0].zone != 0
          self.alter_zone(old_nodes.id, rep_nodes[0].zone)
        end

        # Add the remainder of the array as nodes, with the parent as specified.
        new_ids = {rep_nodes[0].id => old_nodes.id}
        rep_nodes[1..-1].each do |r|

          # Add the new node, and get its designated unique ID.
          id = self.add(r.letter,[],[],r.zone).id

          # Map the rule ID to the correct ID.
          new_ids[r.id] = id
        end
      end

      # Add the parents based on the correct IDs.
      rep_nodes[1..-1].each do |r|
        id = new_ids[r.id]
        r.parents.each do |p|
          pid = new_ids[p]
          self.add_parent(id, pid)
        end
        r.tight_coupling.each do |p|
          pid = new_ids[p]
          self.add_tight_coupling(id, pid)
        end
      end

      true
    end

    ############################################################################

    def to_a
      self.map { |k,v| v.to_a }
    end

    ############################################################################

    # Class structure of each Node as JSON array.
    def as_json(options={})
      {
        max_id: @max_id,
        quest_item_zone: @quest_item_zone,
        zone_traversal: @zone_traversal,
        nodes: self.map do |k,v|
          v.as_json(*options)
        end
      }
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

  end

end

################################################################################
