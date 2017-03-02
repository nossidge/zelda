#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Method for generating a random mission tree.
# Uses the Grammar singleton to replace node sequences having certain Letters,
#   with other sequences of Letters in the tree.
################################################################################

module Zelda

  # Singleton containing only methods.
  class MissionTree

    # Keep generating until we get a valid dungeon.
    def self.generate(grammar, dungeon_settings)
      @@failed_attempts = 0
      nodes = false
      loop do
        nodes = generate_or_fail(grammar, dungeon_settings)
        break if nodes
      end
      nodes
    end

    # Use the data in Grammar to generate a dungeon mission tree.
    def self.generate_or_fail(grammar, dungeon_settings, dev_snapshots = false)

      # Set up a new nodes object with a single 'S' start node.
      nodes = Nodes.new('S')

      # Use the 'grammar' object to define which rules are used.
      # There needs to be only one 'rules_start' selected.
      rules = grammar.get_rules

      # Loop and reshuffle the array every time a replacement occurs.
      # Loop until no replacements are possible.
      loop do
        replacement_done = false

        # Snapshot of the graph.
        if dev_snapshots
          nodes.write_graph_desc
          nodes.write_to_graphic_file(
            "#{Zelda::Config.dir_root}/output/snapshot#{Time.now.strftime('%Y%m%d%H%M%S%L')}")
        end

        # Shuffle all the grammar rules, and try to apply one of them.
        rules.seed_shuffle_increment.each do |rule|

          # Returns a Boolean success state.
          done = nodes.replace_sequence_with_sequence(rule)

          # Break and reshuffle the array if the above returned false.
          if done
            replacement_done = true
            break
          end
        end

        # If we've looped through the whole array and
        #   there are no more replacements possible.
        break if !replacement_done
      end

      # Make sure that all the 'zone' information is up to date.
      loop do
        replaced = false
        nodes.each do |k,n|
          if n.zone == 0
            zone = 0
            n.parents.each do |pid|
              p = nodes.find_by_id(pid)
              zone = p.zone if p.zone > zone
            end
            n.zone = zone
            replaced = true
          end
        end
        break if !replaced
      end

      # Use the constraints to assert that it's valid.
      if not dungeon_settings.assert_constraints(nodes)
        Zelda::Config.seed_increment
        return false
      end

      # Which zone is the quest item in?
      nodes.calculate_quest_item_zone

      # Transfer the correct 'zone_traversal' to the 'nodes'.
      nodes.set_zone_traversal(grammar.get_zone_traversal)

      # Certain nodes need to be logically grouped together to help make sure
      #   that they make sense when mapped to 2d space.
      # This is really only for lock and key groups.
      current_id = 0
      [%w(l k),%w(lf kf),%w(lp kp),%w(lm km)].each do |group|

        # Find all lock nodes. These should have a key as a parent.
        # Then apply the same 'lock_group_id' to all nodes.
        # This will also work for locks with multiple keys.
        l_nodes = nodes.all.select{ |n| n.letter == group[0] }
        l_nodes.each do |n|
          all_nodes = [n]
          current_id += 1
          n.metadata[:lock_group_type] = group[0]
          n.metadata[:lock_group_id] = current_id

          # Add the 'lock_group_id' to each key parent.
          # Also, count how many there are.
          counter = 1
          n.parents.each do |p|
            p = nodes.find_by_id(p)
            if p.letter == group[1]
              all_nodes << p
              p.metadata[:lock_group_type] = group[0]
              p.metadata[:lock_group_id] = current_id
              p.metadata[:lock_group_num] = counter
              counter += 1
            end
          end

          # Now that we know the total count, we can apply that to them all.
          n.metadata[:lock_group_num] = counter
          all_nodes.each do |k|
            k.metadata[:lock_group_total] = counter
          end

        end
      end

      # If it passes the checks, then return the nodes.
      nodes
    end

  end

end

################################################################################
