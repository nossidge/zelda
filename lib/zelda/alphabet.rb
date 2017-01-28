#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Contains both Letter and Alphabet classes.
# Immutable classes for Letter specifications.
# This is hard-coded within this file.
################################################################################
# 'is_threshold' is not used anywhere. The idea was that we could combine rooms
#   together, e.g. have a bonus item room that also contains a locked door.
#   But that is not yet implemented.
################################################################################

module Zelda

  class Letter

    # 'exits' is the number of connecting rooms it can have.
    attr_reader :id, :is_room, :is_threshold, :exits, :desc

    def initialize(id, is_room, is_threshold, exits, desc)
      @id = id
      @is_room = is_room
      @is_threshold = is_threshold
      @exits = exits
      @desc = desc
    end

    def to_s
      @id
    end

  end

  ##############################################################################

  class Alphabet
    @@all = nil

    # Create a hash of Letter objects.
    # For each hash value, the key should be the Letter id.
    def self.all
      if @@all.nil?
        @@all = {}
        [
          ['e' , true,  false, [1],       'entrance'],
          ['g' , true,  false, [1],       'goal'],
          ['n' , true,  false, [1,2,3,4], 'nothing'],
          ['t' , true,  false, [1,2,3,4], 'test'],
          ['ts', false, true,  [1,2,3,4], 'test [secret]'],
          ['k' , true,  false, [1,2,3,4], 'key'],
          ['kp', true,  false, [1,2,3,4], 'key [puzzle]'],
          ['km', true,  false, [1,2,3,4], 'key [multi]'],
          ['kf', true,  false, [1,2,3,4], 'key [final]'],
          ['l' , false, true,  [1,2,3,4], 'lock'],
          ['lp', true,  true,  [2,3,4],   'lock [puzzle]'],
          ['lm', true,  true,  [2,3,4],   'lock [multi]'],
          ['lf', true,  true,  [2,3,4],   'lock [final]'],
          ['ib', true,  false, [1,2,3,4], 'item [bonus]'],
          ['iq', true,  false, [1,2,3,4], 'item [quest]'],
          ['bl', true,  true,  [2],       'boss [level]'],
          ['bm', true,  true,  [2],       'boss [mini]']
        ].each do |i|
          @@all[i[0]] = Letter.new(i[0], i[1], i[2], i[3], i[4]).freeze
        end
      end
      @@all
    end

  end

end

################################################################################
