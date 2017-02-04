
//##############################################################################
// Module to catalogue the Tiled map files.
//##############################################################################

var ModMaps = (function () {

  //############################################################################

  // letterToMap is a hash of the map file names, with the letter as the key.
  var catagoriseTilemaps = function() {
    letterToMap = {};

    for (var filename in self.mapTags) {
      if (self.mapTags.hasOwnProperty(filename)) {
        var map = self.mapTags[filename];
        var letters = map.tags.letter.split(',');

        // Add the map to the letter hash.
        // Create new array if not exists, or add if it does.
        letters.forEach( function(letter) {
          if (letterToMap.hasOwnProperty(letter)) {
            letterToMap[letter].push(filename);
          } else {
            letterToMap[letter] = [filename];
          }
        });
      }
    }

    self.letterToMap = letterToMap;
  };

  //############################################################################

  // Open each map, and read the tags and layers.
  // We'll use this to map tilemaps to rooms.
  var catagoriseTilemapTags = function() {
    var mapTags = {};
    var puzzleIDs = [];
    tilemapFilesMaps.forEach( function(fileName) {
      var tilemapInfo = new Object();
      var tileMap = new PIXI.extras.TiledMap(fileName);
      tilemapInfo.filename = fileName;

      // Add the 'properties' as 'tags'
      tilemapInfo.tags = tileMap.properties;

      // Add the 'layer' names as 'layer'
      tilemapInfo.layers = [];
      for (var layer in tileMap.layers) {
        if (tileMap.layers.hasOwnProperty(layer)) {
          tilemapInfo.layers.push(layer);
        }
      }
      mapTags[fileName] = tilemapInfo;

      // If the map has a 'puzzleID' property, add to the array.
      if (tileMap.properties.hasOwnProperty('puzzleID')) {
        puzzleIDs.push(parseInt(tileMap.properties.puzzleID));
      }
    });

    // Add to the module variables.
    self.mapTags = mapTags;
    self.puzzleIDs = Array.from(new Set(puzzleIDs));
  };

  //############################################################################

  // Public methods and variables.
  var self = new Object();

  self.letterToMap = self.letterToMap;
  self.mapTags = self.mapTags;
  self.puzzleIDs = self.puzzleIDs;
  self.catagoriseTilemaps = function() {
    catagoriseTilemapTags();
    catagoriseTilemaps();
  };

  return self;

})();

//##############################################################################
