#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Contains both Equipment and EquipmentList classes.
# Immutable classes for Equipment specifications.
# This is hard-coded within this file.
################################################################################

module Zelda

  # The 'id' is also the name of the PNG file in 'chest_contents.json'.
  class Equipment
    attr_reader :id, :name
    def initialize(id, name)
      @id = id
      @name = name
    end
  end

  ##############################################################################

  # This stores a list of equipment info hashes.
  class EquipmentList

    # Create a hash of Equipment objects.
    # Separated by how early in the game they are acquired.
    def self.level_1
      @@level_1 ||= array_to_equipment_hash [
        ['shield1',         "Wooden Shield"],
        ['sword1',          "Wooden Sword"],
        ['bomb1',           "Bomb"]
      ].freeze
    end
    def self.level_2
      @@level_2 ||= array_to_equipment_hash [
        ['roc1',            "Roc's Feather"],
        ['bracelet3',       "Power Bracelet"],
        ['pegasus_boots',   "Pegasus Boots"],
        ['hammer',          "Hammer"]
      ].freeze
    end
    def self.level_3
      @@level_3 ||= array_to_equipment_hash [
        ['flippers',        "Flippers"],
        ['fire_rod',        "Fire Rod"],
        ['hook_switch',     "Switch Hook"],
        ['cane_of_somaria', "Cane of Somaria"]
      ].freeze
    end
    def self.full_game
      [ level_1.keys,
        level_2.keys.shuffle,
        level_3.keys.shuffle
      ].flatten
    end

    # Create a hash of Equipment objects.
    # These are as yet unimplemented.
    def self.unimplemented
      @@unimplemented ||= array_to_equipment_hash [
        ['shovel', "Shovel"],
        ['magic_powder', "Magic Powder"],
        ['bow', "Bow"],
        ['roc3', "Roc's Cape"],
        ['boomerang1', "Boomerang"],
        ['boomerang3', "Magic Boomerang"],
        ['hook_shot', "Hookshot"],
        ['shield2', "Iron Shield"],
        ['shield3', "Mirror Shield"],
        ['sword2', "Steel Sword"],
        ['sword3', "Noble Sword"],
        ['sword4', "Master Sword"],
        ['magnetic_glove', "Magnetic Gloves"],
        ['ladder', "Stepladder"],
        ['mermaid_suit', "Mermaid Suit"],
        ['id', "Power Glove"],
        ['id', "Titan's Mitt"],
        ['id', "Longshot"],
        ['id', "Long Hook"],
        ['id', "Lantern"],
        ['id', "Ice Rod"],
        ['id', "Sand Rod"],
        ['id', "Raft"],
        ['id', "Hover Boots"],
        ['id', "Iron Boots"],
        ['id', "Ember Seed"],
        ['id', "Scent Seed"],
        ['id', "Gale Seed"],
        ['id', "Pegasus Seed"],
        ['id', "Mystery Seed"],
        ['id', "Seed Satchel"],
        ['id', "Seed Shooter"],
        ['id', "Slingshot"],
        ['id', "Hyper Slingshot"],
        ['id', "Gnat Hat"],
        ['id', "Grip Ring"],
        ['id', "Gust Jar"],
        ['id', "Cane of Pacci"],
        ['id', "Mole Mitts"],
        ['id', "Spinner"],
        ['id', "Ball and Chain"],
        ['id', "Dominion Rod"],
        ['id', "Whip"],
        ['id', "Fireshield Earrings"]
      ].freeze
    end

    # For each hash value, the key should be the Equipment id.
    def self.array_to_equipment_hash(array)
      output = {}
      array.each do |i|
        output[i[0]] = Equipment.new( *i ).freeze
      end
      output
    end
  end
end

################################################################################
