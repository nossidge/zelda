#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Test the code itself.
# Make sure there's no trailing spaces or tabs anywhere.
# Might be duplicated by the client git hooks.
################################################################################

require 'test/unit'
require './lib/zelda/config.rb'

################################################################################

class TestMeta < Test::Unit::TestCase

  def files_from_grep(grep_output)
    grep_output.split("\n").map do |i|
      '  ' + i.gsub(Zelda::Config.dir_root,'').split(':').first
    end.sort.uniq.join("\n") + "\n"
  end

  def test_trailing_spaces
    result = `grep -ir ' $' #{Zelda::Config.dir_lib}/*`
    assert(result.empty?, files_from_grep(result))
  end

  def test_tabs
    result = `grep -ir $'\t' #{Zelda::Config.dir_lib}/*`
    assert(result.empty?, files_from_grep(result))
  end

  def test_carriage_return
    result = `grep -irU $'\r' #{Zelda::Config.dir_lib}/*`
    assert(result.empty?, files_from_grep(result))
  end

end

################################################################################
