#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Miscellaneous methods and monkey patches.
################################################################################

# Super simple Struct class, just for x and y coordinates.
module Zelda
  class Coords < Struct.new(:x, :y)
  end
end

################################################################################
