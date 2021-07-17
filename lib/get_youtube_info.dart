library get_youtube_info;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'dart:core';

part 'utils.dart';
part 'url-utils.dart';
part 'cache.dart';
part 'sig.dart';
part 'formats.dart';
part 'format_utils.dart';
part 'info_extras.dart';
part 'info.dart';

bool nodeIsTruthy(dynamic value) =>
    value != 0 && value != '' && value != false && value != null;

int? nodeParseInt(dynamic value) {
  if (!(value is String)) return null;
  var match = RegExp(r'^\d+').firstMatch(value);
  if (match == null) return null;
  return int.parse(match[0]!);
}

double? nodeParseDouble(dynamic value) {
  if (!(value is String)) return null;
  var match = RegExp(r'^\d+(\.\d+)?').firstMatch(value);
  if (match == null) return null;
  return double.parse(match[0]!);
}

dynamic nodeOr(
  dynamic a,
  dynamic b,
) {
  if (nodeIsTruthy(a)) return a;
  return b;
}

String nodeURL(String url, String base_url) {
  if (RegExp(r'(^/|^(?!h?t?t?p)\w|^\d)').hasMatch(url)) {
    if (RegExp(r'^/').hasMatch(url)) return base_url + url.substring(1);
    return base_url + url;
  }
  return url;
}

class QueryString {
  static Map<String, dynamic> parse(String query) {
    var search = new RegExp('([^&=]+)=?([^&]*)');
    var result = new Map<String, dynamic>();

    // Get rid off the beginning ? in query strings.
    if (query.startsWith('?')) query = query.substring(1);

    // A custom decoder.
    decode(String s) => Uri.decodeComponent(s.replaceAll('+', ' '));

    // Go through all the matches and build the result map.
    for (Match match in search.allMatches(query)) {
      result[decode(match.group(1)!)] = decode(match.group(2)!);
    }

    return result;
  }
}

extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}




// const PassThrough = require('stream').PassThrough;
// const getInfo = require('./info');
// const utils = require('./utils');
// const formatUtils = require('./format-utils');
// const urlUtils = require('./url-utils');
// const sig = require('./sig');
// const miniget = require('miniget');
// const m3u8stream = require('m3u8stream');
// const { parseTimestamp } = require('m3u8stream');


// /**
//  * @param {string} link
//  * @param {!Object} options
//  * @returns {ReadableStream}
//  */
// const ytdl = (link, options) => {
//   const stream = createStream(options);
//   ytdl.getInfo(link, options).then(info => {
//     downloadFromInfoCallback(stream, info, options);
//   }, stream.emit.bind(stream, 'error'));
//   return stream;
// };
// module.exports = ytdl;

// ytdl.getBasicInfo = getInfo.getBasicInfo;
// ytdl.getInfo = getInfo.getInfo;
// ytdl.chooseFormat = formatUtils.chooseFormat;
// ytdl.filterFormats = formatUtils.filterFormats;
// ytdl.validateID = urlUtils.validateID;
// ytdl.validateURL = urlUtils.validateURL;
// ytdl.getURLVideoID = urlUtils.getURLVideoID;
// ytdl.getVideoID = urlUtils.getVideoID;
// ytdl.cache = {
//   sig: sig.cache,
//   info: getInfo.cache,
//   watch: getInfo.watchPageCache,
//   cookie: getInfo.cookieCache,
// };
// ytdl.version = require('../package.json').version;


// const createStream = options => {
//   const stream = new PassThrough({
//     highWaterMark: (options && options.highWaterMark) || 1024 * 512,
//   });
//   stream._destroy = () => { stream.destroyed = true; };
//   return stream;
// };


// const pipeAndSetEvents = (req, stream, end) => {
//   // Forward events from the request to the stream.
//   [
//     'abort', 'request', 'response', 'error', 'redirect', 'retry', 'reconnect',
//   ].forEach(event => {
//     req.prependListener(event, stream.emit.bind(stream, event));
//   });
//   req.pipe(stream, { end });
// };


// /**
//  * Chooses a format to download.
//  *
//  * @param {stream.Readable} stream
//  * @param {Object} info
//  * @param {Object} options
//  */
// const downloadFromInfoCallback = (stream, info, options) => {
//   options = options || {};

//   let err = utils.playError(info.player_response, ['UNPLAYABLE', 'LIVE_STREAM_OFFLINE', 'LOGIN_REQUIRED']);
//   if (err) {
//     stream.emit('error', err);
//     return;
//   }

//   if (!info.formats.length) {
//     stream.emit('error', Error('This video is unavailable'));
//     return;
//   }

//   let format;
//   try {
//     format = formatUtils.chooseFormat(info.formats, options);
//   } catch (e) {
//     stream.emit('error', e);
//     return;
//   }
//   stream.emit('info', info, format);
//   if (stream.destroyed) { return; }

//   let contentLength, downloaded = 0;
//   const ondata = chunk => {
//     downloaded += chunk.length;
//     stream.emit('progress', chunk.length, downloaded, contentLength);
//   };

//   // Download the file in chunks, in this case the default is 10MB,
//   // anything over this will cause youtube to throttle the download
//   const dlChunkSize = options.dlChunkSize || 1024 * 1024 * 10;
//   let req;
//   let shouldEnd = true;

//   if (format.isHLS || format.isDashMPD) {
//     req = m3u8stream(format.url, {
//       chunkReadahead: +info.live_chunk_readahead,
//       begin: options.begin || (format.isLive && Date.now()),
//       liveBuffer: options.liveBuffer,
//       requestOptions: options.requestOptions,
//       parser: format.isDashMPD ? 'dash-mpd' : 'm3u8',
//       id: format.itag,
//     });

//     req.on('progress', (segment, totalSegments) => {
//       stream.emit('progress', segment.size, segment.num, totalSegments);
//     });
//     pipeAndSetEvents(req, stream, shouldEnd);
//   } else {
//     const requestOptions = Object.assign({}, options.requestOptions, {
//       maxReconnects: 6,
//       maxRetries: 3,
//       backoff: { inc: 500, max: 10000 },
//     });

//     let shouldBeChunked = dlChunkSize !== 0 && (!format.hasAudio || !format.hasVideo);

//     if (shouldBeChunked) {
//       let start = (options.range && options.range.start) || 0;
//       let end = start + dlChunkSize;
//       const rangeEnd = options.range && options.range.end;

//       contentLength = options.range ?
//         (rangeEnd ? rangeEnd + 1 : parseInt(format.contentLength)) - start :
//         parseInt(format.contentLength);

//       const getNextChunk = () => {
//         if (!rangeEnd && end >= contentLength) end = 0;
//         if (rangeEnd && end > rangeEnd) end = rangeEnd;
//         shouldEnd = !end || end === rangeEnd;

//         requestOptions.headers = Object.assign({}, requestOptions.headers, {
//           Range: `bytes=${start}-${end || ''}`,
//         });

//         req = miniget(format.url, requestOptions);
//         req.on('data', ondata);
//         req.on('end', () => {
//           if (stream.destroyed) { return; }
//           if (end && end !== rangeEnd) {
//             start = end + 1;
//             end += dlChunkSize;
//             getNextChunk();
//           }
//         });
//         pipeAndSetEvents(req, stream, shouldEnd);
//       };
//       getNextChunk();
//     } else {
//       // Audio only and video only formats don't support begin
//       if (options.begin) {
//         format.url += `&begin=${parseTimestamp(options.begin)}`;
//       }
//       if (options.range && (options.range.start || options.range.end)) {
//         requestOptions.headers = Object.assign({}, requestOptions.headers, {
//           Range: `bytes=${options.range.start || '0'}-${options.range.end || ''}`,
//         });
//       }
//       req = miniget(format.url, requestOptions);
//       req.on('response', res => {
//         if (stream.destroyed) { return; }
//         contentLength = contentLength || parseInt(res.headers['content-length']);
//       });
//       req.on('data', ondata);
//       pipeAndSetEvents(req, stream, shouldEnd);
//     }
//   }

//   stream._destroy = () => {
//     stream.destroyed = true;
//     req.destroy();
//     req.end();
//   };
// };


// /**
//  * Can be used to download video after its `info` is gotten through
//  * `ytdl.getInfo()`. In case the user might want to look at the
//  * `info` object before deciding to download.
//  *
//  * @param {Object} info
//  * @param {!Object} options
//  * @returns {ReadableStream}
//  */
// ytdl.downloadFromInfo = (info, options) => {
//   const stream = createStream(options);
//   if (!info.full) {
//     throw Error('Cannot use `ytdl.downloadFromInfo()` when called ' +
//       'with info from `ytdl.getBasicInfo()`');
//   }
//   setImmediate(() => {
//     downloadFromInfoCallback(stream, info, options);
//   });
//   return stream;
// };
