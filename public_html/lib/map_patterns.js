/*

Tilemap files must be in the format:
"pattern_{pattern_name}_{room_id}.tmx"

# Pattern match
These are used to match a room to a pattern.
  Only two choices: "relative" and "absolute"
  These must match relatively to the origin room (id 1), or absolutely by value.
  If any of the selected properties do not match, the pattern cannot be used.

# Property alterations
These come into play after a pattern has been matched and selected for use.
They alter the properties of the room so patterns can be properly implemented.

  prop_alter: {}
  Alter a property value.
  Example: "chest": false

  prop_remove: []
  These properties will be removed completely from the room.
  Example: "chest_contents"

  prop_array_remove: {}
  Remove a specific value from an array.
  Currently only works with 'room.letters'.
  Example: "letters": "k"

  prop_array_append: {}
  Add a specific value to an array.
  Currently only works with 'room.letters'.
  Example: "letters": "k"

*/

map_patterns = [
  {
    "name": "horizontal_1",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "E"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "W"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "horizontal_2",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "E"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "W"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "horizontal_3",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "E",
            "equipment": ["roc1"]
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "W",
            "equipment": ["roc1"]
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "horizontal_4",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "E",
            "equipment": ["roc1"]
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "W",
            "equipment": ["bomb1"]
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "horizontal_5",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "E"
          },
          "none_of": {
            "observatory_dest": "NESW",
            "exits_quest_item": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "W"
          },
          "none_of": {
            "observatory_dest": "NESW",
            "exits_quest_item": "NESW"
          }
        }
      }
    ]
  },{
    "name": "vert2_keylock1",
    "comment_direction": "South (key) to North (lock)",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "N"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 0,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "all_of": {
            "letters": "l",
            "exits_open": "S"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "vert2_keylock2",
    "comment_direction": "South (key) to North (lock)",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "N"
          },
          "none_of": {
            "observatory_dest": "NESW",
            "exits_quest_item": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 0,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "all_of": {
            "letters": "l",
            "exits_open": "S"
          },
          "none_of": {
            "observatory_dest": "NESW",
            "exits_quest_item": "NESW"
          }
        }
      }
    ]
  },{
    "name": "vert2_lockkey1",
    "comment": "This one NEEDS to be a lock and key combo",
    "comment_direction": "South (lock) to North (key)",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "all_of": {
            "letters": "l",
            "entrance": "E",
            "walls": "SW",
            "lock_orig": "N"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        },
        "prop_remove": [
          "lock_orig"
        ],
        "prop_alter": {
          "chest": true
        },
        "prop_array_append": {
          "letters": "k"
        }
      },{
        "relative": {
          "id": 2,
          "x": 0,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "all_of": {
            "letters": "k",
            "entrance": "S",
            "walls": "E",
            "lock_dest": "S"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        },
        "prop_remove": [
          "lock_dest"
        ],
        "prop_alter": {
          "chest": false
        },
        "prop_array_remove": {
          "letters": "k"
        }
      }
    ]
  },{
    "name": "vertical_1",
    "comment": "http://vgmaps.com/NewsArchives/April2008/LegendOfZelda-OracleOfHours-Vampire'sCrypt.png",
    "comment_direction": "S to N",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t"]
          },
          "all_of": {
            "exits_open": "N",
            "equipment": ["roc1"]
          },
          "none_of": {
            "exits_quest_item": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 0,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "S",
            "equipment": ["roc1"]
          },
          "none_of": {
            "exits_quest_item": "NESW",
            "observatory_dest": "NESW",
            "exits": "W"
          }
        }
      }
    ]
  },{
    "name": "vertical_2",
    "comment": "http://vgmaps.com/Atlas/GB-GBC/LegendOfZelda-OracleOfAges-MoonlitGrotto.png",
    "comment_direction": "N to S",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "S",
            "equipment": ["bomb1"]
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 0,
          "y": 1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["k","kf","ib","iq"]
          },
          "all_of": {
            "entrance": "N",
            "equipment": ["bomb1"]
          },
          "none_of": {
            "exits_quest_item": "NESW",
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "vert2_unconnected1",
    "comment": "http://www.vgmaps.com/NewsArchives/April2008/LegendOfZelda-OracleOfHours-TempleOfLight.png",
    "comment_direction": "Rooms are unconnected",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","l","k","kf","ib","iq"]
          },
          "all_of": {
            "equipment": ["roc1"]
          },
          "none_of": {
            "exits_quest_item": "NESW",
            "observatory_dest": "NESW",
            "exits": "N"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 0,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["k","kf","ib","iq"]
          },
          "all_of": {
            "equipment": ["roc1"]
          },
          "none_of": {
            "exits_quest_item": "NESW",
            "observatory_dest": "NESW",
            "exits": "S"
          }
        }
      }
    ]
  },{
    "name": "sundial_shrine_four",
    "comment": "http://vgmaps.com/NewsArchives/April2008/LegendOfZelda-OracleOfHours-SundialShrine.png",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "NE"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "NW"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 3,
          "x": 1,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "SW"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 4,
          "x": 0,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "ES"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "corner_three_se",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "E"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "NW"
          },
          "none_of": {
            "exits_quest_item": "ES",
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 3,
          "x": 1,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "S"
          },
          "none_of": {
            "exits_quest_item": "NEW",
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "four_upsidedown_t",
    "comment": "http://l.j-factor.com/zeldaclassic/map-sand.png",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "E"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "NEW"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 3,
          "x": 2,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "W"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 4,
          "x": 1,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "S"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "corner_three_ne",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "E"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "SW"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 3,
          "x": 1,
          "y": 1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "N"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      }
    ]
  },{
    "name": "6horiz_darkpalace",
    "comment": "http://www.finalfantasykingdom.net/z3/darkpalace.png ~ first room is bottom left",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "NE"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "NEW"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 3,
          "x": 2,
          "y": 0,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "NW"
          },
          "none_of": {
            "observatory_dest": "NESW"
          }
        }
      },{
        "relative": {
          "id": 4,
          "x": 0,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "S"
          },
          "none_of": {
            "observatory_dest": "NESW",
            "exits": "W"
          }
        }
      },{
        "relative": {
          "id": 5,
          "x": 1,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "N"
          },
          "none_of": {
            "observatory_dest": "NESW",
            "exits": "ESW"
          }
        }
      },{
        "relative": {
          "id": 6,
          "x": 2,
          "y": -1,
          "zone": 1
        },
        "absolute": {
          "one_of": {
            "letters": ["n","t","k","l","kf","ib","iq"]
          },
          "all_of": {
            "exits_open": "S"
          },
          "none_of": {
            "observatory_dest": "NESW",
            "exits": "E"
          }
        }
      }
    ]
  }
];
