part of get_youtube_info;



// const querystring = require('querystring');


// A shared cache to keep track of html5player.js tokens.


var cache = Cache();


/// Extract signature deciphering tokens from html5player file.
///
/// @param {string} html5playerfile
/// @param {Object} options
/// @returns {Promise<Array.<string>>}
Future<List<String>> Function(String, Map<String,dynamic>) getTokens(html5playerfile, options) => cache.getOrSet(html5playerfile, () async  {
  final body = (await exposedMiniget(html5playerfile, options:options)).body;
  final tokens = extractActions(body);
  if (!tokens || !tokens.length) {
    throw 'Could not extract signature deciphering actions';
  }
  cache.set(html5playerfile, tokens);
  return tokens;
});


/// Decipher a signature based on action tokens.
///
/// @param {Array.<string>} tokens
/// @param {string} sig
/// @returns {string}
exports.decipher = (tokens, sig) => {
  sig = sig.split('');
  for (let i = 0, len = tokens.length; i < len; i++) {
    let token = tokens[i], pos;
    switch (token[0]) {
      case 'r':
        sig = sig.reverse();
        break;
      case 'w':
        pos = ~~token.slice(1);
        sig = swapHeadAndPosition(sig, pos);
        break;
      case 's':
        pos = ~~token.slice(1);
        sig = sig.slice(pos);
        break;
      case 'p':
        pos = ~~token.slice(1);
        sig.splice(0, pos);
        break;
    }
  }
  return sig.join('');
};


/// Swaps the first element of an array with one of given position.
///
/// @param {Array.<Object>} arr
/// @param {number} position
/// @returns {Array.<Object>}
  swapHeadAndPosition(List<dynamic> arr,int position) {
  final first = arr.first;
  arr[0] = arr[(position % arr.length)];
  arr[position] = first;
  return arr;
}


final jsVarStr = r'[a-zA-Z_\$][a-zA-Z_0-9]*';
final jsSingleQuoteStr = r"'[^'\\]*(:?\\[\s\S][^'\\]*)*'";
final jsDoubleQuoteStr = r'"[^"\\]*(:?\\[\s\S][^"\\]*)*"';
final jsQuoteStr = "(?:$jsSingleQuoteStr|$jsDoubleQuoteStr)";
final jsKeyStr = "(?:$jsVarStr|$jsQuoteStr)";
final jsPropStr = '(?:\\.$jsVarStr|\\[$jsQuoteStr\\])';
final jsEmptyStr = '(?:\'\'|"")';
final reverseStr = ':function\\(a\\)\\{' +'(?:return )?a\\.reverse\\(\\)' +'\\}';
final sliceStr = ':function\\(a,b\\)\\{' +
  'return a\\.slice\\(b\\)' +
'\\}';
final spliceStr = ':function\\(a,b\\)\\{' +
  'a\\.splice\\(0,b\\)' +
'\\}';
final swapStr = ':function\\(a,b\\)\\{' +
  'var c=a\\[0\\];a\\[0\\]=a\\[b(?:%a\\.length)?\\];a\\[b(?:%a\\.length)?\\]=c(?:;return a)?' +
'\\}';
final actionsObjRegexp =  RegExp(
  "var ($jsVarStr)=\\{((?:(?:$jsKeyStr$reverseStr|$jsKeyStr$sliceStr|$jsKeyStr$spliceStr|$jsKeyStr$swapStr),?\\r?\\n?)+)\\};");
final actionsFuncRegexp = new RegExp('function(?: $jsVarStr)?\\(a\\)\\{a=a\\.split\\($jsEmptyStr\\);\\s*((?:(?:a=)?$jsVarStr$jsPropStr\\(a,\\d+\\);)+)return a\\.join\\($jsEmptyStr\\)\\}');
final reverseRegexp =  RegExp('(?:^|,)($jsKeyStr)$reverseStr', multiLine: true);
final sliceRegexp = new RegExp('(?:^|,)($jsKeyStr)$sliceStr',  multiLine: true);
final spliceRegexp = new RegExp('(?:^|,)($jsKeyStr)$spliceStr',  multiLine: true);
final swapRegexp = new RegExp('(?:^|,)($jsKeyStr)$swapStr',  multiLine: true);


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
  final objResult = aM_objResult.first;
  final aM_funcResult = actionsFuncRegexp.allMatches(body);
  final funcResult = aM_funcResult.first;
  if (aM_objResult.isEmpty || aM_funcResult.isEmpty) { return null; }

  final obj = aM_objResult.first.group(1)!.replaceAll(r'$', r'\$');
  final objBody = aM_objResult.first.group(2)!.replaceAll(r'$', r'\$');
  final funcBody = aM_funcResult.first.group(1)!.replaceAll(r'$', r'\$');

  final aM_reverseRegexp = reverseRegexp.allMatches(objBody);
  final reverseKey = aM_reverseRegexp.isNotEmpty ? aM_reverseRegexp.first.group(1)!
    .replaceAll(r'$', r'\$')
    .replaceAll('\$|^\'|^"|\'\$|"\$', ''): '';
  var aM_sliceRegexp = sliceRegexp.allMatches(objBody);
  final sliceKey = aM_sliceRegexp.isNotEmpty? aM_sliceRegexp.first.group(1)!
    .replaceAll(r'$', r'\$')
    .replaceAll('\$|^\'|^"|\'\$|"\$', ''):'';

  final spliceKey = aM_sliceRegexp.elementAt(1) != aM_sliceRegexp.first? aM_sliceRegexp.elementAt(1).group(1)! //what if element.at longer than length!?!?!
    .replaceAll(r'$', r'\$')
    .replaceAll('\$|^\'|^"|\'\$|"\$', ''):'';

  final aM_swapRegex = swapRegexp.allMatches(objBody);
  final swapKey =
    aM_swapRegex.isNotEmpty ? aM_swapRegex.first.group(1)!.replaceAll(r'$', r"\$")  .replaceAll('\$|^\'|^"|\'\$|"\$', ''):'';


  final keys = '(${[reverseKey, sliceKey, spliceKey, swapKey].join('|')})';
  final myreg = '(?:a=)?${obj}(?:\\.${keys}|\\['${keys}'\\]|\\["${keys}"\\])\\(a,(\\d+)\\)';
  final tokenizeRegexp =  RegExp(myreg);
  final tokens = <String>[];
  var results = tokenizeRegexp.allMatches(funcBody); 
  var iter = results.iterator;
  while (  iter.moveNext()) {
    var result = iter.current;
    var key = result.group(1) ?? result.group(2) ?? result.group(3);

    if(key == swapKey) {
        tokens.add('w${result[4]}');
    }
   else if(key == reverseKey) {
        tokens.add('r');
    }

   else if(key == sliceKey) {
              tokens.add('s${result[4]}');

    }
   else if(key == spliceKey) {
              tokens.add('p${result[4]}');

    }
 
  }
  return tokens;
}


/// @param {Object} format
/// @param {string} sig
exports.setDownloadURL = (format, sig) => {
  let decodedUrl;
  if (format.url) {
    decodedUrl = format.url;
  } else {
    return;
  }

  try {
    decodedUrl = decodeURIComponent(decodedUrl);
  } catch (err) {
    return;
  }

  // Make some adjustments to the final url.
  const parsedUrl = new URL(decodedUrl);

  // This is needed for a speedier download.
  // See https://github.com/fent/node-ytdl-core/issues/127
  parsedUrl.searchParams.set('ratebypass', 'yes');

  if (sig) {
    // When YouTube provides a `sp` parameter the signature `sig` must go
    // into the parameter it specifies.
    // See https://github.com/fent/node-ytdl-core/issues/417
    parsedUrl.searchParams.set(format.sp || 'signature', sig);
  }

  format.url = parsedUrl.toString();
};


/// Applies `sig.decipher()` to all format URL's.
///
/// @param {Array.<Object>} formats
/// @param {string} html5player
/// @param {Object} options
exports.decipherFormats = async(formats, html5player, options) => {
  let decipheredFormats = {};
  let tokens = await exports.getTokens(html5player, options);
  formats.forEach(format => {
    let cipher = format.signatureCipher || format.cipher;
    if (cipher) {
      Object.assign(format, querystring.parse(cipher));
      delete format.signatureCipher;
      delete format.cipher;
    }
    const sig = tokens && format.s ? exports.decipher(tokens, format.s) : null;
    exports.setDownloadURL(format, sig);
    decipheredFormats[format.url] = format;
  });
  return decipheredFormats;
};
