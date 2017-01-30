#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Class to hold infomation about a 'room' in a 2D dungeon.
################################################################################

require 'json'

################################################################################

module Zelda

  class Room

    # The coordinates in the dungeon map.
    attr_accessor :x, :y

    # 'id', 'letter' and 'zone' map to the mission tree node.
    attr_accessor :id, :letter, :zone

    # This is the same data as in the originating 'node' metadata.
    # It will only be used if the room is a lock or a key.
    # Keys = :id, :num, :total
    attr_reader :lock_group

    # Stores an array of all four neighbour cells, as ['W', [x, y]].
    # This is randomised, for dungeon mapping purposes.
    attr_reader :neighbours

    # 'exits' is a string i.e. 'NSW'
    # 'entrance' is the same, but just one character.
    attr_reader :exits, :entrance
    attr_reader :exits_one_way_orig, :exits_one_way_dest
    attr_reader :exits_quest_item

    # If the room is an 'l' room, which direction is it locking?
    # (This is for all letters that start with 'l', currently: 'l', 'lm', 'lf'.)
    # Also for the room that leads to the boss.
    attr_accessor :lock_orig, :lock_dest
    attr_accessor :lock_puzzle_orig, :lock_puzzle_dest
    attr_accessor :multi_lock_orig, :multi_lock_dest
    attr_accessor :boss_lock_orig, :boss_lock_dest

    # Bombable / burnable walls.
    attr_accessor :weak_walls_orig, :weak_walls_dest, :weak_walls_hidden

    # Observatory for bombable wall hints.
    attr_accessor :observatory_orig, :observatory_dest

    def initialize(x, y, id, letter, zone, exits='')
      @x = x
      @y = y
      @id = id.to_i
      @letter = letter
      @zone = zone
      @exits = exits
      @lock_orig = ''
      @lock_dest = ''
      @lock_puzzle_orig = ''
      @lock_puzzle_dest = ''
      @boss_lock_orig = ''
      @boss_lock_dest = ''
      @multi_lock_orig = ''
      @multi_lock_dest = ''
      @weak_walls_orig = ''
      @weak_walls_dest = ''
      @weak_walls_hidden = ''
      @exits_one_way_orig = ''
      @exits_one_way_dest = ''
      @exits_quest_item = ''
      @observatory_orig = ''
      @observatory_dest = ''
      @lock_group = {}
      self.initialize_neighbours
    end

    def to_s
      "#{@x},#{@y}"
    end
    def desc
      "#{@x},#{@y},#{@letter},#{@exits}"
    end
    def node_id
      "#{@id} = #{@letter}"
    end

    # The y coord, if the origin was top left, not bottom left.
    def origin_topleft_y
      @y
    end

    # Level bosses should mostly lead north, and south should be a last resort.
    def initialize_neighbours
      if @letter != 'bl'
        @neighbours = [
          ['S', Coords.new(x, y-1) ],
          ['N', Coords.new(x, y+1) ],
          ['W', Coords.new(x-1, y) ],
          ['E', Coords.new(x+1, y) ]
        ].seed_shuffle_increment
      else
        @neighbours = [ ['N', Coords.new(x, y+1) ] ]
        [ ['W', Coords.new(x-1, y) ],
          ['E', Coords.new(x+1, y) ]
        ].seed_shuffle_increment.each do |i|
          @neighbours += [ i ]
        end
        @neighbours += [ ['S', Coords.new(x, y-1) ] ]
      end
      @neighbours
    end

    # Get the next random neighbour cell.
    def next_neighbour
      output = @neighbours[0]
      @neighbours.rotate!
      output
    end

    # Get the neighbouring rooms that currently exist.
    def neighbour_rooms(rooms)
      @neighbours.select do |n|
        !rooms.room(n[1].x, n[1].y).nil?
      end
    end

    ############################################################################

    # Make sure it is impossible to add an exit to a
    #   room that already has the maximum number.
    # Return Boolean success or failure.
    def add_exit(dir)

      # Only add if we are not already at the maximum exit count.
      if exits_available?

        # Make sure the string is in the right order.
        exits = @exits + dir
        @exits = %w(N E S W).reject do |i|
          !exits.include? i
        end.join

        true
      else
        false
      end
    end

    # Force a new exit, even if we are at the maximum exit count.
    def add_exit_force(dir)
      exits = @exits + dir
      @exits = %w(N E S W).reject do |i|
        !exits.include? i
      end.join
      true
    end

    def delete_exit(dir)
      @exits.tr!(dir, '')
    end
    def add_entrance(dir)
      @entrance = dir
    end
    def add_exit_one_way_orig(dir)
      exits = @exits_one_way_orig + dir
      @exits_one_way_orig = %w(N E S W).reject do |i|
        !exits.include? i
      end.join
    end
    def add_exit_one_way_dest(dir)
      exits = @exits_one_way_dest + dir
      @exits_one_way_dest = %w(N E S W).reject do |i|
        !exits.include? i
      end.join
    end
    def add_exit_quest_item(dir)
      exits = @exits_quest_item + dir
      @exits_quest_item = %w(N E S W).reject do |i|
        !exits.include? i
      end.join
    end

    # Use Alphabet to find the highest number of exits possible.
    # There's only space if we are not already at the maximum exit count.
    def exits_available?
      @exits.length < Alphabet.all[@letter].exits.max
    end

    # See if the current number of exits is valid according to the Letter.
    def exits_valid?
      Alphabet.all[@letter].exits.include?(@exits.length)
    end

    # This is the inverse of @exits.
    def walls
      %w(N E S W).select do |i|
        !@exits.include?(i) and !@exits_one_way_orig.include?(i)
      end.join
    end

    # These are exits which do not have any sort of barrier.
    def exits_open
      output = @exits
      exit_complications = [
        @lock_orig,
        @lock_dest,
        @lock_puzzle_orig,
        @lock_puzzle_dest,
        @boss_lock_orig,
        @boss_lock_dest,
        @multi_lock_orig,
        @multi_lock_dest,
        @weak_walls_orig,
        @weak_walls_dest,
        @weak_walls_hidden,
        @exits_one_way_orig,
        @exits_one_way_dest,
        @exits_quest_item
      ]
      exit_complications.each do |comp|
        output.tr!(comp, '')
      end
      output
    end

    ############################################################################

    # Copy the metadata from the node to the room.
    def transfer_node_metadata(node)
      if not node.metadata.empty?
        @lock_group[:id]    = node.metadata[:lock_group_id]
        @lock_group[:type]  = node.metadata[:lock_group_type]
        @lock_group[:num]   = node.metadata[:lock_group_num]
        @lock_group[:total] = node.metadata[:lock_group_total]
      end
    end

    ############################################################################

    # Class structure as JSON.
    # Certain variables are not needed if they are nil or empty strings.
    def as_json(options={})
      hash = {
        id: @id,
        x: @x,
        y: @y,
        zone: @zone,
        letter: @letter,
        entrance: @entrance,
        exits: @exits
      }
      hash['walls'] = walls if !walls.to_s.empty?
      hash['exits_open'] = exits_open if !exits_open.to_s.empty?
      add_if_not_nil(hash, 'exits_one_way_orig')
      add_if_not_nil(hash, 'exits_one_way_dest')
      add_if_not_nil(hash, 'exits_quest_item')
      add_if_not_nil(hash, 'lock_orig')
      add_if_not_nil(hash, 'lock_dest')
      add_if_not_nil(hash, 'lock_puzzle_orig')
      add_if_not_nil(hash, 'lock_puzzle_dest')
      add_if_not_nil(hash, 'boss_lock_orig')
      add_if_not_nil(hash, 'boss_lock_dest')
      add_if_not_nil(hash, 'multi_lock_orig')
      add_if_not_nil(hash, 'multi_lock_dest')
      add_if_not_nil(hash, 'weak_walls_orig')
      add_if_not_nil(hash, 'weak_walls_dest')
      add_if_not_nil(hash, 'weak_walls_hidden')
      add_if_not_nil(hash, 'observatory_orig')
      add_if_not_nil(hash, 'observatory_dest')
      add_if_not_nil(hash, 'lock_group')
      hash
    end

    def add_if_not_nil(hash, var_name, hash_key = var_name)
      inst_val = self.send("#{var_name}")
      if !(inst_val.to_s.empty? || %w([] {}).include?(inst_val.to_s))
        hash[hash_key] = inst_val
      end
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

  end

end

################################################################################
