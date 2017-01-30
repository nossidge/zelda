# DONE
* reserved (empty) rooms
* danger value (zones)
* store direction of room entrance
* fix Room#next_neighbour
* move [x,y] arrays to Coords.new(x,y)
* remove Nodes::replace_node_with_sequence
  * it's basically the same as replace_sequence_with_sequence but worse
* read in grammars from DOT file


# TO DO
* use a stack of room combos, and work backwards if dead end found
* replace 't' nodes with 'n'
* remove empty dead end rooms
* more equipment items
* more puzzles
* multi-rooms should match based on count
* dynamically added 'ti' rooms
* more options should be toggleable to differentiate dungeons
* locks should become thresholds
  * combine 'l' and 'lf' nodes into other rooms
* stairways & minecarts
* multi-story dungeons
* side-scrolling basement areas
* palette swap
* create map outline first, and generate mission to match
* full game dungeon generation
  * make 8 dungeons, each one requiring equipment gained in previous
* biomes
