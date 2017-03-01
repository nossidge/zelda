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
    attr_reader :constraints      # Conditions that a mission tree must pass.
    attr_reader :zone_traversal   # Zone traversal requiring quest item.
                                  #   Key is the file basename.
    attr_reader :failed_attempts  # Number of failed tree making attempts.
    attr_accessor :verbose        # Print failures to stdout. Very noisy.

    def initialize(verbose = Zelda::Config.options[:verbose_grammar])
      @rules           = {}
      @rules_start     = []
      @constraints     = nil
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

    # Select how complex you want the grammar to be.
    # This will eventually be a config option, but for now it's hard coded.
    def rules_all
      load_rules('*')
    end
    def rules_simple
      load_rules %w(
        start_chain_01
        linear_chain*
        parallel_chain*
        hook*
        final_chain*
      )
    end
    def rules_complex
      load_rules %w(
        start_chain_multi_01
        linear_chain*
        parallel_chain*
        hook*
        final_chain*
      )
    end
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

    # Set the usual contraints.
    def constraints_usual
      @constraints = []

      # Make sure it's a decent size.
      @constraints << {
        value: "nodes.count",
        conditions: ['>= 30', '<= 53']
      }

      # Make sure all the letters are lowercase.
      @constraints << {
        value: "nodes.select{|k,v| v.letter == v.letter.upcase}.count",
        conditions: '== 0'
      }

      # Make sure there are at least 12 nodes before the miniboss.
      @constraints << {
        value: %{
          nodes.all.select do |n|
            n.zone <= nodes.find_by_letter('bm')[0].zone
          end.count},
        conditions: '>= 12'
      }

      # There should not be too many 'ts' nodes.
      @constraints << {
        value: "nodes.find_by_letter('ts').count",
        conditions: ['>= 1', '<= 2']
      }

      # There should be a range of 'ib' nodes.
      @constraints << {
        value: "nodes.find_by_letter('ib').count",
        conditions: ['>= 4', '<= 7']
      }

      # There should just be 1 of each of these nodes.
      %w(e iq bm bl).each do |i|
        @constraints << {
          value: "nodes.find_by_letter('#{i}').count",
          conditions: '== 1'
        }
      end

      # Debug: Make sure there are some 'l' nodes.
      @constraints << {
        value: "nodes.find_by_letter('l').count",
        conditions: '>= 4'
      }

      # Debug: Make sure there are some 'lm' nodes.
      @constraints << {
        value: "nodes.find_by_letter('lm').count",
        conditions: '>= 0'
      }
    end

    # Assert that the constraints are being followed.
    # Each condition must output to true.
    # We use eval for this. Scary.
    def constraints_assert(nodes)
      @constraints.each do |i|
        [*i[:conditions]].each do |c|
          cond_string = "#{i[:value]} #{c}"
          if not eval(cond_string) == true
            @failed_attempts += 1
            if verbose
              a = "Grammar failure #{@failed_attempts.to_s.rjust(3)}, "
              b = "condition false: (#{cond_string})"
              Zelda::puts_verbose a + b
            end
            return false
          end
        end
      end
      true
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
    def self.output_html

      # Initialise the HTML and file stuff.
      dir_rules = Zelda::Config.dir_rules
      dir_img   = Zelda::Config.dir_rules_images
      rel_img   = Zelda::Config.rel_src_dir_rules_images
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
