#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# This is a special Rake task, that generates many dungeon configurations.
# Not included in the default 'test' task, because of how long it takes to run.
# Call it with the number of dungeons to generate in brackets as the argument:
#   rake full[100]
################################################################################

require 'test/unit'
require File.dirname(__FILE__) + '/../lib/zelda.rb'

################################################################################

# Not sure we need 'TestCase' for this, but maybe we will later.
class RakeTaskFull < Test::Unit::TestCase

  # Get the number of iterations from the ENV variable.
  class << self
    def startup
      ENV['gen_count'] ||= '10'
      @@gen_count = ENV.fetch('gen_count').to_i
    end
  end

  # Kick off the other dungeon gen methods.
  def test_main()

    # Pass the gen count to the Config setting module.
    Zelda::Config.options[:number] = @@gen_count

    # Find each type sub-directory in the 'dungeon_settings' dir.
    types = Dir[Zelda::Config.dir_dungeon_settings + '/*/'].map do |d|
      File.basename(d)
    end

    # Make dungeons for each type. Make sure it doesn't take too long.
    types.each do |type|
      puts '########################################'
      puts "Running dungeons for 'dungeon_settings' type: #{type}"
      Zelda.dungeon type
    end
    puts '########################################'
  end

end

################################################################################
