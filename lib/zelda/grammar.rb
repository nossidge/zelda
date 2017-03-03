#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# This file specifies the grammars for replacing letters in the mission tree.
# Methodology:
#   Find a node or parent/child connected group of nodes with specific
#   letters, and replace them with one or more other nodes. These subsequent
#   nodes can be connected in whatever way, using the optional 3rd argument of
#   Node.new to specify the parent ID.
#   Code location is Zelda::Nodes#replace_sequence_with_sequence
# These are read in from .dot files, that each must contain a single rule.
#   The location of these files is specified in 'Zelda::Config.dir_rules'
################################################################################

require_relative 'nodes.rb'

################################################################################

module Zelda

  class Grammar

    attr_reader :rules            # List of node substitutions.
    attr_reader :rules_start      # Substitutions of the 'S' start node.
    attr_reader :files_start      # Array of files that contain start rules.
    attr_reader :start_rule_name  # The currently chosen start rule file name.
    attr_reader :zone_traversal   # Zone traversal requiring quest item.
                                  #   Key is the file basename.
    attr_reader :failed_attempts  # Number of failed tree making attempts.
    attr_accessor :verbose        # Print failures to stdout. Very noisy.

    def initialize(verbose = Zelda::Config.options[:verbose_grammar])
      @rules           = {}
      @rules_start     = []
      @files_start     = []
      @start_rule_name = nil
      @zone_traversal  = Hash.new { |h,k| h[k] = [] }
      @failed_attempts = 0
      @verbose         = verbose
    end

    ############################################################################

    # Get the rules that we will be using.
    # This puts all the normal rules into the selection bucket,
    #   but chooses only one start rule.
    def get_rules
      get_normal_rules + get_start_rules
    end
    def get_normal_rules
      @files_start.each do |filename|
        @rules_start += [ @rules[filename] ]
      end
      @rules.values - @rules_start
    end
    def get_start_rules
      @start_rule_name ||= random_start_rule
      [ @rules[@start_rule_name] ]
    end

    # Return the file name of a random starting rule.
    def random_start_rule
      @start_rule_name = @files_start.seed_sample_increment
    end

    ############################################################################

    # Get the correct 'zone_traversal' element for the 'start_rule'
    def get_zone_traversal
      @zone_traversal[@start_rule_name]
    end

    ############################################################################

    # Load the grammar rules from the settings directory.
    def rules_from_dungeon_settings(settings_dir = 'default')
      load_rules('*', "#{Zelda::Config.dir_dungeon_settings}/#{settings_dir}")
    end

    def load_rules(rule_file_globs, directory = Zelda::Config.dir_rules)
      rules = {}
      [*rule_file_globs].each do |glob|
        hash = load_from_rules("#{directory}/#{glob}.dot")
        rules = rules.merge(hash)
      end
      @rules = rules
    end

    ############################################################################

    # Inputs are in the form "id = letter = zone" or "id = letter"
    # Old chains use '-' as the separator.
    # New chains use '=' as the separator.
    def parse_dot_node(node_name)
      node_name = node_name.split(' ')
      {
        id:     node_name[0].to_i,
        letter: node_name[2],
        zone:   node_name[4].to_i,
        type:  (node_name[1] == '=') ? 'new' : 'old'
      }
    end

    ############################################################################

    # Returns a hash with the file as the key.
    def load_from_rules(file_glob)
      output = {}
      Dir[file_glob].map do |f|
        base_name = File.basename(f, '.dot')
        output[base_name] = self.grammar_from_dotfile(f)
      end
      output
    end

    # Read in grammar replacements from a dotfile.
    def grammar_from_dotfile(file)
      base_name = File.basename(file, '.dot')

      # These will eventually be output as Node arrays, but we
      #   need to use some Nodes methods to create the trees.
      nodes_new = Zelda::Nodes.new
      nodes_old = Zelda::Nodes.new

      # Regex taken from:
      # http://rgl.rubyforge.org/rgl/files/examples/examples_rb.html
      pattern_single = /^  "([^\"]+)"$/
      pattern_relationship = /\s*([^\"]+)[\"\s]*->[\"\s]*([^\"\[\;]+)/
      pattern_zone_traversal = /# traversal: \[(.*),(.*)\]/

      # For each line, add the nodes to the correct 'Nodes' collection.
      IO.foreach(file) do |line|

        # Single node, with no parent/child relationship.
        if line[pattern_single]
          node = parse_dot_node($1)

          # Add to the old chain, or the new replacement chain?
          nodes = (node[:type] == 'new') ? nodes_new : nodes_old

          # Add the node, if it does not yet exist.
          if nodes.find_by_id(node[:id]).nil?
            nodes.add(node[:letter], [], [], node[:zone], node[:id])
          end

          # If it just contains 'S', then it's a start rule.
          if node[:letter] == 'S'
            @files_start << base_name
          end

        # Node with parent/child relationship.
        elsif line[pattern_relationship]
          from = parse_dot_node($1)
          to   = parse_dot_node($2)

          # Add to the old chain, or the new replacement chain?
          nodes = (to[:type] == 'new') ? nodes_new : nodes_old

          # Add the 'from' node, if it does not yet exist.
          if nodes.find_by_id(from[:id]).nil?
            nodes.add(from[:letter], [], [], from[:zone], from[:id])
          end

          # Do we need a 'tight_coupling' parent?
          # (In the visual graph, this means the line is red)
          tight_coupling = []
          in_brackets = line[/\[(.*?)\]/]
          if in_brackets and in_brackets.gsub(/\s+/,'') == '[color=red]'
            tight_coupling = from[:id]
          end

          # Add the 'to' node, or amend it if it exists.
          to_node = nodes.find_by_id(to[:id])
          if to_node.nil?
            nodes.add(to[:letter], from[:id], tight_coupling, to[:zone], to[:id])
          else
            to_node.letter = to[:letter]
            to_node.parents << from[:id]
            to_node.tight_coupling << tight_coupling if tight_coupling != []
          end

        # Zone traversal requiring quest item.
        elsif line[pattern_zone_traversal]
          @zone_traversal[base_name] << [$1.to_i, $2.to_i]
        end
      end

      # Output as array of array of nodes.
      [ nodes_old.map{|k,v|v}, nodes_new.map{|k,v|v} ]
    end

    ############################################################################

    # Convert all the DOT files in the directory to PNG, and output an
    #   HTML page to see them next to each other.
    # Ideally this would be done using 'viz.js'
    # ToDo: This needs to be amended to use the new 'dungeon_settings' dir.
    def self.output_html

      # Initialise the HTML and file stuff.
      dir_rules = Zelda::Config.dir_rules
      dir_img   = Zelda::Config.dir_output + '/img/rules'
      rel_img   = 'img/rules'
      html = ''

      # Find all .dot files.
      Dir["#{dir_rules}/*.dot"].each do |f|
        filename = File.basename(f, '.dot')

        # Convert to png using the command line.
        system %{dot -Tpng "#{dir_rules}/#{filename}.dot" > "#{dir_img}/#{filename}.png"}

        # Add the image and description to the HTML output.
        elem_id = filename.gsub(' ','_')
        html += %{<div id='#{elem_id}' class='graph' onclick="toggleSelection('#{elem_id}')">}
        html += "<p><input id='check_#{elem_id}' type='checkbox' hidden>"
        html += "#{filename}</p>"
        html += "<img src='#{rel_img}/#{filename}.png'></div>"
      end

      # Save to HTML using the template file.
      File.open(Zelda::Config.file_grammar, 'w') do |fo|
        File.open(Zelda::Config.file_grammar_template, 'r') do |fi|
          fo.puts fi.read.gsub('<!-- @DOT_PNGS -->', html)
        end
      end

      # Open in default browser, if necessary.
      Zelda::Config.open_in_default(Zelda::Config.file_grammar)
    end

    ############################################################################

  end
end

################################################################################
