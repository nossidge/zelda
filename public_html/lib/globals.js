
// A bunch of global functions that I really should organise better.


// Upcase the first character of a string.
String.prototype.capitalize = function() {
  return this.charAt(0).toUpperCase() + this.slice(1);
}

// Get the parameter that was passed through the URL.
function getURLParameter(paramName) {
  var searchString = window.location.search.substring(1),
      i, val, params = searchString.split("&");
  for (i=0;i<params.length;i++) {
    val = params[i].split("=");
    if (val[0] == paramName) return val[1];
  }
  return null;
}

// Get file basename from a path.
function basename(str, sep = '/') {
  return str.substr(str.lastIndexOf(sep) + 1);
}
function strip_extension(str) {
  return str.substr(0,str.lastIndexOf('.'));
}

// Write to console if true.
function logif(condition, msg) {
  if (condition) console.log(msg);
}

function randBetween(min, max) {
  return Math.floor(Math.random()*(max-min+1)+min);
}

function oppositeDirection(dir) {
  var output = '';
  switch(dir) {
    case 'N': output = 'S'; break;
    case 'S': output = 'N'; break;
    case 'E': output = 'W'; break;
    case 'W': output = 'E'; break;
  }
  return output;
}

// Order the directions in a string to 'nesw'.
function dirOrder(dirString) {
  return ['n','e','s','w','N','E','S','W'].filter( function(dir) {
    return dirString.split('').indexOf(dir) != -1;
  }).join('');
}

// http://stackoverflow.com/a/5842695
function getMethods(obj) {
  var res = [];
  for (var m in obj) {
    if (typeof obj[m] == "function") {
      res.push(m)
    }
  }
  return res;
}

// Random from array.
function sample(a) {
  return a[Math.floor(Math.random() * a.length)];
}

// Shuffle an array in place.
function shuffle(a) {
  var j, x, i;
  for (i = a.length; i; i--) {
    j = Math.floor(Math.random() * i);
    x = a[i - 1];
    a[i - 1] = a[j];
    a[j] = x;
  }
}

// Get the values of an object, without the keys.
function getValues(obj) {
  return Object.keys(obj).map( function(key) {
    return obj[key];
  });
}

// http://stackoverflow.com/a/25926600
// @description determine if an array contains one or more items from another array.
// @param {array} haystack the array to search.
// @param {array} needles the array providing items to check for in the haystack.
// @return {boolean} true|false if haystack contains at least one item from needles.
var findOne = function (haystack, needles) {
  return needles.some(function (v) {
    return haystack.indexOf(v) >= 0;
  });
};
var findAll = function (haystack, needles) {
  return needles.every(function (v) {
    return haystack.indexOf(v) >= 0;
  });
};


// Remove all chosen values from array.
// http://stackoverflow.com/a/18165553
function remove(arr, item) {
  for(var i = arr.length; i--;) {
    if(arr[i] === item) {
      arr.splice(i, 1);
    }
  }
}


// Find the element with the smallest 'attrib' value.
// http://stackoverflow.com/a/31844649
Array.prototype.hasMin = function(attrib) {
  return this.reduce( function(prev, curr) {
    return prev[attrib] < curr[attrib] ? prev : curr;
  });
}


// Remove duplicates from an array, preserving order.
// http://stackoverflow.com/a/9229821
function uniqPreserveOrder(a) {
  var seen = {};
  return a.filter(function(item) {
    return seen.hasOwnProperty(item) ? false : (seen[item] = true);
  });
}


// http://stackoverflow.com/a/3820412
function baseName(str) {
  var base = new String(str).substring(str.lastIndexOf('/') + 1);
  if (base.lastIndexOf('.') != -1)
    base = base.substring(0, base.lastIndexOf('.'));
  return base;
}
