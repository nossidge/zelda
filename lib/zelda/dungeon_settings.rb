#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Constraints that the 'nodes' object must follow.
# One 'ConstraintsGrammar' instance is for a single constraint list, and
#   can be used to assert those constraints on multiple 'nodes' objects.
# Ideally, this will also be used for mission Rules, but it's too coupled
#   with the Grammar class for it to be a quick alteration.
################################################################################

module Zelda
  class DungeonSettings

    attr_reader :settings_dir
    attr_reader :mission_constraints
    attr_reader :grammar_rules

    # This cannot be instantiated using invalid data.
    def initialize(settings_dir)
      @settings_dir = settings_dir
      @filepath = "#{Zelda::Config.dir_dungeon_settings}/#{settings_dir}"
      load_mission_constraints
    end

    # Load the constraints from the JSON, and error if not valid.
    # Read all JSON files in the directory.
    private def load_mission_constraints
      @mission_constraints = []
      Dir["#{@filepath}/*.json"].each do |file|
        @mission_constraints << JSON.parse(File.read(file))
      end
      @mission_constraints.flatten!
      validate_constraint_types
    end

    # Make sure each hash in the constraint array contains valid 'type' fields.
    private def validate_constraint_types
      valid_types = [
        'just_one',
        'nodes_count',
        'nodes_before',
        'letter_count'
      ]
      @mission_constraints.each do |constraint|
        if not valid_types.include? constraint['type']
          raise 'Incorrect constraint type.'
        end
      end
    end

    ############################################################################

    # Use the constraints to assert the correctness of the nodes.
    def assert_constraints(nodes)
      constraint_strings = @mission_constraints.map do |i|
        assert_constraint(nodes, i)
      end.flatten

      # For each condition, fail if it is false.
      constraint_strings.each do |cond_string|
        if not eval(cond_string) == true
          return false
        end
      end
      true
    end

    # The 'type' key corresponds to an instance method.
    private def assert_constraint(nodes, constraint)
      self.send(constraint['type'], nodes, constraint)
    end

    ########################################

    # Each of these returns an array of conditions in string form.
    private def just_one(nodes, constraint)
      [*constraint['letters']].map do |i|
        "#{nodes.find_by_letter(i).count} == 1"
      end
    end

    private def nodes_count(nodes, constraint)
      [*constraint['assert']].map do |i|
        "#{nodes.count} #{i}"
      end
    end

    private def nodes_before(nodes, constraint)
      value = nodes.all.select do |n|
        n.zone <= nodes.find_by_letter(constraint['letter'])[0].zone
      end.count
      [*constraint['assert']].map do |i|
        "#{value} #{i}"
      end
    end

    private def letter_count(nodes, constraint)
      value = nodes.find_by_letter(constraint['letter']).count
      [*constraint['assert']].map do |i|
        "#{value} #{i}"
      end
    end

    ############################################################################

  end
end

################################################################################

if __FILE__ == $0
  require_relative '../zelda.rb'
  nodes = nil
  nodes = Zelda::Generate.generate_mission
  dungeon_settings = Zelda::DungeonSettings.new('default')
  p dungeon_settings.assert_constraints(nodes)
end

################################################################################
