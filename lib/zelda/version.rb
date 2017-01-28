#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# The current version number and date.
################################################################################

module Zelda

  def self.version_number
    Gem::Version.new VERSION::STRING
  end

  def self.version_date
    '2017-01-28'
  end

  module VERSION
    MAJOR = 0
    MINOR = 0
    TINY  = 1
    PRE   = 'pre'

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end

end

################################################################################
