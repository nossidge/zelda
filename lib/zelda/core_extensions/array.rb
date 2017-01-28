#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Monkey patch the Array class.
# These methods all relate to pseudorandom sampling.
# This ensures that given the same seed, the same generation will occur.
################################################################################

USE_SEED = true

################################################################################

module Zelda
  module CoreExtensions
    module Array
      def seed_sample
        if USE_SEED
          self.sample(random: Random.new(Zelda::Config.seed))
        else
          self.sample
        end
      end
      def seed_sample_increment
        if USE_SEED
          Zelda::Config.seed_increment
          self.sample(random: Random.new(Zelda::Config.seed))
        else
          self.sample
        end
      end
      def seed_shuffle
        if USE_SEED
          self.shuffle(random: Random.new(Zelda::Config.seed))
        else
          self.shuffle
        end
      end
      def seed_shuffle_increment(seed = Zelda::Config.seed)
        if USE_SEED
          Zelda::Config.seed_increment
          self.shuffle(random: Random.new(seed))
        else
          self.shuffle
        end
      end
    end
  end
end

class Array
  include Zelda::CoreExtensions::Array
end

################################################################################
