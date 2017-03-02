#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Start to generate the dungeon.
# Relies on state of 'Zelda::Config.options'
################################################################################

module Zelda
  class Generate

    TIMEOUT_SECONDS = 1

    ############################################################################

    # Generate dungeons using the parameters set in 'Zelda::Config.options'
    def self.generate(dungeon_setting_dir = 'default')

      # For the moment, this is the same for all 8 dungeons.
      dungeon_settings = Zelda::DungeonSettings.new(dungeon_setting_dir)

      # Loop to make 'Zelda::Config.options[:number]' dungeons.
      nodes = nil
      counter = 0
      loop do
        begin

          # File name is based on the current time.
          filename = Time.now.strftime('%Y%m%d%H%M%S%L')
          filepath = Zelda::Config.dir_output_data + '/' + filename

          # Initial value of the random seed.
          Zelda::Config.seed_dungeon = Zelda::Config.seed

          # Output if verbose.
          Zelda::puts_verbose "seed = #{Zelda::Config.seed_dungeon}"
          Zelda::puts_verbose "filepath = #{filepath}"

          # Generate the mission nodes.
          if nodes.nil? or not Zelda::Config.options[:one_mission]
            nodes = generate_mission(dungeon_settings)
          end

          # Stop generation if the particular seed takes too long.
          dungeon_map = nil
          Timeout::timeout(TIMEOUT_SECONDS) do
            dungeon_map = generate_dungeon(nodes)
          end

          # This will only run if the above did not timeout.
          save_to_file(filepath, nodes, dungeon_map)
          counter += 1
          Zelda::Config.seed = Zelda::Config.options[:seed] + (counter*1000000)

        # If the above timed out.
        rescue Timeout::Error => e
          Zelda::puts_verbose "Seed #{Zelda::Config.seed_dungeon} timed out..."
        end

        # Exit the loop if we've reached the correct number of dungeons.
        break if counter == Zelda::Config.options[:number]
      end

      # Open in default browser, if necessary.
      Zelda::Config.open_in_default(Zelda::Config.file_html_index)
    end

    ############################################################################

    # One mission means use just one MissionTree for all maps.
    def self.generate_mission(dungeon_settings)
      nodes = nil

      # Generate a dungeon mission tree.
      # Return the generated tree as a Zelda::Nodes object.
      grammar = Grammar.new
      grammar.rules_complex
      nodes = MissionTree.generate(grammar, dungeon_settings)

      # Write the nodes to a RGL::DirectedAdjacencyGraph.
      # Use the 'desc' property as the node description.
      nodes.write_graph_desc

      # Return the 'Nodes' object.
      nodes
    end

    ############################################################################

    # Use the 'Nodes' tree to generate a 2D dungeon map.
    def self.generate_dungeon(nodes)
      DungeonMap.new(nodes)
    end

    ############################################################################

    # Save the DOT and JSON to file.
    def self.save_to_file(filepath, nodes, dungeon_map)

      # Save the tree to a DOT file.
      nodes.write_to_dot_file(filepath)

      # Save the dungeon layout to JSON.
      dungeon_map.rooms.save_json(filepath)

      # Write to a static HTML file, if necessary.
      if Zelda::Config.options[:static_html]
        nodes.write_to_graphic_file(filepath)
        dungeon_map.generate_html_file(filepath)

        # Open in default browser, if necessary.
        Zelda::Config.open_in_default(filepath + '.html')
      end

      # Add the file to the JavaScript list.
      Zelda::Config.add_to_file_list_js(File.basename(filepath))
    end

    ############################################################################

  end
end

################################################################################
