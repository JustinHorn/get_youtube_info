part of get_youtube_info;

// const querystring = require('querystring');
// const sax = require('sax');
// const miniget = require('miniget');
// const utils = require('./utils');
// // Forces Node JS version of setTimeout for Electron based applications
// const { setTimeout } = require('timers');
// const formatUtils = require('./format-utils');
// const urlUtils = require('./url-utils');
// const extras = require('./info-extras');
// const sig = require('./sig');
// const Cache = require('./cache');

// Cached for storing basic/full info.

class InfoClass {
  static const BASE_URL = 'https://www.youtube.com/watch?v=';

  static var cache = Cache();
  static var cookieCache = new Cache(timeout: 1000 * 60 * 60 * 24);
  static var watchPageCache = new Cache();
}

// Special error class used to determine if an error is unrecoverable,
// as in, ytdl-core should not try again to fetch the video metadata.
// In this case, the video is usually unavailable in some way.
class UnrecoverableError extends Error {
  final Object? message;

  UnrecoverableError([this.message]);

  String toString() {
    if (message != null) {
      return "UnrecoverableError: ${Error.safeToString(message)}";
    }
    return "UnrecoverableError";
  }
}

// List of URLs that show up in `notice_url` for age restricted videos.
const AGE_RESTRICTED_URLS = [
  'support.google.com/youtube/?p=age_restrictions',
  'youtube.com/t/community_guidelines',
];

///
/// Gets info from a video without getting additional formats.
///
/// @param {string} id
///@param {Object} options
/// @returns {Promise<Object>}
///
getBasicInfo(id, Map<String, dynamic> options) async {
  final Map<String, dynamic> retryOptions = {
    ...options['requestOptions'] ?? {}
  };
  options['requestOptions'] = {...(options['requestOptions'] ?? {}) as Map};
  options['requestOptions']['headers'] = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.101 Safari/537.36',
    ...(options['requestOptions']?['headers'] ?? {})
  };
  final validate = (info) {
    var playErr = playError(
        info['player_response'], ['ERROR'], (d) => UnrecoverableError(d));
    var privateErr = privateVideoError(info['player_response']);
    if (nodeIsTruthy(playErr) || nodeIsTruthy(privateErr)) {
      throw nodeOr(playErr, privateErr);
    }
    return nodeIsTruthy(info?['player_response'])
        ? nodeOr(
            nodeOr(info['player_response']['streamingData'],
                isRental(info['player_response'])),
            isNotYetBroadcasted(info['player_response']))
        : null;
  };
  var info = await pipeline((info, x) => validate(info), retryOptions, [
    () async => await getWatchHTMLPage(id, options),
    () async => await getWatchJSONPage(id, options),
    () async => await getVideoInfoPage(id, options),
  ]);

  info = Map<String, dynamic>.from(info);

  info = {
    ...info,
    'formats': parseFormats(info['player_response']),
    'related_videos': getRelatedVideos(info),
  };

  info = Map<String, dynamic>.from(info);

  // Add additional properties to info.
  final media = getMedia(info);
  final additional = {
    'author': getAuthor(info),
    'media': media,
    'likes': getLikes(info),
    'dislikes': getDislikes(info),
    'age_restricted': nodeIsTruthy(nodeIsTruthy(media) &&
        nodeIsTruthy(media['notice_url']) &&
        AGE_RESTRICTED_URLS.any((url) => media['notice_url'].contains(url))),

    // Give the standard link to the video.
    'video_url': InfoClass.BASE_URL + id,
    'storyboards': getStoryboards(info),
    'chapters': getChapters(info),
  };

  info['videoDetails'] = cleanVideoDetails({
    ...info['player_response']?['microformat']?['playerMicroformatRenderer'],
    ...info['player_response']?['videoDetails'],
    ...additional
  }, info);

  return info;
}

privateVideoError(player_response) {
  var playability = player_response?['playabilityStatus'];
  if (playability?['status'] == 'LOGIN_REQUIRED' &&
      nodeIsTruthy(playability?['messages']
              ?.where((m) => RegExp('This is a private video').hasMatch(m))
              .length >
          0)) {
    return new UnrecoverableError(
        nodeOr(playability['reason'], playability['messages']?.first));
  } else {
    return null;
  }
}

isRental(player_response) {
  var playability = player_response['playabilityStatus'];
  if (playability?['status'] == 'UNPLAYABLE')
    return playability['errorScreen']?['playerLegacyDesktopYpcOfferRenderer'];
}

isNotYetBroadcasted(player_response) {
  var playability = player_response['playabilityStatus'];
  return playability['status'] == 'LIVE_STREAM_OFFLINE';
}

getWatchHTMLURL(id, options) =>
    "${InfoClass.BASE_URL + id}&hl=${nodeOr(options['lang'], 'en')}";
Future<dynamic> getWatchHTMLPageBody(id, options) async {
  final url = getWatchHTMLURL(id, options);
  return await InfoClass.watchPageCache.getOrSet(
      url,
      () async => await exposedMiniget(url, options: options ?? {})
          .then((r) => r.body));
}

const EMBED_URL = 'https://www.youtube.com/embed/';
getEmbedPageBody(id, options) {
  final embedUrl = "${EMBED_URL + id}?hl=${nodeOr(options['lang'], 'en')}";
  return exposedMiniget(embedUrl, options: options).then((r) => r.body);
}

getHTML5player(String body) {
  var html5playerRes = RegExp(
          '<script\\s+src="([^"]+)"(?:\\s+type="text/javascript")?\\s+name="player_ias/base"\\s*>|"jsUrl":"([^"]+)"')
      .firstMatch(body);

  if (!nodeIsTruthy(html5playerRes)) return;

  return nodeOr(html5playerRes![1], html5playerRes[2]);
}

final getIdentityToken = (id, options, key, throwIfNotFound) =>
    InfoClass.cookieCache.getOrSet(key, () async {
      var page = await getWatchHTMLPageBody(id, options);
      var match = RegExp('(["\'])ID_TOKEN\1[:,]\\s?"([^"]+)"').firstMatch(page);
      if (nodeIsTruthy(match) && throwIfNotFound) {
        throw new UnrecoverableError(
            'Cookie header used in request, but unable to find YouTube identity token');
      }
      return match?[2];
    });

/// Goes through each endpoint in the pipeline, retrying on failure if the error is recoverable.
/// If unable to succeed with one endpoint, moves onto the next one.
///
/// @param {Array.<Object>} args
/// @param {Function} validate
/// @param {Object} retryOptions
/// @param {Array.<Function>} endpoints
/// @returns {[Object, Object, Object]}
pipeline(validate, retryOptions, endpoints) async {
  var info;
  for (var func in endpoints) {
    try {
      final newInfo = await retryFunc(func, retryOptions);
      if (nodeIsTruthy(newInfo['player_response'])) {
        newInfo['player_response']['videoDetails'] = assign(
            info?['player_response']?['videoDetails'],
            newInfo['player_response']['videoDetails']);
        newInfo['player_response'] =
            assign(info?['player_response'], newInfo['player_response']);
      }
      info = assign(info, newInfo);
      if (nodeIsTruthy(validate(info, false))) {
        break;
      }
    } catch (err) {
      if (err is UnrecoverableError ||
          func == endpoints[endpoints.length - 1]) {
        throw err;
      }
      //Unable to find video metadata... so try next endpoint.
    }
  }
  return info;
}

/// Like Object.assign(), but ignores `null` and `undefined` from `source`.
///
/// @param {Object} target
/// @param {Object} source
/// @returns {Object}
assign(target, source) {
  if (!(nodeIsTruthy(target) && nodeIsTruthy(source)))
    return nodeOr(target, source);
  for (var x in source.entries) {
    var key = x.key;
    var value = x.value;
    if (value != null && value) {
      target[key] = value;
    }
  }
  return target;
}

/// Given a function, calls it with `args` until it's successful,
/// or until it encounters an unrecoverable error.
/// Currently, any error from miniget is considered unrecoverable. Errors such as
/// too many redirects, invalid URL, status code 404, status code 502.
///
/// @param {Function} func
/// @param {Array.<Object>} args
/// @param {Object} options
/// @param {number} options.maxRetries
/// @param {Object} options.backoff
/// @param {number} options.backoff.inc
retryFunc(func, Map<String, dynamic> options) async {
  var currentTry = 0, result;
  while (currentTry <= options['maxRetries']) {
    try {
      result = await func();
      break;
    } catch (err) {
      if (err is UnrecoverableError ||
          (err is HttpException) ||
          currentTry >= options['maxRetries']) {
        throw err;
      }
      var wait = min<int>((++currentTry * options['backoff']['inc']).toInt(),
          options['backoff']['max']);
      await new Future.delayed(Duration(milliseconds: wait), () => null);
    }
  }
  return result;
}

final jsonClosingChars = RegExp(r"^[)\]}\'\s]+");
handlParseJSON(source, String varName, dynamic json) {
  if (!nodeIsTruthy(json) || json is Map) {
    return json;
  } else {
    try {
      json = json.replaceAll(jsonClosingChars, '');
      return jsonDecode(json);
    } catch (err) {
      throw 'Error parsing $varName in $source: $err';
    }
  }
}

findJSON(source, varName, body, left, right, prependJSON) {
  var jsonStr = between(body, left, right);
  if (!nodeIsTruthy(jsonStr)) {
    throw 'Could not find $varName in $source';
  }
  return handlParseJSON(source, varName, cutAfterJSON('$prependJSON$jsonStr'));
}

findPlayerResponse(source, info) {
  final player_response = nodeOr(
      nodeOr((info['args']?['player_response']), info['player_response']),
      nodeOr(info['playerResponse'], info['embedded_player_response']));
  return handlParseJSON(source, 'player_response', player_response);
}

final getWatchJSONURL =
    (id, options) => '${getWatchHTMLURL(id, options)}&pbj=1';
getWatchJSONPage(id, options) async {
  final Map reqOptions = {'headers': {}, ...options['requestOptions']};

  var cookie =
      nodeOr(reqOptions['headers']['Cookie'], reqOptions['headers']['cookie']);
  print('t0');

  reqOptions['headers'] = {
    'x-youtube-client-name': '1',
    'x-youtube-client-version': '2.20201203.06.00',
    'x-youtube-identity-token':
        InfoClass.cookieCache.get(nodeOr(cookie, 'browser')) ?? '',
    ...reqOptions['headers']
  };
  print('t1');
  final setIdentityToken = (key, throwIfNotFound) async {
    if (nodeIsTruthy(reqOptions['headers']['x-youtube-identity-token'])) {
      return;
    }
    reqOptions['headers']['x-youtube-identity-token'] =
        await getIdentityToken(id, options, key, throwIfNotFound);
  };
  print('t2');

  if (nodeIsTruthy(cookie)) {
    await setIdentityToken(cookie, true);
  }
  print('t3');

  final jsonUrl = getWatchJSONURL(id, options);
  final body = (await exposedMiniget(jsonUrl,
          options: options, requestOptionsOverwrite: reqOptions))
      .body;

  print('t4');

  var parsedBody = handlParseJSON('watch.json', 'body', body);
  if (parsedBody is Map && parsedBody['reload'] == 'now') {
    await setIdentityToken('browser', false);
  }
  print('t5');
  if ((parsedBody is Map && parsedBody['reload'] == 'now') ||
      parsedBody is! List) {
    throw 'Unable to retrieve video metadata in watch.json';
  }
  print('t6');
  var info = List<Map>.from(parsedBody)
      .fold({}, (Map part, Map curr) => ({...curr, ...part}));
  info['player_response'] = findPlayerResponse('watch.json', info);
  info['html5player'] = info['player']?['assets']?['js'];
  print('t7');

  return info;
}

getWatchHTMLPage(id, options) async {
  var body = await getWatchHTMLPageBody(id, options);
  Map<String, dynamic> info = {'page': 'watch'};
  try {
    info['player_response'] = findJSON(
        'watch.html',
        'player_response',
        body,
        RegExp(r'\bytInitialPlayerResponse\s*=\s*\{', multiLine: true),
        '\n',
        '{');
  } catch (err) {
    var args = findJSON('watch.html', 'player_response', body,
        RegExp(r'\bytplayer\.config\s*=\s*{'), '</script>', '{');
    info['player_response'] = findPlayerResponse('watch.html', args);
  }

  info['response'] = findJSON('watch.html', 'response', body,
      RegExp(r'\bytInitialData("\])?\s*=\s*\{', multiLine: true), '\n', '{');

  info['html5player'] = getHTML5player(body);

  return info;
}

const INFO_HOST = 'www.youtube.com';
const INFO_PATH = '/get_video_info';
const VIDEO_EURL = 'https://youtube.googleapis.com/v/';
getVideoInfoPage(id, options) async {
  var url = Uri.parse('https://${INFO_HOST}${INFO_PATH}');

  url = Uri(
      scheme: url.scheme,
      path: url.path,
      queryParameters: {
        ...url.queryParameters,
        'video_id': id,
        'eurl': VIDEO_EURL + id,
        'ps': 'default',
        'gl': 'US',
        'hl': nodeOr(options['lang'], 'en'),
        'html5': '1',
      },
      fragment: url.fragment,
      host: url.host,
      port: url.port);

  final body = (await exposedMiniget(url.toString(), options: options)).body;
  var info = QueryString.parse(body);
  info['player_response'] = findPlayerResponse('get_video_info', info);
  return info;
}

/// @param {Object} player_response
/// @returns {Array.<Object>}
parseFormats(playerResponse) {
  var formats = [];
  if (nodeIsTruthy(playerResponse?['streamingData'])) {
    formats = [
      ...formats,
      ...playerResponse?['streamingData']?['formats'] ?? {},
      ...playerResponse?['streamingData']?['adaptiveFormats'] ?? {}
    ];
  }
  return formats;
}

/// Gets info from a video additional formats and deciphered URLs.
///
/// @param {string} id
/// @param {Object} options
/// @returns {Promise<Object>}
getInfo(id, options) async {
  var info = await getBasicInfo(id, options);
  final hasManifest = nodeOr(
      info['player_response']?['streamingData']?['dashManifestUrl'],
      info['player_response']?['streamingData']?['hlsManifestUrl']);

  List<Future> funcs = [];
  if (info['formats'].length > 0) {
    info['html5player'] = nodeOr(
        nodeOr(info['html5player'],
            getHTML5player(await getWatchHTMLPageBody(id, options))),
        getHTML5player(await getEmbedPageBody(id, options)));
    if (!nodeIsTruthy(info['html5player'])) {
      throw 'Unable to find html5player file';
    }
    final html5player = nodeURL(info['html5player'], InfoClass.BASE_URL);
    funcs.add(decipherFormats(info['formats'], html5player, options));
  }
  if (hasManifest &&
      info['player_response']['streamingData']['dashManifestUrl']) {
    var url = info['player_response']?['streamingData']?['dashManifestUrl'];
    print('no dash manifest');
    // funcs.add(getDashManifest(url, options));
  }
  if (hasManifest &&
      info['player_response']['streamingData']['hlsManifestUrl']) {
    var url = info['player_response']['streamingData']['hlsManifestUrl'];
    funcs.add(getM3U8(url, options));
  }

  var results = await Future.wait(funcs);
  info['formats'] = [...results];
  info['formats'] = info['formats'].map(addFormatMeta);
  info['formats'].sort(sortFormats);
  info['full'] = true;
  return info;
}

// /// Gets additional DASH formats. // cloning sax and xml to much work for now
// ///
// /// @param {string} url
// /// @param {Object} options
// /// @returns {Promise<Array.<Object>>}
// getDashManifest(url, options)  {
//   var formats = {};
//   final parser = sax.parser(false);
//   parser['onerror'] = reject;
//   var adaptationSet;
//   parser['onopentag'] = (node) {
//     if (node.name == 'ADAPTATIONSET') {
//       adaptationSet = node.attributes;
//     } else if (node.name == 'REPRESENTATION') {
//       final itag = parseInt(node.attributes.ID);
//       if (!isNaN(itag)) {
//         formats[url] = Object.assign({
//           itag, url,
//           'bitrate': parseInt(node.attributes.BANDWIDTH),
//           'mimeType': `${adaptationSet.MIMETYPE}; codecs="${node.attributes.CODECS}"`,
//         }, node.attributes.HEIGHT ? {
//           'width': parseInt(node.attributes.WIDTH),
//           'height': parseInt(node.attributes.HEIGHT),
//           'fps': parseInt(node.attributes.FRAMERATE),
//         } : {
//           'audioSampleRate': node.attributes.AUDIOSAMPLINGRATE,
//         });
//       }
//     }
//   };
//   parser.onend = ()() => { resolve(formats); };
//   final req = utils.exposedMiniget(new URL(url, BASE_URL).toString(), options);
//   req.setEncoding('utf8');
//   req.on('error', reject);
//   req.on('data', (chunk) { parser.write(chunk); });
//   req.on('end', parser.close.bind(parser));
// }

/// Gets additional formats.
///
/// @param {string} url
/// @param {Object} options
/// @returns {Promise<Array.<Object>>}
getM3U8(url, options) async {
  url = nodeURL(url, InfoClass.BASE_URL);
  final body = (await exposedMiniget(url.toString(), options: options)).body;
  var formats = {};
  body
      .split('\n')
      .where((line) => RegExp(r"^https?://").hasMatch(line))
      .forEach((line) {
    final itag = nodeParseInt(RegExp(r'/itag/(\d+)/').firstMatch(line)![1]);
    formats[line] = {'itag': itag, 'url': line};
  });
  return formats;
}


// // Cache get info functions.
// // In case a user wants to get a video's info before downloading.
// for (var funcName of ['getBasicInfo', 'getInfo']) {
//   /**
//    * @param {string} link
//    * @param {Object} options
//    * @returns {Promise<Object>}
//    */
//   final func = exports[funcName];
//   exports[funcName] = async(link, options = {})() => {
//     // checkForUpdates();
//     var id = await urlUtils.getVideoID(link);
//     final key = [funcName, id, options.lang].join('-');
//     return Info.cache.getOrSet(key, () => func(id, options));
//   };
// }


