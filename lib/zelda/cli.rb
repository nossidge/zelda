#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# CLI to the Zelda bin file. Incomplete; should eventually cover all optargs as
#   sequential input gets.
# This is very similar in purpose to the optargs code. Maybe move that here?
################################################################################

require 'highline'

################################################################################

module Zelda
  class CLI

    ############################################################################

    # This is the screen that is presented to the users.
    def self.full_cli(argv)
      @@cli = HighLine.new
      cli_title
      cli_break
      Zelda::Config.command = cli_main_menu
      cli_break
    end

    ############################################################################

    # Position text in the centre of the screen.
    def self.centre_text(input_text, width = 80)
      text = input_text.split("\n")
      return ' ' * width if text.empty?
      indent = ' ' * ( (width / 2) - (text.max_by(&:length).length / 2) )
      text.map{ |i| indent + i }.join("\n")
    end

    ############################################################################

    # UTF-8 code for the triangle symbol.
    def self.triangle
      "\xE2\x96\xB2"
    end

    # Tiny triforce, single character.
    def self.triforce_mini
      output = " #{triangle}\n#{triangle} #{triangle}"
      centre_text(output, 80)
    end

    # Make a pretty triforce!
    # Centre the ascii art within 80 characters.
    def self.triforce
      output = %q{
                   /\
                  /  \
                 /    \
                /      \
               /        \
              /__________\
             /\__________/\
            /  \        /  \
           /    \      /    \
          /      \    /      \
         /        \  /        \
        /__________\/__________\
        \__________/\__________/}.sub("\n",'').split("\n").map do |i|
        i[8..-1]
      end.join("\n")
      centre_text(output, 80)
    end

    ############################################################################

    def self.project_header
      %Q{
        Game Boy Zelda Dungeon Generator
        by Paul Thompson - nossidge@gmail.com
        GitHub - https://github.com/nossidge/zelda
        Homepage - https://tilde.town/~nossidge/zelda
        Version #{Zelda.version_number} - #{Zelda.version_date}
      }.sub("\n",'')
    end

    def self.project_header_centred
      @@project_header_centred ||= project_header.split("\n").map do |i|
        centre_text(i.strip, width = 80)
      end
    end

    ############################################################################

    def self.cli_title
      @@cli.say "<%= color('#{triforce}', :yellow, BOLD) %>\n\n"
      @@cli.say "<%= color('#{project_header_centred[0]}', BOLD) %>"
      @@cli.say project_header_centred[1..-1].join("\n")
    end

    def self.cli_break
      puts "\n#{triforce_mini}\n\n"
    end

    def self.cli_main_menu
      command = ''
      commands = Zelda::Config.command_info_formatted(17)
      @@cli.choose do |menu|
        menu.prompt = "\nPlease choose a command number from the above:  "
        menu.choices(*commands) do |chosen|
          command = chosen.split.first
        end
      end
      command
    end

    ############################################################################

  end
end

################################################################################
