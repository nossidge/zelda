#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Singleton to hold config options and default values.
# Used for parsing command line arguments, and directory locations.
################################################################################
# This has kinda broadened its scope since I wrote it.
# It basically contains far more than just config options now.
# I should really separate some of this out into different files.
################################################################################

require 'optparse'

################################################################################

module Zelda
  class Config

    ############################################################################

    # Seed stuff.
    @@seed = Random.rand(9999999)
    def self.seed=(new_seed)
      @@seed = new_seed
    end
    def self.seed
      @@seed
    end
    def self.seed_increment
      @@seed += 1
    end

    ############################################################################

    # The root directory.
    def self.dir_root
      @@dir_root ||= File.expand_path('../../../', __FILE__)
    end

    # Location of the Ruby code.
    def self.dir_lib
      @@dir_lib ||= "#{dir_root}/lib"
    end
    def self.dir_lib_zelda
      @@dir_lib_zelda ||= "#{dir_root}/lib/zelda"
    end

    # Ouput location. This is the public HTML stuff.
    def self.dir_output
      @@dir_output ||= "#{dir_root}/public_html"
    end

    # The location of the base data directory.
    def self.dir_data
      @@dir_data ||= "#{dir_root}/data"
    end

    # The location of the base grammar directory.
    def self.dir_grammar
      @@dir_grammar ||= "#{dir_root}/data/grammar"
    end

    # The location of the grammar rules.
    def self.dir_rules
      @@dir_rules ||= "#{dir_root}/data/grammar/rules"
    end
    def self.rel_src_dir_rules_images
      @@rel_src_dir_rules_images ||= 'img/rules'
    end
    def self.dir_rules_images
      @@dir_rules_images ||= dir_output + '/' + rel_src_dir_rules_images
    end

    # The location of the final .dot and .json files.
    def self.dir_output_data
      @@dir_output_data ||= "#{dir_output}/data"
    end

    # The location of the tilemap .tmx files.
    def self.dir_tilemaps
      @@dir_tilemaps ||= "#{dir_output}/img/tilemaps"
    end

    # File that displays all the grammar rules as diagrams.
    def self.file_grammar_template
      @@file_grammar_template ||= "#{dir_data}/template_grammars.html"
    end
    def self.file_grammar
      @@file_grammar ||= "#{dir_output}/grammar_rules.html"
    end

    # Template for statically generated DungeonMap output HTML file.
    def self.file_map_template
      @@file_map_template ||= "#{dir_data}/template_map.html"
    end

    # The index homepage where you select levels to view.
    def self.file_html_index
      @@file_html_index ||= "#{dir_output}/index.html"
    end

    # The file that lists the filenames of Tiled maps.
    def self.map_files_js
      @@map_files_js ||= "#{dir_output}/lib/map_files.js"
    end

    ############################################################################

    # For a given object, run all methods that match a certain regex.
    # Return an array containing [method_name, result] arrays.
    def self.run_methods(object, regex)
      object = Object.const_get(object) if object.is_a?(String)
      object.methods.select do |i|
        i.to_s =~ regex
      end.map do |i|
        [i.to_s, object.public_send(i).to_s]
      end
    end

    # Print config information.
    def self.print_config_values
      output  = run_methods(Zelda, /^version_*/)
      output += run_methods(Zelda::Config, /^dir_*/)
      output += run_methods(Zelda::Config, /^file_*/)

      # Make sure the columns line up.
      len = output.max_by{ |i| i[0].length }[0].length + 3
      output.each do |i|
        puts i[0].ljust(len) + i[1]
      end
    end

    ############################################################################

    # Delete all files in the data directory.
    def self.delete_data_files
      files = Dir.glob(dir_output_data + '/*')
      files = files.select { |f| File.file?(f) }
      files.each { |f| File.delete(f) }
    end

    ############################################################################

    # Open in default browser, if necessary.
    def self.open_in_default(filepath, force = false)
      if options[:open_html] or force
        require 'os'
        if OS.windows?
          system %{cmd /c "start #{filepath}"}
        elsif OS.mac?
          system %{open "#{filepath}"}
        end
      end
    end

    ############################################################################

    # Output string of JavaScript array assignment.
    def self.format_js_array(variable_name, array, indent = 0)
      indent = '  ' * indent
      output = array.map { |i| indent + "  '#{i}'" }.join(",\n")
      indent + "#{variable_name} = [\n#{output}\n#{indent}]\n"
    end

    # The file that lists the filenames of generated dungeons.
    # This is needed so that JavaScript knows which files to load.
    # Use this also to force clean the file, to ensure that it's valid.
    def self.file_list_js
      @@file_list_js ||= nil
      if @@file_list_js.nil?
        @@file_list_js = "#{dir_output}/lib/file_list.js"
        clean_file_list_js
      end
      @@file_list_js
    end

    # Recreate the file using only the argument files.
    def self.make_file_list_js(file_array = [])
      File.open(file_list_js, 'w') do |f|
        f.write format_js_array('fileList', file_array)
      end
    end

    # Add a new file to 'file_list.js'.
    def self.add_to_file_list_js(new_files = [])
      new_files = *new_files
      if not new_files.empty?
        files = read_file_list_js
        files.push(*new_files)
        make_file_list_js(files)
      end
    end

    # Get the filelist from the JSON, and eval to read into Ruby array.
    def self.read_file_list_js
      json_file_list = File.open(file_list_js, 'r').read
      eval(json_file_list)
    end

    # Ensure that '@@file_list_js' is up to date,
    #   and contains no invalid files.
    def self.clean_file_list_js

      # Iterate through the array, and check if both the needed files exist.
      valid_files = read_file_list_js.select do |f|
        dot  = dir_output_data + '/' + f + '.dot'
        json = dir_output_data + '/' + f + '.json'
        File.file?(dot) and File.file?(json)
      end

      # Recreate the file using only the existing files.
      make_file_list_js(valid_files)
    end

    ############################################################################

    def self.options_default
      @@options = {}
      @@options[:seed]            = Random.rand(9999999)
      @@options[:number]          = 1
      @@options[:one_mission]     = false
      @@options[:static_html]     = false
      @@options[:open_html]       = false
      @@options[:verbose]         = true  # ToDo: Turn this off.
      @@options[:verbose_grammar] = false
    end

    def self.options_exist?
      !@@optparse.getopts.empty?
    end

    def self.options
      @@options
    end

    def self.command
      @@command
    end

    def self.command=(input)
      @@command = input
    end

    def self.command_info(indent = 14)
      {
        'dungeon' => 'Make one or more Zelda dungeon JSON and DOT files',
        'gen4'    => 'Make 4 dungeons, and delete the previously generated files',
        'gen8'    => 'Make 8 dungeons, and delete the previously generated files',
        'delete'  => 'Delete all the previously generated JSON and DOT files',
        'grammar' => 'Generate an HTML file with graphs of all the grammar rules',
        'tilemap' => 'Write all the Tiled map filenames to the JavaScript list',
        'config'  => 'Display various config options',
        'tag'     => "Output the Tiled map tags that are in use\n" +
          ' ' * indent + "Add a second arg and it will output maps using that tag",
        'open'    => "Open the output 'level select' HTML file in default browser\n" +
          ' ' * indent + "Won't work unless your browser accepts xrefs from 'file://'"
      }
    end
    def self.command_info_formatted(indent = 14)
      command_info(indent).map do |k,v|
        '   ' + k.ljust(11) + v
      end
    end
    def self.command_info_to_console(indent = 14)
      command_info_formatted(indent).join("\n")
    end

    # Determine the command for this run of the program.
    def self.main_command(argv)
      command_map = {
        'menu'      => 'menu',
        'd'         => 'dungeon',
        'dungeon'   => 'dungeon',
        'dungeons'  => 'dungeon',
        'gen'       => 'dungeon',
        'gen4'      => 'gen4',
        'gen8'      => 'gen8',
        'delete'    => 'delete',
        'del'       => 'delete',
        'cls'       => 'delete',
        'clear'     => 'delete',
        'clean'     => 'delete',
        'grammar'   => 'grammar',
        'gram'      => 'grammar',
        'g'         => 'grammar',
        'tilemap'   => 'tilemap',
        'tiledmap'  => 'tilemap',
        'tilemaps'  => 'tilemap',
        'tiledmaps' => 'tilemap',
        'tm'        => 'tilemap',
        'map'       => 'tilemap',
        'maps'      => 'tilemap',
        'config'    => 'config',
        'conf'      => 'config',
        'con'       => 'config',
        'tag'       => 'tag',
        'tags'      => 'tag',
        'open'      => 'open',
        'o'         => 'open'
      }

      # If there is a first ARGV to deal with.
      if argv[0]
        @@command = command_map[argv[0]]
        argv.shift if @@command
      end
      @@command ||= command_map['menu']
      argv
    end

    # Parse the console ARGV using the 'optparse'.
    def self.parse_argv(argv)

      # Parse to find the main command.
      # (Shifts it from the front of the array.)
      argv = main_command(argv)

      # Parse the rest of the arguments.
      begin
        optparse.parse!(argv)
      rescue OptionParser::ParseError => e
        puts e
        exit 1
      end

      # Set options.
      Zelda::Config.seed = @@options[:seed]

      # Usually, if no command is specified default to 'menu', but if there
      #   are options specified, then default to 'dungeon'.
      @@command = 'dungeon' if options_exist?

      # Return the argv itself.
      argv
    end

    # Get all of the command-line options.
    def self.optparse
      options_default
      @@optparse ||= OptionParser.new do |opts|

        # Set a banner, displayed at the top of the help screen.
        opts.banner  = "Usage: zelda <command> [options]"
        opts.banner += "\n\n"
        opts.banner += "Available commands:\n"
        opts.banner += command_info_to_console
        opts.banner += "\n\n"
        opts.banner += "Available options:\n"

        # Easy to deal with options.
        opts.on('-n', '--number        NUMBER', Integer, 'Number of dungeons to generate') do |n|
          options[:number] = n if 0 < n
        end
        opts.on('-s', '--seed          NUMBER', Integer, 'Seed to use for the RNG') do |n|
          options[:seed] = n if 0 < n
        end
        opts.on('-m', '--mission', 'Use one mission for all dungeons') do |b|
          options[:one_mission] = b
        end
        opts.on('-S', '--static_html', 'Generate static HTML and PNG files') do |b|
          options[:static_html] = b
        end
        opts.on('-o', '--open_html', 'Open HTML file in default browser') do |b|
          options[:open_html] = b
        end
        opts.on('-v', '--verbose', 'Output will be verbose') do |b|
          options[:verbose] = b
        end
        opts.on('-g', '--grammar',
            "Grammar generation will be verbose\n" + ' '*39 +
            "Warning: This will be very noisy!") do |b|
          options[:verbose] = true
          options[:verbose_grammar] = b
        end

        # Help output.
        opts.on('-h', '--help', 'Display this help screen') do
          puts opts
          exit 0
        end
      end
    end

    ############################################################################

  end
end

################################################################################
