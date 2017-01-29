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
    "name": "key_lock_e_to_w",
    "rooms": [
      {
        "relative": {
          "id": 1,
          "x": 0,
          "y": 0,
          "zone": 1,
          "lock_group": {
            "id": 1
          }
        },
        "absolute": {
          "letter": "k",
          "entrance": "S",
          "exits": "ES"
        }
      },
      {
        "relative": {
          "id": 2,
          "x": 1,
          "y": 0,
          "zone": 1,
          "lock_group": {
            "id": 1
          }
        },
        "absolute": {
          "letter": "l",
          "entrance": "W"
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
          "zone": 1,
          "lock_group": {
            "id": 1
          }
        },
        "absolute": {
          "letter": "k"
        }
      },
      {
        "relative": {
          "id": 2,
          "x": 0,
          "y": -1,
          "zone": 1,
          "lock_group": {
            "id": 1
          }
        },
        "absolute": {
          "letter": "l",
          "entrance": "S"
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
          "zone": 1,
          "lock_group": {
            "id": 1
          }
        },
        "absolute": {
          "letter": "l",
          "entrance": "E",
          "walls": "SW"
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
      },
      {
        "relative": {
          "id": 2,
          "x": 0,
          "y": -1,
          "zone": 1,
          "lock_group": {
            "id": 1
          }
        },
        "absolute": {
          "letter": "k",
          "entrance": "S",
          "walls": "E"
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
  }
];
