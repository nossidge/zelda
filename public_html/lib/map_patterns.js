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
          }
        }
      }
    ]
  },{
    "name": "key_lock_s_to_n",
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
            "letters": "k",
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
          }
        }
      }
    ]
  },{
    "name": "lock_key_s_to_n",
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
            "exits_quest_item": "ES"
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
            "exits_quest_item": "NEW"
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
          }
        }
      }
    ]
  }
];
