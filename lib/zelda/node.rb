#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Simple class to hold infomation about a letter node.
# These will be managed by an enumerable Nodes object.
#   'id' is a number that must be unique to each Node in the Nodes object.
#   'letter' is the letter string that the node represents.
#   'parents' is the optional array of parent nodes, by node id.
################################################################################

module Zelda

  class Node

    attr_reader   :id
    attr_accessor :letter
    attr_accessor :parents, :tight_coupling
    attr_accessor :zone

    # This is a bit generic, but it makes sense to logically separate the
    #   tree-specific named instance vars from the more mission-specific data.
    # This hash will be used for info to help with the mapping to 2D.
    # Current keys = :lock_group_id, :lock_group_total, :lock_group_num
    attr_accessor :metadata

    def initialize(id, letter = nil, parents = [], tight_coupling = [], zone = 0)
      @id = id.to_i
      @letter = letter ? letter : id
      @parents = *parents
      @tight_coupling = *tight_coupling
      @zone = zone
      @metadata = {}
    end

    def to_s
      @id
    end

    def desc
      "#{@id} = #{@letter} = #{@zone}"
    end

    # Array of the ancestors in the chain, all the way back to node 1.
    # Only works when inside a Nodes collection.
    def ancestors(nodes)
      output = []
      self.parents.each do |pid|
        output << pid
        output += nodes.find_by_id(pid).ancestors(nodes)
      end
      output.uniq
    end

    ############################################################################

    def to_a
      [ id, letter, parents, tight_coupling, zone ]
    end

    ############################################################################

    # Class structure of each Node as JSON array.
    def as_json(options={})
      hash = {
        id: @id,
        letter: @letter,
        zone: @zone
      }
      add_if_not_nil(hash, 'parents')
      add_if_not_nil(hash, 'tight_coupling')
      add_if_not_nil(hash, 'metadata')
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
