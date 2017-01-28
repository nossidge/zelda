#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Monkey patch the String class.
################################################################################

module Zelda
  module CoreExtensions
    module String
      def upcase?
        self == self.upcase
      end
    end
  end
end

################################################################################

class String
  include Zelda::CoreExtensions::String
end

################################################################################
