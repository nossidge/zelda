#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Read in the TMX files from the directory.
# Examine them for correctness.
# ToDo: Ensure that every possible room configuration
#   can be represented by at least one .tmx file.
################################################################################

require 'tmx'

################################################################################

module Zelda

  ##############################################################################

  # Don't store everything about the TileMap, just the stuff we need.
  class TilemapInfo
    attr_reader :name, :tags, :layers, :chest
    def initialize(filepath)
      tilemap = Tmx.load(filepath)
      @name = File.basename(filepath, '.tmx')
      @tags = tilemap.properties
      @layers = tilemap.layers.map{ |i| i.name }
      @chest = @layers.include?('Chest')
    end
  end

  ##############################################################################

  # Singleton. Holds list of tilemaps in 'tilemap_info_list'
  class Tilemaps

    # Read each file, and load to 'TilemapInfo' instances.
    def self.tilemaps
      @@tilemaps ||= Dir[Zelda::Config.dir_tilemaps + '/*.tmx'].map do |f|
        TilemapInfo.new(f)
      end
    end

    # Get all the tags that are used by maps.
    def self.tilemap_tags
      @@tilemap_tags ||= tilemaps.map do |i|
        i.tags.keys
      end.flatten.sort.uniq
    end

    # Get all the maps that use a specific tag.
    def self.tilemaps_by_tag(tag_name)
      tilemaps.select do |i|
        i.tags.keys.include?(tag_name)
      end.map do |i|
        i.name
      end
    end

    # Read through all the tilemaps and write to the JavaScript code file.
    def self.tilemap_js_make

      # Seperate into 'maps' and 'patterns'.
      all_files = Dir[Zelda::Config.dir_tilemaps + '/*.tmx'].map do |f|
        File.basename(f)
      end
      patterns = all_files.select do |f|
        f.start_with?('pattern_')
      end
      maps = all_files - patterns

      # Add the img relative directory prefix.
      pref = Zelda::Config.dir_tilemaps.sub(Zelda::Config.dir_output, '')
      pref = pref.sub(/^\//,'').sub(/\/$/,'') + '/'
      maps.map!     { |f| pref + f }
      patterns.map! { |f| pref + f }

      # Output string of JavaScript array assignment.
      File.open(Zelda::Config.map_files_js, 'w') do |f|
        f.write Zelda::Config.format_js_array('tilemapFilesMaps', maps)
        f.write Zelda::Config.format_js_array('tilemapFilesPatterns', patterns)
      end
    end
  end
end

################################################################################
