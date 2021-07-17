part of get_youtube_info;

/// Extract string inbetween another.
///
/// @param {string} haystack
/// @param {string} left
/// @param {string} right
/// @returns {string}
String Function(String haystack, dynamic left, dynamic right) between =
    (haystack, left, right) {
  int pos = 0;
  if (left is RegExp) {
    final match = left.firstMatch(haystack);
    if (!nodeIsTruthy(match)) {
      return '';
    }
    pos = match!.start + match.group(0)!.length;
  } else {
    pos = haystack.indexOf(left);
    if (pos == -1) {
      return '';
    }
    pos += (left as String).length;
  }
  haystack = haystack.substring(pos);
  pos = haystack.indexOf(right);
  if (pos == -1) {
    return '';
  }
  haystack = haystack.substring(0, pos);
  return haystack;
};

///TODO: test this funciton!
/// Get a number from an abbreviated number string.
///
/// @param {string} string
/// @returns {number}
num? Function(String string) parseAbbreviatedNumber = (string) {
  final match = RegExp(r"([\d,.]+)([MK]?)")
      .allMatches(string.replaceAll(',', '.').replaceAll(' ', ''));
  if (match.isNotEmpty) {
    var iter = match.iterator;
    iter.moveNext();
    var number = nodeParseDouble(iter.current.group(1))!;

    var multi = iter.current.group(2);
    return (multi == 'M'
            ? number * 1000000
            : multi == 'K'
                ? number * 1000
                : number)
        .round();
  }
  return null;
};

///
/// Match begin and end braces of input JSON, return only json
///
/// @param {string} mixedJson
/// @returns {string}
///
final String Function(String mixedJson) cutAfterJSON = (mixedJson) {
  var open;
  var close;
  if (mixedJson[0] == '[') {
    open = '[';
    close = ']';
  } else if (mixedJson[0] == '{') {
    open = '{';
    close = '}';
  }

  if (!nodeIsTruthy(open)) {
    throw "Can't cut unsupported JSON (need to begin with [ or { ) but got: ${mixedJson[0]}";
  }

  // States if the loop is currently in a string
  var isString = false;

  // States if the current character is treated as escaped or not
  var isEscaped = false;

  // Current open brackets to be closed
  var counter = 0;

  int i;
  for (i = 0; i < mixedJson.length; i++) {
    // Toggle the isString boolean when leaving/entering string
    if (mixedJson[i] == '"' && !isEscaped) {
      isString = !isString;
      continue;
    }

    // Toggle the isEscaped boolean for every backslash
    // Reset for every regular character
    isEscaped = mixedJson[i] == '\\' && !isEscaped;

    if (isString) continue;

    if (mixedJson[i] == open) {
      counter++;
    } else if (mixedJson[i] == close) {
      counter--;
    }

    // All brackets have been closed, thus end of JSON is reached
    if (counter == 0) {
      // Return the cut JSON
      return mixedJson.substring(0, i + 1);
    }
  }

  // We ran through the whole string and ended up with an unclosed bracket
  throw "Can't cut unsupported JSON (no matching closing bracket found)";
};

/// Checks if there is a playability error.
///
/// @param {Object} player_response
/// @param {Array.<string>} statuses
/// @param {Error} ErrorType
/// @returns {!Error}
T? playError<T extends Error>(player_response, statuses, T create(dynamic x)) {
  var playability =
      player_response.isNotEmpty ? player_response['playabilityStatus'] : null;
  if (playability && statuses.contains(playability['status'])) {
    return create(playability['reason'] ?? playability['messages']?.first);
  }
  return null;
}

const Map<String, dynamic> x = {};

/// Does a miniget request and calls options.requestCallback if present
///
/// @param {string} url the request url
/// @param {Object} options an object with optional requestOptions and requestCallback parameters
/// @param {Object} requestOptionsOverwrite overwrite of options.requestOptions
/// @returns {miniget.Stream}
///
Future<http.Response> exposedMiniget(String url,
    {Map options = x, Map requestOptionsOverwrite = x}) async {
  final req = await http
      .get(Uri.parse(url), headers: {...options, ...requestOptionsOverwrite});

  if (options['requestCallback'] is Function) options['requestCallback'](req);
  return req;
}

/// Temporary helper to help deprecating a few properties.
///
/// @param {Object} obj
/// @param {string} prop
/// @param {Object} value
/// @param {string} oldPath
/// @param {string} newPath
void Function(
    Map<String, dynamic> obj,
    String prop,
    dynamic value,
    String oldPath,
    String newPath) deprecate = (obj, prop, value, oldPath, newPath) {
  throw 'Not Implemented!';

  // Object.defineProperty(obj, prop, {
  //   get: ()  {
  //     print('`${oldPath}` will be removed in a near future release use `${newPath}` instead.');
  //     return value;
  //   },
  // });
};

// Check for updates.
// //const pkg = require('../package.json');
// const UPDATE_INTERVAL = 1000 * 60 * 60 * 12;
// exports.lastUpdateCheck = 0;
Function checkForUpdates = () {
  throw 'Not implemented!';

  // if (!process.env.YTDL_NO_UPDATE && !pkg.version.startsWith('0.0.0-') &&
  //   Date.now() - exports.lastUpdateCheck >= UPDATE_INTERVAL) {
  //   exports.lastUpdateCheck = Date.now();
  //   return miniget('https://api.github.com/repos/fent/node-ytdl-core/releases/latest', {
  //     headers: { 'User-Agent': 'ytdl-core' },
  //   }).text().then(response => {
  //     if (JSON.parse(response).tag_name !== `v${pkg.version}`) {
  //       console.warn('\x1b[33mWARNING:\x1B[0m ytdl-core is out of date! Update with "npm install ytdl-core@latest".');
  //     }
  //   }, err => {
  //     console.warn('Error checking for updates:', err.message);
  //     console.warn('You can disable this check by setting the `YTDL_NO_UPDATE` env variable.');
  //   });
  // }
  // return null;
};
