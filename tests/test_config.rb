#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Make sure the config directories and files exist.
################################################################################

require 'test/unit'
require './lib/zelda/config.rb'

################################################################################

class TestConfig < Test::Unit::TestCase

  # Run all methods beginning with 'dir_'
  def test_directories
    results = Zelda::Config.run_methods(Zelda::Config, /^dir_*/)
    results.each do |i|
      assert File.directory?(i[1]), "#{i[0]}  =  #{i[1]}"
    end
  end

  # Run all methods beginning with 'file_'
  def test_files
    results = Zelda::Config.run_methods(Zelda::Config, /^file_*/)
    results.each do |i|
      assert File.file?(i[1]), "#{i[0]}  =  #{i[1]}"
    end
  end

end

################################################################################
