#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Holds a hash of Room objects.
# 'rooms' is a hash with key the same as the vars [#x, #y].
# X and Y values can be negative, to account for uncertainty in map generation
#   when adding rooms. '#recalculate_coords!' can be used to redraw from zero.
################################################################################

require 'json'

################################################################################

module Zelda

  class Rooms
    include Enumerable

    # This is the main array of the collection.
    # Stores hash of Room objects, by [x, y] keys.
    attr_reader :rooms

    # Stores an array of rooms as [x, y] pairs in the order they were added.
    attr_reader :rooms_added

    # Array of [x, y] pairs where rooms should not be written.
    attr_reader :reserved_rooms

    # Highest and lowest X and Y values in the keys of @rooms.
    # Must call #calculate_mins_and_maxs for accurate stats.
    attr_reader :min, :max

    # 'lock_group's that cannot be small keys.
    attr_accessor :lock_groups_non_small_key

    # 'lock_group's that contain one or more observatories.
    attr_accessor :lock_groups_observatory

    # Name of the dungeon.
    attr_accessor :dungeon_name

    # Zone containing the equipment quest item.
    attr_accessor :quest_item_zone

    def initialize
      @rooms = Hash.new(nil)
      @rooms_added = []
      @reserved_rooms = []
      @lock_groups_non_small_key = nil
      @lock_groups_observatory = nil
      @min = Coords.new(0,0)
      @max = Coords.new(0,0)
      @dungeon_name = generate_dungeon_name
      @quest_item_zone = nil
    end
    def room(x, y)
      @rooms[[x, y]]
    end

    # Enumerate through each room.
    def each(&block)
      @rooms.each do |k,v|
        block.call(v)
      end
    end

    # Get just the rooms from the hash, without the Coords key.
    def all
      @rooms.map{ |k,v| v }
    end

    # Count rooms.
    def size
      @rooms.size
    end

    # Get all zones.
    def zones
      self.map{|r|r.zone}.sort.uniq
    end

    # Find the room from id, not x,y key.
    def find(id)
      @rooms.each do |k,v|
        return v if v.id == id.to_i
      end
      nil
    end

    # Edit the rooms.
    def add(x, y, letter, zone, exits='')
      if @rooms[[x, y]].nil?
        @rooms[[x, y]] = Room.new(x, y, letter, zone, exits)
        @rooms_added << [x, y]
      end
      @rooms[[x, y]]
    end
    def alter_letter(x, y, letter)
      @rooms[[x, y]].letter = letter
    end

    # If the room doesn't exist, then it will error.
    def add_exit(x, y, dir)
      @rooms[[x, y]].add_exit(dir)
    end
    def add_exit_force(x, y, dir)
      @rooms[[x, y]].add_exit_force(dir)
    end
    def add_entrance(x, y, dir)
      @rooms[[x, y]].add_entrance(dir)
    end
    def add_one_way(x, y, dir)
      @rooms[[x, y]].add_one_way(dir)
    end

    # See if the number of exits is valid for all rooms.
    def exits_valid?
      exits_valid_reasons(false)
    end
    def exits_valid_reasons(give_reason = true)
      bool_valid = true
      rooms_failed = []
      @rooms.each do |key, room|
        if !room.exits_valid?
          if give_reason
            rooms_failed << room
          else
            bool_valid = false
            break
          end
        end
      end
      give_reason ? rooms_failed : bool_valid
    end

    # Does the room exist?
    def exists?(x, y)
      !@rooms[[x, y]].nil?
    end

    # Find the largest and smallest Xs & Ys.
    def calculate_mins_and_maxs
      num = 9999
      @min = Coords.new( num,  num)
      @max = Coords.new(-num, -num)
      @rooms.each do |k,r|
        @min.x = r.x if r.x < @min.x
        @min.y = r.y if r.y < @min.y
        @max.x = r.x if r.x > @max.x
        @max.y = r.y if r.y > @max.y
      end
      self
    end

    # Re-draw the table from 0,0 origin.
    def recalculate_coords!
      self.calculate_mins_and_maxs

      # Alter the coords in each Room.
      @rooms.each do |k,r|
        r.x -= @min.x
        r.y -= @min.y
        (0..3).each do |i|
          r.neighbours[i][1].x -= @min.x
          r.neighbours[i][1].y -= @min.y
        end
      end

      # Can't change the keys of a hash, so we need to make a new one.
      # Clone the original hash with the new coords as the keys.
      rooms_new = Hash.new(nil)
      @rooms.each do |k,r|
        rooms_new[ [r.x, r.y] ] = r
      end
      @rooms = rooms_new

      # Set the new min/max values.
      self.calculate_mins_and_maxs
      self
    end

    # Find a random existing room.
    # Should just be able to loop through the keys in @rooms.
    def random_room
      @rooms[@rooms.keys.seed_sample_increment]
    end

    # Same, but matches a yielded block condition
    def random_room_condition
      self.all.select do |i|
        yield i
      end.seed_sample_increment
    end

    # 'coords' should be a [x,y] pair.
    def room_free?(coords)
      !(@reserved_rooms + @rooms.keys).include?(coords)
    end

    ############################################################################

    # Methods to handle reserved rooms.
    def reserved_rooms_clear
      @reserved_rooms = []
    end

    # Add ad-hoc coords.
    def reserved_rooms_add(x, y)
      @reserved_rooms << [x, y]
    end

    # Make sure no rooms can be drawn south of the [0,0] entrance.
    def reserved_rooms_bottom_row
      (-100..100).each do |x|
        @reserved_rooms << [x, -1]
      end
    end

    # Kind of looks like a castle ramparts/balustrade, with holes in the middle.
    def reserved_rooms_castle
      # Spaces in the middle.
      [2,4,6,8,10].each do |y|
        @reserved_rooms << [ 1, y]
        @reserved_rooms << [-1, y]
      end

      # Walls to the side.
      (-100..100).each do |y|
        @reserved_rooms << [ 3, y]
        @reserved_rooms << [-3, y]
      end
    end

    # Dungeon with a central hole, like Bottle Grotto from Link’s Awakening.
    def reserved_rooms_bottle
      (-100..100).each do |i|
        # Rooms next to the entrance (0,0), and far wall.
        @reserved_rooms << [i, 0]
        @reserved_rooms << [i, 7]

        # Walls to the side.
        @reserved_rooms << [ 4, i]
        @reserved_rooms << [-4, i]
      end

      # Spaces in the middle.
      [2,3,4].each do |y|
        @reserved_rooms << [ 1, y]
        @reserved_rooms << [ 0, y]
        @reserved_rooms << [-1, y]
      end
    end

    # Make sure the dungeon can't get any larger than 7x7.
    # Args should be in the form: (width, length)
    def reserved_rooms_area(*args)
      if args.size == 1
        width = length = args[0]
      else
        width  = args[0]
        length = args[1]
      end

      (-100..100).each do |i|
        # Rooms next to the entrance (0,0), and far wall.
#        @reserved_rooms << [i, 0]
        @reserved_rooms << [i, length]

        # Walls to the side.
        width_half = (width/2.0).ceil
        @reserved_rooms << [  width_half, i]
        @reserved_rooms << [-(width_half - (width % 2 == 0 ? 1 : 0)), i]
      end
    end

    ############################################################################

    # Nice hash of each key/lock group.
    def all_lock_groups
      self.all.select do |room|
        !room.lock_group.empty?
      end.sort_by do |room|
        room.lock_group[:id]
      end.map do |room|
        {
          id: room.lock_group[:id],
          type: room.lock_group[:type],
          total: room.lock_group[:total]
        }
      end.uniq
    end

    ############################################################################

    # Generate an example dungeon name.
    def generate_dungeon_name
      prefixes = %w(tail bottle key angler's catfish's face eagle's turtle swamp
        skull desert icy forest shadow spirit woodfall snowhead stone moon
        spirit's wing moonlit crown mermaid's ancient black hero's gnarled
        root snake's unicorn's explorer's lakebed forsaken forbidden skyview
        moblin goron dodongo zora maku
      )
      suffixes = %w(cave cavern grotto tower chasm temple shrine mines ruins
        palace castle woods mire tunnel rock dungeon fortress well path lair
        keep grave tomb remains crypt maze pyramid grounds
      )
      {
        line_1: prefixes.seed_sample.capitalize,
        line_2: suffixes.seed_sample.capitalize
      }
    end

    ############################################################################

    # Class structure of each Room as JSON array.
    def as_json(options={})
      hash = {
        dungeon_name: @dungeon_name,
        seed: Zelda::Config.seed_dungeon,
        min: {
          x: @min.x,
          y: @min.y
        },
        max: {
          x: @max.x,
          y: @max.y
        }
      }
      add_if_not_nil(hash, 'quest_item_zone')
      add_if_not_nil(hash, 'all_lock_groups', 'lock_groups')
      add_if_not_nil(hash, 'lock_groups_non_small_key')
      add_if_not_nil(hash, 'lock_groups_observatory')
      hash2 = {
        rooms: self.sort_by do |i|
          i.id
        end.map do |i|
          i.as_json(*options)
        end
      }
      hash.merge(hash2)
    end

    def add_if_not_nil(hash, var_name, hash_key = var_name)
      inst_val = self.send(var_name)
      if !(inst_val.to_s.empty? || %w([] {}).include?(inst_val.to_s))
        hash[hash_key] = inst_val
      end
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

    # Write 'as_json' to a JSON file.
    def save_json(filename)
      File.open("#{filename}.json",'w') do |f|
        f.write JSON.pretty_generate(self.as_json)
      end
    end

  end

end

################################################################################
