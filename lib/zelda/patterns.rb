#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Attempt to perform the 'determinePatterns' function from 'rooms.js'
# to determine what room map patterns can be applied to this dungeon.
# This is smaller in scope, however. We don't need to know which rooms
# match which patterns, just that a pattern can be matched somewhere.
################################################################################

module Zelda
  module Patterns

    # Returns an array of pattern names.
    def self.patterns_available dungeon
      output_patterns = []

      # Read in all the patterns to an array.
      patterns_js = Zelda::Config.read_map_patterns_js

      # Loop through each room and see if it matches a pattern start room.
      dungeon.rooms.each do |room|

        # Loop through each pattern and see if it matches.
        patterns_js.each do |pattern|

          # For each 'room' in the pattern.
          is_valid = true
          pattern[:rooms].each do |pattern_room|

            # These are relative to the first room with id = 1.
            roomX = room.x + pattern_room[:relative][:x]
            roomY = room.y - pattern_room[:relative][:y]
            traversed_room = dungeon.rooms.room(roomX, roomY)

            is_valid = false if !is_match(traversed_room, pattern_room)
            break if !is_valid
          end

          output_patterns << pattern[:name] if is_valid
        end
      end
      output_patterns.sort.uniq
    end

    private

      # Little methods for finding all values or one value
      # in an array of needles, within a haystack array.
      def self.find_one haystack, needles
        needles.any? do |i|
          haystack.include?(i)
        end
      end
      def self.find_all haystack, needles
        needles.all? do |i|
          haystack.include?(i)
        end
      end

      # Does the room match the chosen pattern?
      def self.is_match(room, pattern_room)
        return false if !room

        # If the room is an observatory, then it is not valid.
        return false if room.observatory_dest != ''

        # Loop through each 'pattern_room.absolute' property.
        is_valid = true
        [:all_of, :one_of, :none_of].each do |absolute_type|
          absolute = pattern_room[:absolute][absolute_type]
          keys = absolute.keys rescue []
          keys.each do |property|

            # ToDo: We are not yet specifying the equipment.
            next if property == :equipment

            # Make sure it matches the 'room' property.
            # These are strings of letters, so check if it's in the string.
            if room.send(property) != ''

              # Split to array, if not already.
              arr_abso = absolute[property]
              arr_abso = arr_abso.split('') if !arr_abso.is_a?(Array)
              arr_room = room.send(property)
              arr_room = arr_room.split('') if !arr_room.is_a?(Array)

              case absolute_type

                # If it's not in the room property, then it's not valid.
                when :one_of
                  is_valid = false if !find_one(arr_room, arr_abso)

                # If it's not ALL in the room property, then it's not valid.
                when :all_of
                  is_valid = false if !find_all(arr_room, arr_abso)

                # If it IS in the room property, then it's not valid.
                when :none_of
                  is_valid = false if find_one(arr_room, arr_abso)
              end

            elsif [:one_of, :all_of].include?(absolute_type)
              is_valid = false
            end

          end

          # No need to keep iterating if it's already proven to be invalid.
          break if !is_valid
        end

        # Return whether or not the room and pattern room match.
        is_valid
      end

  end
end

################################################################################
