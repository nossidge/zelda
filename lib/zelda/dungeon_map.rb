#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Map a mission grammar onto a 2d plane to generate a random dungeon layout.
# Transforms a Zelda::Nodes object into a Zelda::Rooms object.
# Also has a method for outputting to an HTML file.
################################################################################

module Zelda

  # Hold information about the first room of a new zone.
  class ZoneInfo

    # 'zone' is the zone number.
    # 'room_orig' is the threshold room from the previous zone.
    # 'room_dest' is the first room of the new zone.
    attr_reader :zone, :room_orig, :room_dest

    def initialize(zone, room_orig, room_dest)
      @zone = zone
      @room_orig = room_orig
      @room_dest = room_dest
    end

    def as_json(options={})
      { zone: @zone,
        room_orig: @room_orig,
        room_dest: @room_dest
      }
    end

    def to_json(*options)
      as_json(*options).to_json(*options)
    end

  end

  ##############################################################################

  class DungeonMap

    attr_reader :rooms              # The main output object.
    attr_reader :nodes              # Mission tree to use.
    attr_reader :failed_attempts    # Number of failed map making attempts.
    attr_reader :origin             # Entrance room co-ords.
    attr_reader :zone_info          # Array of ZoneInfo instances.

    ############################################################################

    def opposite_direction(dir)
      case dir
        when 'N'; 'S'
        when 'S'; 'N'
        when 'E'; 'W'
        when 'W'; 'E'
        else    ; ''
      end
    end

    # Convert a cardinal direction to a coord difference.
    def dir_to_xy_diff(dir)
      output = Coords.new(0, 0)
      case dir
        when 'N'; output.y =  1
        when 'S'; output.y = -1
        when 'E'; output.x =  1
        when 'W'; output.x = -1
      end
      output
    end

    ############################################################################

    def initialize(nodes)
      @nodes = nodes
      @failed_attempts = 0
      @origin = Coords.new(0, 0)
      @zone_info = []
      self.generate
    end

    ############################################################################

    # Keep generating until we get a valid dungeon.
    def generate
      @rooms = nil
      loop do
        @zone_info = []
        @rooms = generate_or_fail(@nodes)
        break if @rooms
        Zelda::Config.seed_increment
      end

      # Handle one-way exits and quest item traversal between zones.
      # 'nodes.zone_traversal' is being read from the start rule's DOT file.
      nodes.zone_traversal.each do |i|
        add_one_way_exits(@rooms, i[0], i[1])
      end

      # Remove walls between non-essential rooms.
      destroy_walls(@rooms, ['n','t'])

      # Find all rooms with letter 'n' that don't lead to useful rooms.
      # Loop until there are no more dead-ends.
      loop do
        break if not destroy_dead_ends(@rooms)
      end

      # Determine 'lock_group's that need special treatment.
      determine_dodgy_lock_groups(@rooms)

      # Pass the '@nodes.quest_item_zone' variable.
      @rooms.quest_item_zone = @nodes.quest_item_zone
    end

    ############################################################################

    # Use the data in Grammar to generate a dungeon mission tree.
    # Return false if it failed for any reason.
    def generate_or_fail(nodes)

      # This will hold information about the room positions.
      rooms = Rooms.new
      rooms.reserved_rooms_bottom_row
      rooms.reserved_rooms_area(7, 8)

      # Array of all nodes that do not have tight coupling parents.
      # Sorted to place nodes with fewer ancestors first.
      nodes_normal = nodes.collect_normal_parents

      # Hash of nodes that do have tightly coupled parents.
      # Key is the parent ID, value is an array of tight children.
      nodes_tight = nodes.tight_parents_to_nodes

      # First, we will loop normally through each of 'nodes_normal'.
      # Once written to the map, if the 'id' field of the node matches
      #   a key in 'nodes_tight', then immediately add those nodes.
      # This is to make sure that we are not adding a node that needs
      #   a certain parent, before the parent is added.
      nodes_normal.each do |node|

        # Break from the whole method if we can't add the node.
        return false if not recurse_add_node(nodes_tight, rooms, nodes, node)
      end

      # Certain rooms have constraints on the number of room entrances allowed.
      # Redo the whole thing if it's not correct.
      # ToDo: This is pretty CPU wasteful.
      if not rooms.exits_valid?
        @failed_attempts += 1
        Zelda::puts_verbose "#{@failed_attempts} not rooms.exits_valid?"
        Zelda::puts_verbose rooms.exits_valid_reasons.map { |i| i.node_id }
        return false
      end

      rooms.recalculate_coords!
    end

    ############################################################################

    # The node may have tightly coupled children, which may in turn have
    #   tightly coupled children, so recurse through them.
    # This is all to make sure they're added before non-tight rooms.
    def recurse_add_node(nodes_tight, rooms, nodes, node)

      # Break from the whole method if we can't add the node.
      return false if not add_individual_node(rooms, nodes, node)

      # Check if the added room has a tightly coupled child.
      nodes_tight[node.id].each do |tight|

        # If the room has not yet been added.
        if rooms.find(tight.id).nil?
          return false if not recurse_add_node(nodes_tight, rooms, nodes, tight)
        end
      end

      # If it didn't fail, return true.
      true
    end

    ############################################################################

    # Add a single node to the 'rooms' instance.
    def add_individual_node(rooms, nodes, node)

      # Does the room need to come after a specific room?
      #   (Does it have a tight coupling?)
      # Assume #tight_coupling array contains just one value.
      is_tight = !nodes.nodes[node.id].tight_coupling.empty?
      if is_tight
        pid = nodes.nodes[node.id].tight_coupling[0].to_i
        parent_room = rooms.find(pid)
        if parent_room.nil?
          p "parent_room.nil?  --  node is: #{node.desc}"
          return false
        end
      end

      # Get the constraints of the letter.
      # It's 'current' because it's the one we're newly adding.
      # ToDo: Something with this...
      letter_current = Alphabet.all[node.letter]

      # Initialise.
      room, room_base, coords, moving, room_valid = nil

      # For the very first room, with 'e' Letter.
      if rooms.rooms.empty?
        raise 'Wrong entrance Letter!' if node.letter != 'e'
        room = rooms.add(@origin.x, @origin.y, node.id, node.letter, node.zone)
        rooms.add_entrance(@origin.x, @origin.y, 'S')

      else

        # Make sure we are not overwriting an existing room.
        loop do

          # Find a previously added room, and add the new room to it.
          room_base = nil

          # If it's a tight red coupling, then this needs to be the parent.
          if is_tight
            room_base = parent_room

          # Make sure we place any locks in an area == the key zone.
          # (This was previously >= the key zone, but created game-breakers)
          # This works because we always place the keys first.
          elsif node.letter == 'l'

            # Search 'nodes' for the right key id.
            key = nodes.all.select do |i|
              met = ( i.metadata[:lock_group_id] == node.metadata[:lock_group_id] )
              let = ( i.letter == 'k' )
              met and let
            end[0]

            # Now search 'rooms' to get the updated zone for the room.
            # Then pick a random room greater than or equal to the code.
            room_base = rooms.random_room_condition do |i|
              i.zone == rooms.find(key.id).zone
            end

          else
            room_base = rooms.random_room
          end

          # Loop through the neighbours to find a suitable room.
          # 4 possible exits, so loop 4 times.
          4.times do |i|

            # Examine the next neighbour cell.
            next_neighbour = room_base.next_neighbour
            moving = next_neighbour[0]
            coords = next_neighbour[1]

            # Break if the room is available.
            room_valid = (
              rooms.room_free?([coords.x, coords.y]) and
              coords.y >= 0 and
              room_base.exits_available?
            )
            break if room_valid
          end

          # If we can't add more to the tight coupled parent room.
          if is_tight and not room_valid
            @failed_attempts += 1
            if 1 == 2
              Zelda::puts_verbose "#{@failed_attempts}: Tight coupling not possible"
            end
            return false
          end

          break if room_valid
        end

        # Add the room to the collection.
        room = rooms.add(coords.x, coords.y, node.id, node.letter, node.zone)

        # Add exits to the room and the origin room.
        rooms.add_entrance(coords.x, coords.y, opposite_direction(moving))
        rooms.add_exit(coords.x, coords.y, opposite_direction(moving))
        rooms.add_exit(room_base.x, room_base.y, moving)

        # Make sure the zone is passed onto the next room, if necessary.
        # This is to make sure that rooms behind locked doors are not
        #   joined to rooms before the lock.
        if room.zone.floor == room_base.zone.floor
          room.zone = room_base.zone
        end

        # If the parent room is a lock, and they're tightly coupled,
        #   then link to this room.
        if is_tight
          if room_base.letter == 'lf'
            room_base.boss_lock_orig += moving
            room.boss_lock_dest += opposite_direction(moving)

          elsif room.letter == 'bm'
            room_base.boss_mini_orig += opposite_direction(moving)
            room.boss_mini_dest += moving

          elsif room_base.letter == 'lm'
            room_base.multi_lock_orig += moving
            room.multi_lock_dest += opposite_direction(moving)
            if room.zone.floor == room_base.zone.floor
              add_zone_fraction(rooms, room, room_base)
            end

          elsif room_base.letter == 'l'
            room_base.lock_orig += moving
            room.lock_dest += opposite_direction(moving)
            if room.zone.floor == room_base.zone.floor
              add_zone_fraction(rooms, room, room_base)
            end

          elsif room_base.letter == 'lp'
            room_base.lock_puzzle_orig += moving
            room.lock_puzzle_dest += opposite_direction(moving)
            if room.zone.floor == room_base.zone.floor
              add_zone_fraction(rooms, room, room_base)
            end

          elsif room_base.letter == 'ts'
            room_base.weak_walls_orig += moving
            room.weak_walls_dest += opposite_direction(moving)

            if room.zone.floor == room_base.zone.floor
              add_zone_fraction(rooms, room, room_base)
            end

            # Test to see if there are any valid neighbours.
            # If there are, then add an 'observatory' exit to it.
            neighbours = room.neighbour_rooms(rooms)
            neighbours.map!    { |n|  [n[0], n[1]] }
            neighbours.reject! { |n|  n[0] == opposite_direction(moving) }

            # Do this for one random neighbour.
            if not neighbours.empty?
              n = neighbours.seed_sample_increment
              room_neighbour = rooms.room(n[1].x, n[1].y)

              # We can safely force an exit here, I think.
              dir = opposite_direction(n[0])
              rooms.add_exit_force(n[1].x, n[1].y, dir)
              room_neighbour.observatory_orig += dir

              # Add observatory to the room.
              dir = n[0]
              room.observatory_dest += dir
              rooms.add_exit(coords.x, coords.y, dir)

              # If we are adding an observatory, then we can hide the origin.
              # This means that the only clue the wall is bombable will be
              #   from the observatory side.
              room_base.weak_walls_hidden += moving
            end

          end
        end
      end

      # Copy metadata from the node to the room.
      room.transfer_node_metadata(node)

      # Return true if it didn't fail up to this point.
      true
    end

    ############################################################################

    # Handle floating point rounding error.
    # This is pretty hacky, and won't work for number bigger than the divisor.
    def round_error(num)
      (num*1000000000).round/1000000000.0
    end

    # Add a fraction to the zone number. Make sure that the number does not
    #   already exist in the map. This is so that we can separate distinct
    #   sub-zones, and we don't merge areas that should be behind two
    #   different locks.
    def add_zone_fraction(rooms, room, room_base)

      # Find the highest zone fraction with the same integer part as the input.
      # The new zone for the 'room' argument will be this number plus a bit.
      base_max = rooms.zones.select do |i|
        i.floor == room.zone.floor
      end.max

      # Hack to make sure it does not get to the next full integer.
      #   With acknowledgments to Zeno of Elea.
      # This should be okay, as we don't care about the actual value, just as
      #   long as it is different from other values in the integer range, and
      #   higher or lower than the preceding and subsequent zones' integer.
      fraction = 0.1
      loop do
        new_zone  = round_error(base_max + fraction)
        next_zone = round_error(room.zone + 1).floor
        break if new_zone < next_zone
        fraction = round_error(fraction / 10.0)
      end
      room.zone = round_error(base_max + fraction)

      # Every time we add a new zone, we should also add the id of the
      #   previous zone room that originated it. Then we can find zones
      #   which are opened by a small key, that only contain a small key.
      # We will then replace the unlocking mechanism from a lock and key,
      #   to a puzzle and solution.
      # ToDo: Do we need this anymore?
      @zone_info << ZoneInfo.new(room.zone, room_base, room)
    end

    ############################################################################

    # Find all rooms with letter 'n'. If any borders another room that
    #   is in the same zone, then remove the walls between them.
    # They have to be the exact same zone, not just same integer.
    def destroy_walls(rooms, letters)
      letters = [*letters]
      rooms.select{ |r| letters.include?(r.letter) }.each do |r|
        r.neighbours.each do |n_arr|
          n = rooms.room(n_arr[1].x, n_arr[1].y)
          if !n.nil? and letters.include?(n.letter) and (r.zone == n.zone)
            rooms.add_exit(r.x, r.y, n_arr[0])
            rooms.add_exit(n.x, n.y, opposite_direction(n_arr[0]))
          end
        end
      end
      rooms
    end

    # Find all rooms with zone 'zone_from'. If any have a wall between another
    #   room with zone 'zone_to', then destroy the wall, and add a one_way_exit
    #   between them.
    def add_one_way_exits(rooms, zone_to, zone_from)
      rooms.select{ |r| r.zone.floor == zone_from }.each do |r|
        r.neighbours.each do |n_arr|
          n = rooms.room(n_arr[1].x, n_arr[1].y)
          if !n.nil? and n.zone.floor == zone_to

            # If there is a wall between them, add one way exits.
            if !r.exits.split('').include? n_arr[0]
              r.add_exit_one_way_orig n_arr[0]
              r.add_exit n_arr[0]
              n.add_exit_one_way_dest opposite_direction(n_arr[0])
              n.add_exit opposite_direction(n_arr[0])

            # If there's no wall, then need to add a quest item barrier.
            # Can add this barrier to either room, so try to add to the
            #   room that is the least busy.
            # ToDo: Find "least busy" room.
            else
              r.add_exit_quest_item n_arr[0]
            end
          end
        end
      end
      rooms
    end

    # Find all rooms with letter 'n' that don't lead to useful rooms.
    # Delete the room, and delete the threshold to neighbours.
    def destroy_dead_ends(rooms)
      rooms_removed = false

      rooms.select{ |r| ['n','t'].include?(r.letter) }.each do |r|
        if r.exits == r.entrance
          rooms_removed = true

          # Find open directions.
          open_dirs = %w(N E S W) - r.walls.chars

          # For each open direction, get the orig room and remove the threshold.
          open_dirs.each do |dir|
            diff = dir_to_xy_diff(dir)
            room_orig = rooms.rooms[ [r.x + diff.x, r.y + diff.y] ]
            room_orig.delete_exit opposite_direction(dir)
          end

          # Kill this useless dead-end room.
          rooms.delete(r)
        end
      end

      # Return bool of successful removal.
      rooms_removed
    end

    ############################################################################

    # Lock groups are designed to be quite flexible in terms of the maps used.
    # But some map types cannot be used for certain lock groups.
    def determine_dodgy_lock_groups(rooms)
      determine_non_small_key_groups(rooms)
      determine_observatory_groups(rooms)
    end

    # Problem: One of the 'km' types that we are using is a room that contains
    #   multiple small-key lock blocks. This could result in sequence breaking
    #   or unfinishable dungeons, when a key designed for a single 'l' room is
    #   used instead in the multi-lock room. This code attempts to solve that.
    def determine_non_small_key_groups(rooms)

      # Find zones locked by 'l' rooms.
      zones_locked = @zone_info.select do |i|
        i.room_orig.letter == 'l'
      end.map do |i|
        i.zone
      end

      # Determine if those zones only contain 'km' key rooms.
      letters_by_zone = Hash.new { |h,k| h[k] = [] }
      rooms.all.sort_by{|r|r.zone}.each do |r|
        if r.letter[0] == 'k'
          letters_by_zone[r.zone] << r.letter
        end
      end
      zones_km = zones_locked.select do |i|
        letters_by_zone[i].uniq == ['km']
      end

      # Get the rooms for those 'km's.
      # Then return the affected 'lock_group's.
      # These are the ones that cannot be small keys.
      non_key_ids = rooms.all.sort_by do |r|
        r.zone
      end.select do |r|
        r.letter == 'km' and zones_km.include?(r.zone)
      end.map do |r|
        r.lock_group[:id]
      end.uniq

      # Find all rooms with the same 'lock_group[:id]'.
      # Add ':observatory' to their 'lock_group' hash.
      non_key_ids.each do |obs_id|
        rooms.all.each do |r|
          if r.lock_group[:id] == obs_id
            r.lock_group[:non_small_key] = true
          end
        end
      end
    end

    # Problem: One of the 'km' types that we are using is a room that contains
    #   a monster in an arena room. These cannot be observatories, so here we
    #   will look for any 'lm' rooms that contain an observatory.
    def determine_observatory_groups(rooms)
      obs_ids = rooms.all.select do |r|
        ['km','lm'].include?(r.letter)
      end.select do |r|
        r.observatory_dest != ''
      end.map do |r|
        r.lock_group[:id]
      end.uniq

      # Find all rooms with the same 'lock_group[:id]'.
      # Add ':observatory' to their 'lock_group' hash.
      obs_ids.each do |obs_id|
        rooms.all.each do |r|
          if r.lock_group[:id] == obs_id
            r.lock_group[:observatory] = true
          end
        end
      end
    end

    ############################################################################

    # Generate an HTML file containing the Rooms data.
    # This is kinda superfluous now that 'mission.html' is
    #   running off vis.js, but let's keep it anyway.
    def generate_html_file(filename)

      # Create the HTML table.
      html = ''
      (@rooms.min.y..@rooms.max.y).each do |y|
        html_row = "  <tr>"
        (@rooms.min.x..@rooms.max.x).each do |x|
          r = @rooms.room(x,y)
          if !r
            row = "\n    <td><br></td>"
          else
            walls   = r.walls.split('')
            oneways = r.exits_one_way_orig.split('')

            klass  = ''
            klass += " zone#{r.zone.floor.to_s.rjust(2,'0')}"
            klass += ' ' + walls.map{|i|"wall#{i}"}.join(' ')
            klass += ' ' + oneways.map{|i|"oneway#{i}"}.join(' ')
            klass += " lock#{r.lock_orig}" if r.lock_orig != ''
            klass += " lock#{r.lock_dest}" if r.lock_dest != ''
            klass += " lock_puzzle#{r.lock_puzzle_orig}" if r.lock_puzzle_orig != ''
            klass += " lock_puzzle#{r.lock_puzzle_dest}" if r.lock_puzzle_dest != ''
            klass += " multilock#{r.multi_lock_orig}" if r.multi_lock_orig != ''
            klass += " multilock#{r.multi_lock_dest}" if r.multi_lock_dest != ''
            klass += " bosslock#{r.boss_lock_orig}" if r.boss_lock_orig != ''
            klass += " bosslock#{r.boss_lock_dest}" if r.boss_lock_dest != ''
            klass += " bossmini#{r.boss_mini_orig}" if r.boss_mini_orig != ''
            klass += " bossmini#{r.boss_mini_dest}" if r.boss_mini_dest != ''
            klass += " weak_wall#{r.weak_walls_orig}" if r.weak_walls_orig != ''
            klass += " weak_wall#{r.weak_walls_dest}" if r.weak_walls_dest != ''
            klass += " observatory#{r.observatory_orig}" if r.observatory_orig != ''
            klass += " observatory#{r.observatory_dest}" if r.observatory_dest != ''
            klass += ' entrance' if r.letter == 'e'
            klass  = klass.strip.split.join(' ')
            klass  = "#{r.letter.ljust(2,' ')} #{klass}"
            text   = "#{r.id} = #{r.letter}<br>#{r.entrance}<br>#{r.zone}"
            row    = "\n    <td class='#{klass}'>#{text}</td>"
          end
          html_row += row
        end
        html_row += "\n  </tr>"
        html = html_row + "\n" + html
      end
      html = "<table>\n#{html}</table>"

      # Save to HTML using the template file.
      File.open("#{filename}.html", 'w') do |fo|
        File.open(Zelda::Config.file_map_template, 'r') do |fi|
          output = fi.read
          output = output.gsub('<!-- @TABLE -->', html)
          output = output.gsub('<!-- @IMAGE -->', "<img src='#{File.basename(filename)}.png'>")
          fo.puts output
        end
      end

      html
    end

  end
end

################################################################################
