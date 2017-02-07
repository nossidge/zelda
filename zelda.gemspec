# Encoding: UTF-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zelda/version.rb'

Gem::Specification.new do |s|
  s.name          = 'zelda'
  s.version       = Zelda.version_number
  s.date          = Zelda.version_date
  s.license       = 'GPL-3.0'

  s.summary       = %q{Game Boy Zelda Dungeon Generator}
  s.description   = %q{Procedurally generate dungeons as they were found in the three Game Boy Zelda games. Dungeons are logically traversable by the player, and follow the mechanics of the original games, without risk of sequence breaking.}

  s.authors       = ['Paul Thompson']
  s.email         = ['nossidge@gmail.com']
  s.homepage      = 'https://tilde.town/~nossidge/zelda/'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency('highline', '~> 1.7', '>= 1.7.8')
  s.add_runtime_dependency('os',       '~> 0.9', '>= 0.9.6')
  s.add_runtime_dependency('rgl',      '~> 0.5', '>= 0.5.2')
  s.add_runtime_dependency('tmx',      '~> 0.1', '>= 0.1.5')
  s.add_runtime_dependency('andand',   '~> 1.3', '>= 1.3.3')
end
