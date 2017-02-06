
//##############################################################################
// This module takes the JSON file generated by the Ruby script, and adds extra
//   properties. These are properties that can change with each F5 refresh.
//##############################################################################

// Module to examine and add to the JSON file Rooms collection.
var ModRooms = (function () {

  //############################################################################

  // Convert 'l,k' to ['l','k']
  // 'room.letter' is the original Ruby-generated string.
  // 'room.letters' is the amended array.
  // Currently, this is only amended if the room is part of a layout pattern,
  //   so any regular single rooms will be able to treat it as single element.
  var addLettersArray = function(objJSON) {
    objJSON.rooms.forEach( function(room) {
      room.letters = room.letter.split(',');
    });
    return objJSON;
  };

  //############################################################################

  // The JSON data is from origin bottom-left, so need to subtract
  //   from highest Y to make the map from origin top.
  var calculateTopLeftYCoords = function(objJSON) {
    objJSON.rooms.forEach( function(room) {
      room.y_orig = room.y; // Just in case.
      room.y = objJSON.max.y - room.y;
    });
    return objJSON;
  };

  //############################################################################

  // Get rooms by coord key.
  // Ordered by keys for easier debugging.
  var hashByCoords = function(objJSON) {
    var unsorted = new Object();
    var sorted = new Object();

    // Add in whatever order.
    var keys = [];
    objJSON.rooms.forEach( function(room) {
      var key = room.x + ',' + room.y;
      unsorted[key] = room;
      keys.push(key);
    });

    // Now sort the keys and recreate.
    keys.sort();
    for (i in keys) {
      var key = keys[i];
      var value = unsorted[key];
      sorted[key] = value;
    }

    objJSON.room_by_coords = sorted;
    return objJSON;
  };

  //############################################################################

  // Get rooms by letter key.
  // Ordered by keys for easier debugging.
  var hashByLetters = function(objJSON) {
    var unsorted = new Object();
    var sorted = new Object();

    // Add in whatever order.
    var keys = [];
    objJSON.rooms.forEach( function(room) {
      room.letters.forEach( function(letter) {
        if (typeof unsorted[letter] == 'undefined') {
          unsorted[letter] = [];
        }
        unsorted[letter].push(room);
        keys.push(letter);
      });
    });

    // Now sort the keys and recreate.
    keys.sort();
    for (i in keys) {
      var key = keys[i];
      var value = unsorted[key];
      sorted[key] = value;
    }

    objJSON.room_by_letters = sorted;
    return objJSON;
  };

  //############################################################################

  // Add the name of the dungeon.
  var determineDungeonName = function(objJSON) {
    var prefixes, suffixes;
    prefixes = `snake's unicorn's explorer's angler's catfish's spirit's stone
                eagle's mermaid's hero's mummy's tail desert icy forest shadow
                wing moonlit crown ancient black gnarled swamp spirit woodfall
                skyview moblin goron dodongo maku moon root derelict arrowhead
                skull turtle bottle lakebed forsaken forbidden face snowhead
                misbegotten crumbling`.replace("\n",'');
    prefixes = prefixes.split(' ').filter(function(n){ return n != '' });
    suffixes = `woods cavern grotto tower chasm temple shrine mines ruins palace
                castle cave mire tunnel rock dungeon fortress well path lair den
                grave tomb remains crypt maze pyramid grounds bastion stronghold
                fort`.replace("\n",'');
    suffixes = suffixes.split(' ').filter(function(n){ return n != '' });
    objJSON.dungeon_name = {
      line_1: sample(prefixes).capitalize(),
      line_2: sample(suffixes).capitalize()
    }
    return objJSON;
  };

  //############################################################################

  // What type of multi-lock rooms should we draw?
  // (This will break if there are more than 2 unique multi-key 'lock_groups')
  var determineMultiLocks = function(objJSON) {
    var multiLockTypes = {
      normal: ['monsters','slates','keys'],
      dodgy:  ['monsters','slates']
    }
    shuffle(multiLockTypes.normal);
    shuffle(multiLockTypes.dodgy);

    // Loop through all 'lm' groups. Try to not repeat multiLockTypes.
    objJSON.lock_groups.forEach( function(lock_group) {
      if (lock_group.type == 'lm') {

        // Determine if 'dodgy_lock_groups'
        var isDodgy = false;
        if (typeof objJSON.dodgy_lock_groups != 'undefined') {
          if (objJSON.dodgy_lock_groups.indexOf(lock_group.id) != -1) {
            isDodgy = true;
          }
        }

        // If it's dodgy use the dodgy list. If not then the normal list.
        if (isDodgy) {
          var value = multiLockTypes.dodgy.shift();
          var index = multiLockTypes.normal.indexOf(value);
          if (index != -1) multiLockTypes.normal.splice(index, 1);
        } else {
          var value = multiLockTypes.normal.shift();
          var index = multiLockTypes.dodgy.indexOf(value);
          if (index != -1) multiLockTypes.dodgy.splice(index, 1);
        }
        lock_group.multi_type = value;
      }
    });

    // We'll need to use the 'id's as keys.
    var lookup = {};
    for (var i = 0, len = objJSON.lock_groups.length; i < len; i++) {
      lookup[objJSON.lock_groups[i].id] = objJSON.lock_groups[i];
    }

    // Now, add 'multi_type' each affected room.
    objJSON.rooms.forEach( function(room) {
      if (typeof room.lock_group != 'undefined') {
        if (room.lock_group.type == 'lm') {
          room.lock_group.multi_type = lookup[room.lock_group.id].multi_type;
          if (room.letters.includes('km')) {
            if (room.lock_group.multi_type == 'slates') {
              room.chest = true;
              room.chest_contents = 'slate.png';
            } else if (room.lock_group.multi_type == 'keys') {
              room.chest = true;
              room.chest_contents = 'dungeon_key2.png';
            }
          }
        }
      }
    });

    return objJSON;
  };

  //############################################################################

  // What type of puzzle rooms should we draw?
  var determinePuzzleLocks = function(objJSON) {
    var puzzleIDsAvailable = ModMaps.puzzleIDs.slice();
    var puzzleIDsUsed = [];
    objJSON.room_by_letters['lp'].forEach( function(lpRoom) {

      // Find a random item, and make sure it can't be used again.
      var puzzleID = sample(puzzleIDsAvailable);
      remove(puzzleIDsAvailable, puzzleID);
      puzzleIDsUsed.push(puzzleID);

      // Find the matching 'kp' room.
      var kpRoom = null;
      objJSON.room_by_letters['kp'].forEach( function(posRoom) {
        if (posRoom.lock_group.id == lpRoom.lock_group.id) {
          kpRoom = posRoom;
        }
      });

      // Add to both the key and lock rooms.
      lpRoom.puzzle_id = puzzleID;
      kpRoom.puzzle_id = puzzleID;
    });
    return objJSON;
  };

  //############################################################################

  // Loop through to find all the 'ib' rooms.
  // Make sure that the map and compass are in just one chest each.
  var determineChests = function(objJSON) {

    // Add all 'ib' ids to an object, keyed by zone.
    ibRoomsZone = new Object();
    objJSON.rooms.forEach( function(room) {
      if (room.letters.includes('ib')) {
        if (typeof ibRoomsZone[room.zone] == 'undefined') {
          ibRoomsZone[room.zone] = [];
        }
        ibRoomsZone[room.zone].push(room.id);
      }
    });

    // Shuffle the ids in each zone, and cat them all together.
    // Map and compass should prioritise chests in lower zones.
    ibRooms = [];
    Object.keys(ibRoomsZone).sort().forEach( function(zone) {
      shuffle(ibRoomsZone[zone]);
      ibRooms = ibRooms.concat(ibRoomsZone[zone]);
    });

    // These are the non-quest loot items.
    var normalChestItems = [
      'rupee2.png',
      'rupee3.png',
      'ring.png',
      'gasha_seed.png',
      'seashell.png'
    ];

    // Add the chest contents to the rooms.
    // There may in future be some issues with multi-letter rooms.
    // But for now, there is still only one chest to a room.
    objJSON.rooms.forEach( function(room) {
      if (typeof room.chest == 'undefined') {
        room.chest = findOne(room.letters, ['ib','iq','kf','k','g'])
      }
      if (room.chest) {
        if (room.id == ibRooms[0]) {
          room.chest_contents = 'dungeon_compass.png';
        } else if (room.id == ibRooms[1]) {
          room.chest_contents = 'dungeon_map.png';
        } else if (ibRooms.indexOf(room.id) != -1) {
          room.chest_contents = sample(normalChestItems);
        } else if (room.letters.includes('k')) {
          room.chest_contents = 'dungeon_key2.png';
        } else if (room.letters.includes('kf')) {
          room.chest_contents = 'dungeon_boss_key.png';
        } else if (room.letters.includes('iq')) {
          room.chest_contents = 'roc1.png';
        } else if (room.letters.includes('g')) {
          room.chest_contents =
            'goal_item_' + randBetween(1,3) + '_' + randBetween(1,8) + '.png';
        }
      }
    });

    return objJSON;
  };

  //############################################################################

  // The sprite that shows the room direction.
  var determineMinimapRooms = function(objJSON) {
    objJSON.rooms.forEach( function(room) {

      // Add a sprite for each room based on exits.
      var exits = room.exits + room.entrance;
      exits = dirOrder(exits.toLowerCase());

      // Hide the one-way room links.
      if (typeof room.weak_walls_orig !== 'undefined') {
        room.weak_walls_orig.toLowerCase().split('').forEach( function(i) {
          exits = exits.replace(i, '');
        });
      }
      if (typeof room.exits_one_way_dest !== 'undefined') {
        room.exits_one_way_dest.toLowerCase().split('').forEach( function(i) {
          exits = exits.replace(i, '');
        });
      }

      // Write to the object.
      exits = dirOrder(exits.toLowerCase());
      var spriteName = 'room_' + exits + '.png';
      if (exits == '') spriteName = 'room_noexit.png';
      room.minimap_room = spriteName;
    });

    return objJSON;
  };

  //############################################################################

  // Hard-coded for now. These should become generated later.
  var determineEquipmentInventory = function(objJSON) {
    var reqItems = ['shield1','sword1','bomb1'];
    var maybeItems = ['magic_powder','bracelet3','bow',
                      'boomerang1','flippers','shovel'];
    shuffle(maybeItems);
    for (var i = 0; i < randBetween(0,4); i++) {
      reqItems.push(maybeItems[i]);
    }
    objJSON.equipment = {
      new: 'roc1',
      required: reqItems
    }
    return objJSON;
  };

  //############################################################################

  // Use 'objJSON.equipment' and 'objJSON.quest_item_zone' to figure out
  //   the equipment the player has at each room.
  // This will determine what puzzles can be safely used in the room.
  var determineRoomEquipment = function(objJSON) {
    var itemsStart = objJSON.equipment.required.slice();
    var itemsEnd = itemsStart.slice();
    itemsEnd.push(objJSON.equipment.new);
    objJSON.rooms.forEach( function(room) {
      room.equipment =
        (room.zone > objJSON.quest_item_zone) ? itemsEnd : itemsStart;
    });
    return objJSON;
  };

  //############################################################################

  // Determine which .tmx file we will use for each room.
  var determineTiledRooms = function(objJSON) {
    objJSON.rooms.forEach( function(room) {

      // Which map to use for which room.
      // This is only used for the 'ModMaps.letterToMap' key.
      // 'n' tagged rooms are multi-purpose.
      var mapTagLetter = room.letter;
      var letter = room.letter;
      if ( ['t','ti','ts','k','l','lf','iq'].indexOf(room.letter) != -1 ) {
        letter = 'n';
      } else if ( ['kf'].indexOf(room.letter) != -1 ) {
        letter = 'ib';
      }

      // If the room is a multi-lock with a chest, we can use a 'n' room.
      if (letter == 'km' && room.chest) letter = 'n';

      // Make sure the room has the correct 'fromN', 'fromE', etc. tags.
      var filenameArray = ModMaps.letterToMap[letter].slice();
      shuffle(filenameArray);

      // If there is a map name to prioritise.
      // Push matching maps to the front of the queue.
      // (It is safe to duplicate these map filenames)
      if (mapToPrioritise != null) {
        function containsSubstring(elem) {
          return (elem.search(mapToPrioritise) != -1);
        }
        var filtered = filenameArray.filter(containsSubstring);
        filenameArray = filtered.concat(filenameArray);
      }

      // Shuffle the array of tileMap filenames, and loop until one works.
      var mapFilename = '';
      for (var i = 0; i < filenameArray.length; i++) {
        mapFilename = filenameArray[i];
        var objTileMap = ModMaps.mapTags[mapFilename];

        // This is the exits, minus the entrance.
        var exitOnly = room.exits.replace(room.entrance, '');

        // Use this to get specific dev output with no unwanted noise.
        var logReason = false;
//        logReason = (mapFilename == 'img/tilemaps/roc_001.tmx');
//        logReason = (room.id == 8);

        // Innocent until proven guilty.
        var isValid = true;

        // 'directionBanned' can be inferred from 'fromNESW'.
        if (!objTileMap.tags.hasOwnProperty('directionBanned')) {
          objTileMap.tags.directionBanned = '';
        }
        ['N','E','S','W'].forEach( function(dir) {
          if (objTileMap.tags['from'+dir] == '') {
            objTileMap.tags.directionBanned += dir.toLowerCase();
          }
        });
        objTileMap.tags.directionBanned = dirOrder(objTileMap.tags.directionBanned);

        // If there is no access from a required direction.
        for (var j = 0; j < room.exits.length; j++) {
          if (objTileMap.tags[ 'from'+room.exits[j] ] == '') {
            logif(logReason, '1 room.id = ' + room.id);
            isValid = false;
          }
        }

        // If it needs a chest, but the tilemap doesn't have one.
        if (room.chest) {
          if (!objTileMap.layers.includes('Chest')) {
            logif(logReason, '10 room.id = ' + room.id);
            isValid = false;
          }
        }

        // If it needs an obstacle pit, but the tilemap doesn't have one.
        if (room.hasOwnProperty('exits_quest_item')) {
          for (var j = 0; j < room.exits_quest_item.length; j++) {
            if (!objTileMap.layers.includes('ObstaclePit' + room.exits_quest_item[j])) {
              logif(logReason, '11 room.id = ' + room.id);
              isValid = false;
            }
          }
        }

        // If it needs a specific 'puzzleID', but the tilemap doesn't match.
        if (room.hasOwnProperty('puzzle_id')) {
          if (objTileMap.tags.hasOwnProperty('puzzleID')) {
            if (objTileMap.tags.puzzleID != room.puzzle_id) {
              logif(logReason, '14 room.id = ' + room.id);
              isValid = false;
            }
          } else {
            logif(logReason, '13 room.id = ' + room.id);
            isValid = false;
          }
        }

        // If there is access from a banned direction.
        if (objTileMap.tags.hasOwnProperty('directionBanned')) {
          if (objTileMap.tags['directionBanned'] != '') {

            // For each banned exit, reject if it's present.
            var exitsLower = room.exits.toLowerCase();
            objTileMap.tags['directionBanned'].split('').forEach( function(banned) {
              if (exitsLower.includes(banned)) {
                logif(logReason, '9 room.id = ' + room.id);
                isValid = false;
              }
            });
          }
        }

        // 'directionRequired' means that the room has to have these directions.
        // It may well have more, but it MUST have these.
        // So reject if there is no access from a required direction.
        if (objTileMap.tags.hasOwnProperty('directionRequired')) {
          if (objTileMap.tags['directionRequired'] != '') {
            var arr1 = objTileMap.tags['directionRequired'].split('');
            var arr2 = room.exits.toLowerCase().split('');
            if (!findAll(arr2, arr1)) {
              logif(logReason, '2 room.id = ' + room.id);
              isValid = false;
            }
          }
        }

        // If the exit is required, then enforce it.
        if (objTileMap.tags.hasOwnProperty('exitRequired')) {
          if (objTileMap.tags['exitRequired'] != '') {
            var arr1 = objTileMap.tags['exitRequired'].split('');
            var arr2 = exitOnly.toLowerCase().split('');
            if (!findOne(arr1, arr2)) {
              logif(logReason, '7 room.id = ' + room.id);
              isValid = false;
            }
          }
        }

        // If the entrance is required, then enforce it.
        if (objTileMap.tags.hasOwnProperty('entranceRequired')) {
          if (objTileMap.tags['entranceRequired'] != '') {
            if (objTileMap.tags['entranceRequired'] != room.entrance.toLowerCase()) {
              logif(logReason, '8 room.id = ' + room.id);
              isValid = false;
            }
          }
        }

        // If the room is a multi-room, then make sure we use the correct type.
        if (findOne(room.letters, ['km','lm'])) {
          if (objTileMap.tags.hasOwnProperty('multiRoomType')) {
            if (objTileMap.tags['multiRoomType'] != room.lock_group.multi_type) {
              logif(logReason, '6 room.id = ' + room.id);
              isValid = false;
            }
          }
        }

        // If one or more items are required, make sure we have them in that particular room.
        ['itemRequired','itemRequiredForChest'].forEach( function(propName) {
          if (objTileMap.tags.hasOwnProperty(propName)) {
            if (objTileMap.tags[propName] != '') {
              var arrItemsMap = objTileMap.tags[propName].split(',');
              function inRoomItems(elem) {
                return room.equipment.includes(elem);
              }
              if (!arrItemsMap.every(inRoomItems)) {
                logif(logReason, '12 room.id = ' + room.id);
                isValid = false;
              }
            }
          }
        });

        // If one or more items are banned, make sure we don't have them in that particular room.
        ['itemBanned','itemPrep'].forEach( function(propName) {
          if (objTileMap.tags.hasOwnProperty(propName)) {
            if (objTileMap.tags[propName] != '') {
              var arrItemsMap = objTileMap.tags[propName].split(',');
              function inRoomItems(elem) {
                return room.equipment.includes(elem);
              }
              if (arrItemsMap.some(inRoomItems)) {
                logif(logReason, '15 room.id = ' + room.id);
                isValid = false;
              } else if (propName == 'itemPrep' &&
                        !arrItemsMap.includes(objJSON.equipment.new)) {
                logif(logReason, '16 room.id = ' + room.id);
                isValid = false;
              }
            }
          }
        });

        // If the room needs an observatory, then get a map with an observatory.
        if (room.hasOwnProperty('observatory_dest')) {
          if (!objTileMap.tags.hasOwnProperty('observatory')) {
            logif(logReason, '3 room.id = ' + room.id);
            isValid = false;
          } else {
            if (objTileMap.tags['observatory'] != room.observatory_dest.toLowerCase()) {
              logif(logReason, '4 room.id = ' + room.id);
              isValid = false;
            }
          }

        // If the room does not need one, then don't force one.
        } else {
          if (objTileMap.tags.hasOwnProperty('observatory')) {
            logif(logReason, '5 room.id = ' + room.id);
            isValid = false;
          }
        }

        if (isValid) break;
      }
      if (!isValid) {
        logif(1==1, 'Room not able to be found!');
        logif(1==1, room);
      }

//      console.log('########################################');
//      console.log(objTileMap);

      room.tiled_file = mapFilename;

    });
    return objJSON;
  };

  //############################################################################

  // See if the dungeon contains any multi-room configurations that
  //   match a pre-defined pattern.
  var determinePatterns = function(objJSON) {

    // ID that is used to group rooms in a matched pattern.
    var patternMatchID = 0;

    // Loop through each room and see if it matches a pattern start room.
    getValues(objJSON.room_by_coords).forEach( function(room) {

      // Initialise this room property.
      room.pattern_in_use = false;

      // Loop through each pattern and see if it matches.
      map_patterns.forEach( function(pattern) {

        // If we are only matching a specific pattern.
        if (typeof objJSON.patternToOnlyUse != 'undefined') {
          if (pattern.name != objJSON.patternToOnlyUse) {
            return;
          }
        }

        // Array to store the rooms traversed in the pattern.
        var roomsTraversed = [];

        // For each 'room' in the pattern.
        var isValid = true;
        pattern.rooms.forEach( function(patternRoom) {

          // These are relative to the first room with id = 1.
          var roomX = room.x + patternRoom.relative.x;
          var roomY = room.y + patternRoom.relative.y;
          var traversedRoom = {};
          traversedRoom.room = objJSON.room_by_coords[roomX+','+roomY];

          // Try to match to a pattern start room.
          // If it matches, then add to [roomsTraversed].
          if ( isMatch(traversedRoom.room, patternRoom) ) {
            traversedRoom.patternRoom = patternRoom;
            roomsTraversed.push( traversedRoom );
          } else {
            isValid = false;  // Break out?
          }
        });

        // Hooray! The pattern can be used!
        if (isValid) {
          patternMatchID++;

          // Add to master patterns_possible property.
          if ( !objJSON.hasOwnProperty('patterns_possible') ){
            objJSON.patterns_possible = {};
          }

          // Loop back through the [roomsTraversed] array.
          // Add the pattern to the base room, and the rooms within the pattern.
          roomsTraversed.forEach( function(traversedRoom) {
            if ( !traversedRoom.room.hasOwnProperty('patterns_possible') ){
              traversedRoom.room.patterns_possible = [];
            }
            var patternAndRoom = {};
            patternAndRoom.name = pattern.name;
            patternAndRoom.pattern_match_id = patternMatchID;
            patternAndRoom.room = traversedRoom.patternRoom;
            traversedRoom.room.patterns_possible.push( patternAndRoom );

            // Rooms is the id. The idea is that we can tell if there are
            //   overlaps if one key has multiple values.
            if ( !objJSON.patterns_possible.hasOwnProperty(traversedRoom.room.id) ){
              objJSON.patterns_possible[traversedRoom.room.id] = [];
            }

            // This object is getting pretty messy...
            var finalPush = {};
            finalPush.pattern = pattern;
            finalPush.name = pattern.name;
            finalPush.room = traversedRoom.patternRoom;
            finalPush.id   = traversedRoom.patternRoom.relative.id;
            finalPush.pattern_match_id = patternMatchID;
            objJSON.patterns_possible[traversedRoom.room.id].push( finalPush );
          });
        }
      });
    });
    return objJSON;
  };

  // Does the room match the chosen pattern?
  var isMatch = function(room, patternRoom, verbose = false) {
    if (!room) return false;

    // If the room is an observatory, then it is not valid.
    if (room.hasOwnProperty('observatory_dest')) return false;

    // Loop through each 'patternRoom.absolute' property.
    var isValid = true;
    ['all_of','one_of','none_of'].forEach( function(absoluteType) {
      var absolute = patternRoom.absolute[absoluteType];
      for ( var property in absolute ) {
        if ( absolute.hasOwnProperty(property) ) {

          // Make sure it matches the 'room' property.
          // These are strings of letters, so check if it's in the string.
          if ( room.hasOwnProperty(property) ) {

            // Split to array, if not already.
            var arrAbso = absolute[property].constructor === Array
                        ? absolute[property]
                        : absolute[property].split('');
            var arrRoom = room[property].constructor === Array
                        ? room[property]
                        : room[property].split('');

            // If it's not in the room property, then it's not valid.
            if ( absoluteType == 'one_of' ) {
              if ( !findOne(arrRoom, arrAbso) ) {
                isValid = false;
                logif(verbose, 'isMatch: 1 isValid = false');
              }
            }

            // If it's not ALL in the room property, then it's not valid.
            if ( absoluteType == 'all_of' ) {
              if ( !findAll(arrRoom, arrAbso) ) {
                isValid = false;
                logif(verbose, 'isMatch: 2 isValid = false');
              }
            }

            // If it IS in the room property, then it's not valid.
            if ( absoluteType == 'none_of' ) {
              if ( findOne(arrRoom, arrAbso) ) {
                isValid = false;
                logif(verbose, 'isMatch: 3 isValid = false');
              }
            }

          // If the property is nonexistent but required, then it's not valid.
          } else if ( ['one_of','all_of'].includes(absoluteType) ) {
            isValid = false;
            logif(verbose, 'isMatch: 4 isValid = false');
          }
        }
      }
    });
    return isValid;
  };

  //############################################################################

  // Choose which multi-room patterns will be used.
  // Apply the .tmx file name to the room.
  var resolvePatterns = function(objJSON) {

    // Loop through each key in {patterns_possible} and count values.
    var duplicateRoomIDs = [];
    for (var roomID in objJSON.patterns_possible) {
      if (objJSON.patterns_possible.hasOwnProperty(roomID)) {
        var len = objJSON.patterns_possible[roomID].length;
        if (len > 1) {
          duplicateRoomIDs.push(roomID);
        }
      }
    }

    // If there are no duplicates, then finish the recursion process.
    if (duplicateRoomIDs.length == 0) {

      // Find each room, and alter the 'tiled_file' property.
      for (var roomID in objJSON.patterns_possible) {
        if (objJSON.patterns_possible.hasOwnProperty(roomID)) {
          var room = objJSON.rooms[roomID - 1];
          if (room.patterns_possible.length > 0) {

            // We can use the first element of 'patterns_possible',
            //   now that we have made sure there is only one.
            var pattern = room.patterns_possible[0];
            var name = pattern.name;
            var id   = pattern.room.relative.id;
            room.pattern_in_use = true;
            room.tiled_file = 'img/tilemaps/pattern_' + name + '_' + id + '.tmx';

            // Property change: Alter a property value.
            if (typeof pattern.room.prop_alter != 'undefined') {
              for (var key in pattern.room.prop_alter) {
                if (pattern.room.prop_alter.hasOwnProperty(key)) {
                  room[key] = pattern.room.prop_alter[key];
                }
              }
            }

            // Property change: Remove a property completely.
            if (typeof pattern.room.prop_remove != 'undefined') {
              for (var i = 0; i < pattern.room.prop_remove.length; i++) {
                delete room[pattern.room.prop_remove[i]];
              }
            }

            // Property change: Remove a value from an array.
            // Currently only works with 'room.letters'.
            // It will find a value in a given array, and remove it.
            if (typeof pattern.room.prop_array_remove != 'undefined') {
              for (var key in pattern.room.prop_array_remove) {
                if (pattern.room.prop_array_remove.hasOwnProperty(key)) {
                  var item = pattern.room.prop_array_remove[key];
                  remove(room[key], item);
                }
              }
            }

            // Property change: Append a value to an array.
            // Currently only works with 'room.letters'.
            if (typeof pattern.room.prop_array_append != 'undefined') {
              for (var key in pattern.room.prop_array_append) {
                if (pattern.room.prop_array_append.hasOwnProperty(key)) {
                  var item = pattern.room.prop_array_append[key];
                  room[key].push(item);
                }
              }
            }

          }
        }
      }
      return objJSON;

    // If there are duplicates, then remove a pattern from the available,
    //   and recurse the function.
    // In this way, we will only remove one clashing pattern each function
    //   call, but we should end up with no clashes.
    } else {

      // Select a random clashing room from [duplicateRoomIDs].
      var roomID = sample(duplicateRoomIDs);
      var patternsForTheRoom = objJSON.patterns_possible[roomID];

      // Randomly choose one pattern match to banish.
      shuffle(patternsForTheRoom);
      var patternToBanish = patternsForTheRoom[0].pattern_match_id;

      // Loop through each 'roomID' in 'objJSON.patterns_possible'.
      for (var roomID in objJSON.patterns_possible) {
        if (objJSON.patterns_possible.hasOwnProperty(roomID)) {
          var validPatterns = [];

          // Loop through each pattern in the room's pattern array.
          // If the pattern is NOT banished, then keep it.
          objJSON.patterns_possible[roomID].forEach( function(pattern) {
            if (pattern.pattern_match_id != patternToBanish) {
              validPatterns.push(pattern);
            }
          });

          // Overwrite with the new array.
          objJSON.patterns_possible[roomID] = validPatterns;
          objJSON.rooms[roomID - 1].patterns_possible = validPatterns;
        }
      }

      // Recurse to see if more patterns need resolving.
      objJSON = resolvePatterns(objJSON);
      return objJSON;
    }
  };

  //############################################################################

  // Public methods and variables.
  return {

    // Apply all the transformations.
    transform: function(fileName, objJSON, largeMap = true, usePatterns = true) {

      objJSON.file_name = strip_extension(basename(fileName));
      objJSON = addLettersArray(objJSON);
      objJSON = calculateTopLeftYCoords(objJSON);
      objJSON = hashByCoords(objJSON);
      objJSON = hashByLetters(objJSON);
      if (typeof objJSON.dungeon_name == 'undefined') {
        objJSON = determineDungeonName(objJSON);
      }
      objJSON = determineMultiLocks(objJSON);
      objJSON = determineChests(objJSON);
      objJSON = determineMinimapRooms(objJSON);
      objJSON = determineEquipmentInventory(objJSON);

      // Are we displaying a whole TiledMap dungeon?
      // (Or just a minimap?)
      if (largeMap) {
        objJSON = determineRoomEquipment(objJSON);
        objJSON = determinePuzzleLocks(objJSON);
        if (usePatterns) objJSON = determinePatterns(objJSON);
        objJSON = determineTiledRooms(objJSON);
        if (usePatterns) objJSON = resolvePatterns(objJSON);
      }
      if (usePatterns) objJSON = determineChests(objJSON);

//      console.log('Room transform complete');
//      console.log(objJSON);
      return objJSON;
    }
  };

})();

//##############################################################################
