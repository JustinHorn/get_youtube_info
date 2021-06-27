part of get_youtube_info;

// Use these to help sort formats, higher index is better.
const audioEncodingRanks = [
  'mp4a',
  'mp3',
  'vorbis',
  'aac',
  'opus',
  'flac',
];
const videoEncodingRanks = [
  'mp4v',
  'avc1',
  'Sorenson H.283',
  'MPEG-4 Visual',
  'VP8',
  'VP9',
  'H.264',
];

int getVideoBitrate(Map<String, dynamic> format) => format['bitrate'] ?? 0;
int getVideoEncodingRank(format) => videoEncodingRanks.indexWhere(
    (enc) => format['codecs'] != null && format['codecs'].contains(enc));
int getAudioBitrate(Map<String, dynamic> format) => format['audioBitrate'] ?? 0;
int getAudioEncodingRank(format) => audioEncodingRanks.indexWhere(
    (enc) => format['codecs'] != null && format['codecs'].contains(enc));

/// Sort formats by a list of functions.
///
/// @param {Object} a
/// @param {Object} b
/// @param {Array.<Function>} sortBy
/// @returns {number}
sortFormatsBy(a, b, sortBy) {
  var res = 0;
  for (var fn in sortBy) {
    res = fn(b) - fn(a);
    if (res != 0) {
      break;
    }
  }
  return res;
}

int sortFormatsByVideo(a, b) => sortFormatsBy(a, b, [
      (format) => nodeParseInt(format['qualityLabel']) ?? 0,
      getVideoBitrate,
      getVideoEncodingRank,
    ]);

int sortFormatsByAudio(a, b) => sortFormatsBy(a, b, [
      getAudioBitrate,
      getAudioEncodingRank,
    ]);

/// Sort formats from highest quality to lowest.
///
/// @param {Object} a
/// @param {Object} b
/// @returns {number}
int sortFormats(Map<String, dynamic> a, Map<String, dynamic> b) =>
    sortFormatsBy(a, b, [
      // Formats with both video and audio are ranked highest.
      (format) => format['isHLS'] == true ? 1 : 0,
      (format) => format['isDashMPD'] == true ? 1 : 0,
      (format) => (format['contentLength'] ?? -1) > 0 ? 1 : 0,
      (format) =>
          (format['hasVideo'] == true && format['hasAudio'] == true) ? 1 : 0,
      (format) => format['hasVideo'] == true ? 1 : 0,
      (format) => nodeParseInt(format['qualityLabel']) ?? 0,
      getVideoBitrate,
      getAudioBitrate,
      getVideoEncodingRank,
      getAudioEncodingRank,
    ]);

/// Choose a format depending on the given options.
///
/// @param {Array.<Object>} formats
/// @param {Object} options
/// @returns {Object}
/// @throws {Error} when no format matches the filter/format rules
chooseFormat(List<Map<String, dynamic>> formats, options) {
  if (options['format'] is Map) {
    if (!nodeIsTruthy(options['format']['url'])) {
      throw 'Invalid format given, did you use `ytdl.getInfo()`?';
    }
    return options['format'];
  }

  if (nodeIsTruthy(options['filter'])) {
    formats = filterFormats(formats, options['filter']);
  }

  // We currently only support HLS-Formats for livestreams
  // So we (now) remove all non-HLS streams
  if (formats.any((fmt) => fmt['isHLS'] != null)) {
    formats = formats
        .where((fmt) => fmt['isHLS'] == true || fmt['isLive'] == false)
        .toList();
  }

  var format;
  final quality = options['quality'] ?? 'highest';

  if (formats.length == 0) throw 'No such format found: $quality';

  switch (quality) {
    case 'highest':
      format = formats[0];
      break;

    case 'lowest':
      format = formats[formats.length - 1];
      break;

    case 'highestaudio':
      {
        formats = filterFormats(formats, 'audio');
        formats.sort(sortFormatsByAudio);
        // Filter for only the best audio format
        final bestAudioFormat = formats[0];
        formats = formats
            .where((f) => sortFormatsByAudio(bestAudioFormat, f) == 0)
            .toList();
        // Check for the worst video quality for the best audio quality and pick according
        // This does not loose default sorting of video encoding and bitrate

        final formatListCopy = [
          ...formats.map((f) => nodeParseInt(f['qualityLabel']) ?? 0).toList()
        ];
        formatListCopy.sort((a, b) => a - b);
        final worstVideoQuality = formatListCopy[0];
        format = formats.firstWhere(
            (f) => (nodeParseInt(f['qualityLabel']) ?? 0) == worstVideoQuality);
        break;
      }

    case 'lowestaudio':
      formats = filterFormats(formats, 'audio');
      formats.sort(sortFormatsByAudio);
      format = formats[formats.length - 1];
      break;

    case 'highestvideo':
      {
        formats = filterFormats(formats, 'video');
        formats.sort(sortFormatsByVideo);
        // Filter for only the best video format
        final bestVideoFormat = formats[0];
        formats = formats
            .where((f) => sortFormatsByVideo(bestVideoFormat, f) == 0)
            .toList();
        // Check for the worst audio quality for the best video quality and pick according
        // This does not loose default sorting of audio encoding and bitrate
        final worstFormats =
            formats.map((f) => f['audioBitrate'] ?? 0).toList();
        worstFormats.sort((a, b) => a - b);
        final worstAudioQuality = worstFormats[0];
        format = formats
            .firstWhere((f) => (f['audioBitrate'] ?? 0) == worstAudioQuality);
        break;
      }

    case 'lowestvideo':
      formats = filterFormats(formats, 'video');
      formats.sort(sortFormatsByVideo);
      format = formats[formats.length - 1];
      break;

    default:
      format = getFormatByQuality(quality, formats);
      break;
  }

  if (!nodeIsTruthy(format)) {
    throw 'No such format found: $quality';
  }
  return format;
}

/// Gets a format based on quality or array of quality's
///^
/// @param {string|[string]} quality
/// @param {[Object]} formats
/// @returns {Object}
Map<String, dynamic>? getFormatByQuality(
    quality, List<Map<String, dynamic>> formats) {
  if (quality is List) {
    return _getFormat(
        quality.firstWhere((q) => nodeIsTruthy(_getFormat(q, formats))),
        formats);
  } else {
    return _getFormat(quality, formats);
  }
}

Map<String, dynamic>? _getFormat(dynamic itag, formats) {
  final Map<String, Object> empty = {};

  var result = formats.firstWhere((format) => '${format['itag']}' == '$itag',
      orElse: () => empty);
  return result == empty ? null : result;
}

/// @param {Array.<Object>} formats
/// @param {Function} filter
/// @returns {Array.<Object>}
List<Map<String, dynamic>> filterFormats(
    List<Map<String, dynamic>> formats, filter) {
  var fn;
  switch (filter) {
    case 'videoandaudio':
    case 'audioandvideo':
      fn = (format) => format['hasVideo'] == true && format['hasAudio'] == true;
      break;

    case 'video':
      fn = (format) => format['hasVideo'] == true;
      break;

    case 'videoonly':
      fn = (format) =>
          nodeIsTruthy(format['hasVideo']) && !nodeIsTruthy(format['hasAudio']);
      break;

    case 'audio':
      fn = (format) => nodeIsTruthy(format['hasAudio']);
      break;

    case 'audioonly':
      fn = (format) =>
          !nodeIsTruthy(format['hasVideo']) && format['hasAudio'] == true;
      break;

    default:
      if (filter is Function) {
        // problem not correct
        fn = filter;
      } else {
        throw 'Given filter ($filter) is not supported';
      }
  }

  final type = () => true;
  if (filter.runtimeType.toString() == type.runtimeType.toString()) {
    return formats.where((format) => format['url'] != null && fn()).toList();
  }

  return formats
      .where((format) => format['url'] != null && fn(format))
      .toList();
}

/// @param {Object} format
/// @returns {Object}
addFormatMeta(Map<String, dynamic> format) {
  format = {...?FORMATS[format['itag']?.toString()], ...format};
  format['hasVideo'] = nodeIsTruthy(format['qualityLabel']);
  format['hasAudio'] = nodeIsTruthy(format['audioBitrate']);
  format['container'] = format['mimeType'] != null
      ? format['mimeType'].split(';').first.split('/')[1]
      : null;
  format['codecs'] = nodeIsTruthy(format['mimeType'])
      ? between(format['mimeType'], 'codecs="', '"')
      : null;
  format['videoCodec'] =
      nodeIsTruthy(format['hasVideo']) && nodeIsTruthy(format['codecs'])
          ? format['codecs'].split(', ').first
          : null;
  format['audioCodec'] = (format['hasAudio'] && nodeIsTruthy(format['codecs']))
      ? (format['codecs'] as String).split(', ').last
      : null;
  format['isLive'] =
      RegExp('\bsource[/=]yt_live_broadcast\b').hasMatch(format['url']);
  format['isHLS'] =
      RegExp('/manifest/hls_(variant|playlist)/').hasMatch(format['url']);
  format['isDashMPD'] = RegExp('/manifest/dash/').hasMatch(format['url']);
  return format;
}
