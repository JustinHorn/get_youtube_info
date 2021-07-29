part of get_youtube_info;

// A shared cache to keep track of html5player.js tokens.

class Sig {
  static final cache = Cache();
}

/// Extract signature deciphering tokens from html5player file.
///
/// @param {string} html5playerfile
/// @param {Object} options
/// @returns {Promise<Array.<string>>}
Future<List<String>> getTokens(
    String html5playerfile, Map<String, dynamic> options) async {
  return await Sig.cache.getOrSet(html5playerfile, () async {
    final body = (await exposedMiniget(html5playerfile, options: options)).body;
    final tokens = extractActions(body);
    if (tokens == null || tokens.length == 0) {
      throw 'Could not extract signature deciphering actions';
    }
    Sig.cache.set(html5playerfile, tokens);
    return tokens;
  });
}

/// Decipher a signature based on action tokens.
///
/// @param {Array.<string>} tokens
/// @param {string} sig
/// @returns {string}
String decipher(List<String> tokens, String sig) {
  var sigList = sig.split('');
  for (var i = 0, len = tokens.length; i < len; i++) {
    var token = tokens[i];
    int pos;
    switch (token[0]) {
      case 'r':
        sigList = sigList.reversed.toList();
        break;
      case 'w':
        pos = int.parse(token.substring(1));
        sigList = swapHeadAndPosition(sigList, pos).cast<String>();
        break;
      case 's':
        pos = int.parse(token.substring(1));
        sigList = sigList.sublist(pos).cast<String>();
        break;
      case 'p':
        pos = int.parse(token.substring(1));
        sigList = sigList.sublist(pos).cast<String>();
        break;
    }
  }
  return sigList.join('');
}

/// Swaps the first element of an array with one of given position.
///
/// @param {Array.<Object>} arr
/// @param {number} position
/// @returns {Array.<Object>}
List<dynamic> swapHeadAndPosition(List<dynamic> arr, int position) {
  final first = arr.first;
  arr[0] = arr[(position % arr.length)];
  if (position < arr.length) {
    arr[position] = first;
  } else {
    while (position + 1 < arr.length) {
      arr.add(null);
    }
    arr.add(first);
  }
  return arr;
}

final jsVarStr = r"[a-zA-Z_\\$][a-zA-Z_0-9]*";
final jsSingleQuoteStr = "'[^'\\\\]*(:?\\\\[\\s\\S][^'\\\\]*)*'";
final jsDoubleQuoteStr = '"[^"\\\\]*(:?\\\\[\\s\\S][^"\\\\]*)*"';
final jsQuoteStr = "(?:$jsSingleQuoteStr|$jsDoubleQuoteStr)";
final jsKeyStr = "(?:$jsVarStr|$jsQuoteStr)";
final jsPropStr = '(?:\\.$jsVarStr|\\[$jsQuoteStr\\])';
final jsEmptyStr = '(?:\'\'|"")';
final reverseStr =
    ':function\\(a\\)\\{' + '(?:return )?a\\.reverse\\(\\)' + '\\}';
final sliceStr = ':function\\(a,b\\)\\{' + 'return a\\.slice\\(b\\)' + '\\}';
final spliceStr = ':function\\(a,b\\)\\{' + 'a\\.splice\\(0,b\\)' + '\\}';
final swapStr = ":function\\(a,b\\)\\{" +
    "var c=a\\[0\\];a\\[0\\]=a\\[b(?:%a\\.length)?\\];a\\[b(?:%a\\.length)?\\]=c(?:;return a)?" +
    "\\}";
final actionsObjRegexp = RegExp(
    "var ($jsVarStr)=\\{((?:(?:$jsKeyStr$reverseStr|$jsKeyStr$sliceStr|$jsKeyStr$spliceStr|$jsKeyStr$swapStr),?\\r?\\n?)+)\\};");
final actionsFuncRegexp = new RegExp(
    'function(?: $jsVarStr)?\\(a\\)\\{a=a\\.split\\($jsEmptyStr\\);\\s*((?:(?:a=)?$jsVarStr$jsPropStr\\(a,\\d+\\);)+)return a\\.join\\($jsEmptyStr\\)\\}');
final reverseRegexp = RegExp('(?:^|,)($jsKeyStr)$reverseStr', multiLine: true);
final sliceRegexp = new RegExp('(?:^|,)($jsKeyStr)$sliceStr', multiLine: true);
final spliceRegexp =
    new RegExp('(?:^|,)($jsKeyStr)$spliceStr', multiLine: true);
final swapRegexp = new RegExp('(?:^|,)($jsKeyStr)$swapStr', multiLine: true);

/// Extracts the actions that should be taken to decipher a signature.
///
/// This searches for a function that performs string manipulations on
/// the signature. We already know what the 3 possible changes to a signature
/// are in order to decipher it. There is
///
/// * Reversing the string.
/// * Removing a number of characters from the beginning.
/// * Swapping the first character with another position.
///
/// Note, `Array#slice()` used to be used instead of `Array#splice()`,
/// it's kept in case we encounter any older html5player files.
///
/// After retrieving the function that does this, we can see what actions
/// it takes on a signature.
///
/// @param {string} body
/// @returns {Array.<string>}
List<String>? extractActions(String body) {
  final aM_objResult = actionsObjRegexp.allMatches(body);
  final aM_funcResult = actionsFuncRegexp.allMatches(body);
  if (aM_objResult.isEmpty || aM_funcResult.isEmpty) {
    return null;
  }

  final obj = aM_objResult.first.group(1)!.replaceAll(r'$', r'\$');
  final objBody = aM_objResult.first.group(2)!.replaceAll(r'$', r'\$');
  final funcBody = aM_funcResult.first.group(1)!.replaceAll(r'$', r'\$');

  final aM_reverseRegexp = reverseRegexp.allMatches(objBody);
  final reverseKey = aM_reverseRegexp.isNotEmpty
      ? aM_reverseRegexp.first
          .group(1)!
          .replaceAll(r'$', r'\$')
          .replaceAll(RegExp('\$|^\'|^"|\'\$|"\$'), '')
      : '';
  var aM_sliceRegexp = sliceRegexp.allMatches(objBody);
  final sliceKey = aM_sliceRegexp.isNotEmpty
      ? aM_sliceRegexp.first
          .group(1)!
          .replaceAll(r'$', r'\$')
          .replaceAll(RegExp('\$|^\'|^"|\'\$|"\$'), '')
      : '';

  final aM_spliceRegexp = spliceRegexp.allMatches(objBody);
  final spliceKey = aM_spliceRegexp.isNotEmpty
      ? aM_spliceRegexp.first
          .group(1)! //what if element.at longer than length!?!?!
          .replaceAll(r'$', r'\$')
          .replaceAll(RegExp('\$|^\'|^"|\'\$|"\$'), '')
      : '';

  final aM_swapRegex = swapRegexp.allMatches(objBody);
  final swapKey = aM_swapRegex.isNotEmpty
      ? aM_swapRegex.first
          .group(1)!
          .replaceAll(r'$', r"\$")
          .replaceAll(RegExp('\$|^\'|^"|\'\$|"\$'), '')
      : '';

  final keys = '(${[reverseKey, sliceKey, spliceKey, swapKey].join("|")})';
  final myreg =
      '(?:a=)?$obj(?:\\.$keys|\\[\'$keys\'\\]|\\["$keys"\\])\\(a,(\\d+)\\)';
  final tokenizeRegexp = RegExp(myreg);
  final tokens = <String>[];
  var results = tokenizeRegexp.allMatches(funcBody);
  var iter = results.iterator;
  while (iter.moveNext()) {
    var result = iter.current;
    var key = result.group(1) ?? result.group(2) ?? result.group(3);
    if (key == swapKey) {
      tokens.add('w${result.group(4)}');
    } else if (key == reverseKey) {
      tokens.add('r');
    } else if (key == sliceKey) {
      tokens.add('s${result.group(4)}');
    } else if (key == spliceKey) {
      tokens.add('p${result.group(4)}');
    }
  }
  return tokens;
}

/// @param {Object} format
/// @param {string} sig
setDownloadURL(Map<String, dynamic> format, String? sig) {
  var decodedUrl;
  if (format['url'] != null && format['url'] != '') {
    decodedUrl = format['url'];
  } else {
    return;
  }

  try {
    decodedUrl = Uri.decodeComponent(decodedUrl);
  } catch (err) {
    return;
  }

  // Make some adjustments to the final url.
  var parsedUrl = Uri.parse(decodedUrl);

  // This is needed for a speedier download.
  // See https://github.com/fent/node-ytdl-core/issues/127
  final queryParameters = {...parsedUrl.queryParameters};
  queryParameters.addAll({'ratebypass': 'yes'});

  if (nodeIsTruthy(sig)) {
    // When YouTube provides a `sp` parameter the signature `sig` must go
    // into the parameter it specifies.
    // See https://github.com/fent/node-ytdl-core/issues/417
    queryParameters.addAll({(format['sp'] ?? 'signature'): sig!});
  }

  format['url'] =
      Uri.https(parsedUrl.authority, parsedUrl.path, queryParameters)
          .toString();
}

/// Applies `sig.decipher()` to all format URL's.
///
/// @param {Array.<Object>} formats
/// @param {string} html5player
/// @param {Object} options
Future<dynamic> decipherFormats(List<Map<String, dynamic>> formats,
    String html5player, Map<String, dynamic> options) async {
  var decipheredFormats = {};
  var tokens = await (getTokens(html5player, options) as Future<List<String>>);
  formats.forEach((format) {
    var cipher = format['signatureCipher'] ?? format['cipher'];
    if (nodeIsTruthy(cipher)) {
      format.addAll(QueryString.parse(cipher));
      format.remove('signatureCipher');
      format.remove('cipher');
    }
    final sig =
        nodeIsTruthy(format['s']) ? decipher(tokens, format['s']) : null;
    setDownloadURL(format, sig);
    decipheredFormats[format['url']] = format;
  });
  return decipheredFormats;
}
