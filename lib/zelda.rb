#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# The base module. Contains '#run' method which kicks everything off.
################################################################################

require 'rgl/adjacency'
require 'rgl/implicit'
require 'rgl/dot'
require 'rgl/topsort'
require 'rgl/traversal'
require 'andand'
require 'json'
require 'tmx'

# Hopefully, when I figure out and fix whatever bug is
#   causing the hang, this will not be needed...
require 'timeout'

require_relative 'zelda/core_extensions/string.rb'
require_relative 'zelda/core_extensions/array.rb'
require_relative 'zelda/rgl_extensions/graph.rb'
require_relative 'zelda/config.rb'
require_relative 'zelda/version.rb'
require_relative 'zelda/cli.rb'
require_relative 'zelda/misc.rb'
require_relative 'zelda/generate.rb'
require_relative 'zelda/alphabet.rb'
require_relative 'zelda/dungeon_map.rb'
require_relative 'zelda/grammar.rb'
require_relative 'zelda/mission_tree.rb'
require_relative 'zelda/node.rb'
require_relative 'zelda/nodes.rb'
require_relative 'zelda/room.rb'
require_relative 'zelda/rooms.rb'
require_relative 'zelda/tilemaps.rb'

################################################################################

module Zelda

  # Logging stuff.
  def self.puts_verbose(message)
    puts message if Zelda::Config.options[:verbose]
  end

  ##############################################################################

  # Generate a dungeon.
  def self.dungeon
    Zelda::Generate.generate
  end

  # Delete all files in the data directory.
  def self.delete
    Zelda::Config.delete_data_files
  end

  ##############################################################################

  # Perform the selected Zelda command.
  def self.perform_command(command, argv)
    case command
      when 'menu'
        Zelda::CLI.full_cli(argv)
        perform_command(Zelda::Config.command, argv)
      when 'delete'
        delete
      when 'dungeon'
        dungeon
      when 'grammar'
        Zelda::Grammar.output_html
      when 'config'
        Zelda::Config.print_config_values
      when 'tilemap'
        Zelda::Tilemaps.tilemap_js_make
        Zelda::Tilemaps.tilemap_info_js_make
      when 'tag'
        if argv[0]
          puts Zelda::Tilemaps.tilemaps_by_tag(argv[0])
        else
          puts Zelda::Tilemaps.tilemap_tags
        end
      when 'layer'
        if argv[0]
          puts Zelda::Tilemaps.tilemaps_by_layer(argv[0])
        else
          puts Zelda::Tilemaps.tilemap_layers
        end
      when 'open'
        Zelda::Config.open_in_default(Zelda::Config.file_html_index, true)
      when 'gen4'
        delete
        Zelda::Config.options[:number] = 4
        dungeon
      when 'gen8'
        delete
        Zelda::Config.options[:number] = 8
        dungeon
    end
  end

  ##############################################################################

  # Main method.
  def self.run(argv = [])
    argv = Zelda::Config.parse_argv [*argv]
    perform_command(Zelda::Config.command, argv)
  end
end

################################################################################

# If run directly, output should be verbose.
if __FILE__ == $0
  Zelda.run ['dungeon', '-v']
end

################################################################################
