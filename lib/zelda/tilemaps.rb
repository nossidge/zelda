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

    attr_reader :name, :tags, :layers, :chest, :crystal

    # Argument can be a filename, or an existing hash.
    def initialize(filepath_or_hash)
      if not filepath_or_hash.is_a?(Hash)
        tilemap  = Tmx.load(filepath_or_hash)
        @name    = File.basename(filepath_or_hash, '.tmx')
        @tags    = tilemap.properties
        @layers  = tilemap.layers.map{ |i| i.name }
        @chest   = @layers.include?('Chest')
        @crystal = @layers.include?('Crystal')
      else
        @name    = filepath_or_hash[:name]
        @tags    = filepath_or_hash[:tags]
        @layers  = filepath_or_hash[:layers]
        @chest   = filepath_or_hash[:chest]
        @crystal = filepath_or_hash[:crystal]
      end
    end

    def as_json(options={})
      {
        name: @name,
        tags: @tags,
        layers: @layers,
        chest: @chest,
        crystal: @crystal,
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
      @complexity = output + 1
    end
  end

  ##############################################################################

  # Singleton. Holds list of tilemaps in 'Tilemaps.all'
  class Tilemaps

    # Read each file, and load to 'TilemapInfo' instances.
    # Only load map files, not patterns.
    def self.all
      @@all ||= nil; return @@all if !@@all.nil?
      @@all = Dir[Zelda::Config.dir_tilemaps + '/*.tmx'].reject do |f|
        base = File.basename(f)
        base.start_with?('_') || base.start_with?('pattern_')
      end.map do |f|
        TilemapInfo.new(f)
      end
    end

    ########################################

    # Get all the tags that are used by maps.
    def self.tilemap_tags
      @@tilemap_tags ||= self.all.map do |i|
        i.tags.keys
      end.flatten.sort.uniq
    end

    # Get all the maps that use a specific tag.
    def self.tilemaps_by_tag(tag_name)
      self.all.select do |i|
        i.tags.keys.map{ |j| j.downcase }.include?(tag_name.downcase)
      end.map do |i|
        i.name
      end
    end

    ########################################

    # Get all the layers that are used by maps.
    def self.tilemap_layers
      @@tilemap_layers ||= self.all.map do |i|
        i.layers
      end.flatten.sort.uniq
    end

    # Get all the maps that use a specific layer.
    def self.tilemaps_by_layer(layer_name)
      self.all.select do |i|
        i.layers.map{ |j| j.downcase }.include?(layer_name.downcase)
      end.map do |i|
        i.name
      end
    end

    ########################################

    # Get the tilemap info from the JSON, and eval to read into Ruby array.
    def self.tilemap_js_read
      json = File.open(Zelda::Config.file_map_files_info_js, 'r').read
      eval(json).map { |i| TilemapInfo.new(i) }
    end

    ########################################

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
