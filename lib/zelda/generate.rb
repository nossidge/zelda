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

      # Output the generated DungeonMap objects.
      output_dungeon_maps = []

      # For the moment, this is the same for all 8 dungeons.
      dungeon_settings = Zelda::DungeonSettings.new(dungeon_setting_dir)

      # Loop to make 'Zelda::Config.options[:number]' dungeons.
      nodes = nil
      counter_success, counter_fail = 0, 0
      loop do
        begin

          # Initial value of the random seed.
          Zelda::Config.seed_dungeon = Zelda::Config.seed
          Zelda::puts_verbose "###"
          Zelda::puts_verbose "seed = #{Zelda::Config.seed_dungeon}"

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
          Zelda::puts_verbose "dungeon_name = #{dungeon_map.rooms.dungeon_name_full}"
          Zelda::puts_verbose "filepath = #{dungeon_map.filepath}"
          output_dungeon_maps << dungeon_map
          dungeon_map.save_to_file
          counter_success += 1

        # If the above timed out.
        rescue Timeout::Error => e
          Zelda::puts_verbose "Seed #{Zelda::Config.seed_dungeon} timed out..."
          counter_fail += 1
        end

        # Exit the loop if we've reached the correct number of dungeons.
        break if counter_success == Zelda::Config.options[:number]

        # New seed for the next dungeon.
        seed_delta = (counter_success + counter_fail) * 1000000
        Zelda::Config.seed = Zelda::Config.options[:seed] + seed_delta
      end

      # Open in default browser, if necessary.
      Zelda::Config.open_in_default(Zelda::Config.file_html_index)

      output_dungeon_maps
    end

    ############################################################################

    # One mission means use just one MissionTree for all maps.
    def self.generate_mission(dungeon_settings)
      nodes = nil

      # Generate a dungeon mission tree.
      # Return the generated tree as a Zelda::Nodes object.
      grammar = Grammar.new
      grammar.rules_from_dungeon_settings(dungeon_settings.settings_dir)
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

  end
end

################################################################################
