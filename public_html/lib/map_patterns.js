// Hard coded example of room patterns.
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
          "exits": "ES",
          "walls": "NW"
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
          "entrance": "W",
          "exits": "EW",
          "walls": "NS",
          "lock_orig": "E"
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
        },
        "prop_alter": {
          "chest": false
        },
        "prop_remove": {
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
          "letter": "l",
          "entrance": "S"
        },
        "prop_alter": {
          "chest": true
        },
        "prop_append": {
          "letters": "k"
        }
      }
    ]
  },{
    "name": "test",
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
          "letter": "l"
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
          "entrance": "S"
        }
      }
    ]
  }
];
