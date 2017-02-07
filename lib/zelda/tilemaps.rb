#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Read in the TMX files from the directory.
# Examine them for correctness.
# ToDo: Ensure that every possible room configuration
#   can be represented by at least one .tmx file.
################################################################################

module Zelda

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

    def as_json(options={})
      {
        name: @name,
        tags: @tags,
        layers: @layers,
        chest: @chest,
        complexity: complexity
      }
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

    # How picky this tilemap is, with regards to where it can be placed.
    # Used in the JavaScript to prioritise more complex and needy maps.
    # This does not need to be exact, an approximation is acceptable.
    # A higher number indicates a higher complication.
    private def complexity
      return @complexity if !@complexity.nil?

      # Get all the 'fromX' tags, and count the values.
      output = @tags.keys.select do |i|
        i.start_with?('from')
      end.map do |i|
        @tags[i].length
      end.reduce(:+).to_i
      output = (16 - output) / 4

      # How many directions or items are required.
      output += @tags['directionRequired'].andand.length.to_i
      output += @tags['entranceRequired'] .andand.length.to_i
      output += @tags['exitRequired']     .andand.length.to_i
      output += @tags['itemRequired'].andand.split(',').andand.length.to_i * 2
      output += @tags['itemBanned']  .andand.split(',').andand.length.to_i
      output += @tags['itemPrep']    .andand.split(',').andand.length.to_i
      output += @chest ? 0 : 1  # Harder to place if there's no chest.
      @complexity = output
    end
  end

  ##############################################################################

  # Singleton. Holds list of tilemaps in 'Tilemaps.all'
  class Tilemaps

    # Read each file, and load to 'TilemapInfo' instances.
    def self.all
      @@all ||= Dir[Zelda::Config.dir_tilemaps + '/*.tmx'].map do |f|
        TilemapInfo.new(f)
      end
    end

    # Get all the tags that are used by maps.
    def self.tilemap_tags
      @@tilemap_tags ||= self.all.map do |i|
        i.tags.keys
      end.flatten.sort.uniq
    end

    # Get all the maps that use a specific tag.
    def self.tilemaps_by_tag(tag_name)
      self.all.select do |i|
        i.tags.keys.include?(tag_name)
      end.map do |i|
        i.name
      end
    end

    # Read through all the tilemaps and write to the JavaScript code file.
    def self.tilemap_js_make

      # Get all TMX files.
      all_files = Dir[Zelda::Config.dir_tilemaps + '/*.tmx'].map do |f|
        File.basename(f)
      end

      # Ignore any that start with '_'.
      all_files.reject! do |f|
        f.start_with?('_')
      end

      # Seperate into 'maps' and 'patterns'.
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
      File.open(Zelda::Config.file_map_files_js, 'w') do |f|
        f.write Zelda::Config.format_js_array('tilemapFilesMaps', maps)
        f.write Zelda::Config.format_js_array('tilemapFilesPatterns', patterns)
      end
    end

    # Get the tilemap info and write to the JavaScript code file.
    def self.tilemap_info_js_make
      File.open(Zelda::Config.file_map_files_info_js, 'w') do |f|
        json = JSON.pretty_generate(Zelda::Tilemaps.all)
        javascript = json.sub('[','tilemapFilesInfo = [')
        f.puts javascript
      end
    end
  end
end

################################################################################
