
//##############################################################################
// Create a class that will display a Minimap.
// Needs to be a class, so we can handle having multiple instances.
// These multiple instances will be used on the Level Select HTML page.
// Still in progress. Need to separate out to functions.
//##############################################################################

// Create a Minimap area using PIXI.
function Minimap (objJSON, stage) {
  this.objJSON = objJSON;
  this.stage = stage;
  this.zoom = 2;
  this.minimapBase   = new PIXI.Container();
  this.minimapMap    = new PIXI.Container();
  this.minimapChests = new PIXI.Container();
}

//##############################################################################

// Return a container of sprites.
Minimap.prototype.wordSprites = function(word, wordZoom = this.zoom) {
  var outputSprites = new PIXI.Container();
  var currentX = 0;
  word = String(word);
  word.split('').forEach( function(i) {
    var filename;

    // Figure out the filename of the character's sprite.
    switch(i) {
      case ' ': filename = 'font_space.png'; break;
      case '.': filename = 'font_fullstop.png'; break;
      case ',': filename = 'font_comma.png'; break;
      case '&': filename = 'font_ampersand.png'; break;
      case "'": filename = 'font_apostrophe.png'; break;
      case ':': filename = 'font_colon.png'; break;
      case ';': filename = 'font_semicolon.png'; break;
      case '-': filename = 'font_hyphen.png'; break;
      default:
        var iLower = i.toLowerCase();
        var charCase = (i == iLower) ? 'down' : 'up';
        filename = 'font_letter_' + charCase + '_' + iLower + '.png';
        if (i == parseInt(i)) filename = 'font_' + i + '.png';
    }

    // Add the sprite, and add the width to the position counter.
    var spriteLetter = new PIXI.Sprite(
      PIXI.loader.resources['img/font_minimap.json'].textures[filename]
    );
    spriteLetter.width  = spriteLetter.width  * wordZoom;
    spriteLetter.height = spriteLetter.height * wordZoom;
    spriteLetter.x = currentX;
    currentX += wordZoom + spriteLetter.width;
    outputSprites.addChild(spriteLetter);
  });
  return outputSprites;
};

//##############################################################################

// Draw the dungeon name to 'this.minimapBase'.
Minimap.prototype.drawDungeonName = function(spriteOutline) {

  // 'levelNumber' should default to 1 if not already set.
  var num = 1;
  if (this.objJSON.hasOwnProperty('dungeon_number')) {
    num = this.objJSON.dungeon_number;
  }
  var levelNumber = this.wordSprites(num);
  levelNumber.x = 54 * this.zoom;
  levelNumber.y = 12 * this.zoom;
  this.minimapBase.addChild(levelNumber);

  // 'row1' and 'row2' are Containers for each letter's sprite.
  var row1 = this.wordSprites(this.objJSON.dungeon_name.line_1);
  var row2 = this.wordSprites(this.objJSON.dungeon_name.line_2);
  row1.x = spriteOutline.width / 2;
  row2.x = spriteOutline.width / 2;
  row1.y = 25 * this.zoom;
  row2.y = 36 * this.zoom;

  // Find the accumulated width of each letter sprite for the row.
  function reduceWidth(acc, spr) { return acc + spr._width; }
  var row1Width = row1.children.reduce(reduceWidth, 0);
  var row2Width = row2.children.reduce(reduceWidth, 0);

  // Account for the single pixel spaces inbetween letters.
  row1Width += this.zoom * (row1.children.length - 1);
  row2Width += this.zoom * (row2.children.length - 1);

  // Centre the text within the outline.
  // Make sure it is 'pixel-perfect' with 'this.zoom' as the size of the pixels.
  row1.x -= this.zoom * Math.round(row1Width / (2 * this.zoom));
  row2.x -= this.zoom * Math.round(row2Width / (2 * this.zoom));
  this.minimapBase.addChild(row1);
  this.minimapBase.addChild(row2);
};

//##############################################################################

// Set the position of the minimap, as if it's the only object on the stage.
Minimap.prototype.drawEquipmentInventory = function() {

  // Add a sprite for the contents of the quest chest.
  var spriteItemNew = new PIXI.Sprite(
    PIXI.loader.resources['img/chest_contents.json'].textures[this.objJSON.equipment.new + '.png']
  );
  spriteItemNew.width  = this.zoom * spriteItemNew.width;
  spriteItemNew.height = this.zoom * spriteItemNew.height;
  spriteItemNew.x      = this.zoom * 55;
  spriteItemNew.y      = this.zoom * 145;
  this.minimapBase.addChild(spriteItemNew);

  // Add a sprite for each required item.
  var currentX = originX = 15;
  var currentY = 186;
  for (var i = 0; i < this.objJSON.equipment.required.length; i++) {
    var itemName = this.objJSON.equipment.required[i];
    var spriteItemReq = new PIXI.Sprite(
      PIXI.loader.resources['img/chest_contents.json'].textures[itemName + '.png']
    );
    spriteItemReq.width  = this.zoom * spriteItemReq.width;
    spriteItemReq.height = this.zoom * spriteItemReq.height;
    spriteItemReq.x      = this.zoom * currentX;
    spriteItemReq.y      = this.zoom * currentY;

    this.minimapBase.addChild(spriteItemReq);
    if (currentX >= 65) {
      currentX = originX;
      currentY += 18;
    } else {
      currentX += 10;
    }
  }
};

//##############################################################################

// Loop through each room in the JSON and add to:
//   this.minimapMap
//   this.minimapChests
Minimap.prototype.addEachRoom = function() {
  var spriteDim = 8;
  for (var i = 0; i < this.objJSON.rooms.length; i++) {
    var room = this.objJSON.rooms[i];

    // Add a sprite for each room based on exits.
    var spriteRoom = new PIXI.Sprite(
      PIXI.loader.resources['img/room.json'].textures[room.minimap_room]
    );
    spriteRoom.width  = this.zoom * spriteDim;
    spriteRoom.height = this.zoom * spriteDim;
    spriteRoom.x = this.zoom * (spriteDim * room.x);
    spriteRoom.y = this.zoom * (spriteDim * room.y);

    // Add the sprite to the list to be added after the main map.
    this.minimapMap.addChild(spriteRoom);

    // Add the item sprites.
    if (room.chest || room.letter == 'bl') {
      if (room.chest) spriteName = 'room_chest.png';
      if (room.letter == 'bl') spriteName = 'room_boss.png';
      var spriteItem = new PIXI.Sprite(
        PIXI.loader.resources['img/room.json'].textures[spriteName]
      );
      spriteItem.width  = spriteRoom.width;
      spriteItem.height = spriteRoom.height;
      spriteItem.x      = spriteRoom.x;
      spriteItem.y      = spriteRoom.y;
      this.minimapChests.addChild(spriteItem);
    }
  }
};

//##############################################################################

// Set the position of the minimap, in relation to the big map.
Minimap.prototype.positionBig = function(spriteOutline) {

  // Lots of bloody horrible calcs here, but it does work.
  var mapColumn = 0, mapRow = 1;
  var spriteOutlineX, spriteOutlineY;
  spriteOutlineX  = mapPixelsWidth  / 2 / pixelZoom;
  spriteOutlineY  = mapPixelsHeight / 2 / pixelZoom;
  spriteOutlineX -= spriteOutline.width  / 2;
  spriteOutlineY -= spriteOutline.height / 2;
  spriteOutlineX += mapPixelsWidth  /  pixelZoom * mapColumn;
  spriteOutlineY += mapPixelsHeight / (pixelZoom * 2) * (mapRow * 2);
  this.minimapBase.x = spriteOutlineX;
  this.minimapBase.y = spriteOutlineY;

  // Go through all the existing coords.
  // Find the column where there is space to display the minimap.
  // Minimap takes up 3 rows.
  var columnX = -1;
  for (var x = 0; x <= this.objJSON.max.x; x++) {
    var emptyYs = 0;
    for (var y = this.objJSON.max.y; y >= 0; y--) {
      if (typeof this.objJSON.room_by_coords[[x,y]] == 'undefined') {
        emptyYs += 1
      } else {
        emptyYs = 0;
      }
    }
    if (emptyYs >= 3) {
      columnX = x;
      break;
    }
  }

  // If 'columnX' is still -1, then add an additional space next to the map.
  if (columnX != -1) {
    this.minimapBase.x += (mapPixelsWidth * columnX) / pixelZoom;
  } else {
    columnX = this.objJSON.max.x + 1;
    var adjust = 18 * pixelZoom;

    // Resize the stage width to account for the new minimap.
    resizeStage(
      renderer.width + mapPixelsWidth - adjust,
      renderer.height
    );

    // Adjust the map x slightly to make it fit better.
    this.minimapBase.x += (mapPixelsWidth * columnX) / pixelZoom;
    this.minimapBase.x -= (adjust / 2 / pixelZoom);
  }
};

//##############################################################################

// This is optimised to work at "this.zoom = 2".
// Might be a bit weird at different numbers.
Minimap.prototype.display = function(largeMap = true) {

  // Add the minimap.
  var texture = PIXI.Texture.fromImage('img/minimap_x1.png');
  var spriteOutline = new PIXI.Sprite(texture);
  spriteOutline.width  = spriteOutline.width  * this.zoom;
  spriteOutline.height = spriteOutline.height * this.zoom;
  this.minimapBase.addChild(spriteOutline);

  // Add the dungeon name and items needed.
  this.drawDungeonName(spriteOutline);
  this.drawEquipmentInventory();

  // Loop through each room in the JSON and add to the stage.
  this.addEachRoom(this.objJSON, this.zoom);

  // Add minimap to the parent containers.
  this.minimapMap.addChild(this.minimapChests);
  this.minimapBase.addChild(this.minimapMap);

  // Set the position of the minimap, in relation to the big map.
  if (largeMap) this.positionBig(spriteOutline);

  // Position the map section.
  this.minimapMap.x = (this.minimapBase.width / 2) - (this.minimapMap.width / 2);
  this.minimapMap.y = (96 * this.zoom) - (this.minimapMap.height / 2);

  // Add to the stage.
  this.stage.addChild(this.minimapBase);
};

//##############################################################################
