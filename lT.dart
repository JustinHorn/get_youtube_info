bool nodeIsTruthy(dynamic value) =>
    value != 0 && value != '' && value != false && value != null;

/// Gets a format based on quality or array of quality's
///^
/// @param {string|[string]} quality
/// @param {[Object]} formats
/// @returns {Object}
Map<String, dynamic>? getFormatByQuality(
    quality, List<Map<String, dynamic>> formats) {
  if (quality is List) {
    return getFormat(
        quality.firstWhere((q) => nodeIsTruthy(getFormat(q, formats))),
        formats);
  } else {
    return getFormat(quality, formats);
  }
}

Map<String, dynamic>? getFormat(dynamic itag, formats) {
  final Map<String, Object> empty = {'empty': ''};

  var result = formats.firstWhere((format) => '${format['itag']}' == '$itag',
      orElse: () => empty);
  return result == empty ? null : result;
}

main() {
  var arr = 'abcdef';
  print(arr.split('').last);
}

final formats = [
  {
    'itag': '96',
    'mimeType': 'video/ts; codecs="H.264, aac"',
    'container': 'ts',
    'qualityLabel': '1080p',
    'codecs': 'H.264, aac',
    'videoCodec': 'H.264',
    'audioCodec': 'aac',
    'bitrate': 2500000,
    'audioBitrate': 256,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
    'isHLS': true,
  },
  {
    'itag': '96.worse.audio',
    'mimeType': 'video/ts; codecs="H.264, aac"',
    'container': 'ts',
    'qualityLabel': '1080p',
    'codecs': 'H.264, aac',
    'videoCodec': 'H.264',
    'audioCodec': 'aac',
    'bitrate': 2500000,
    'audioBitrate': 128,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
    'isHLS': true,
  },
  {
    'itag': '95',
    'mimeType': 'video/ts; codecs="H.264, aac"',
    'container': 'ts',
    'qualityLabel': '720p',
    'codecs': 'H.264, aac',
    'videoCodec': 'H.264',
    'audioCodec': 'aac',
    'bitrate': 1500000,
    'audioBitrate': 256,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
    'isHLS': true,
  },
  {
    'itag': '94',
    'mimeType': 'video/ts; codecs="H.264, aac"',
    'container': 'ts',
    'qualityLabel': '480p',
    'codecs': 'H.264, aac',
    'videoCodec': 'H.264',
    'audioCodec': 'aac',
    'bitrate': 800000,
    'audioBitrate': 128,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
    'isHLS': true,
  },
  {
    'itag': '92',
    'mimeType': 'video/ts; codecs="H.264, aac"',
    'container': 'ts',
    'qualityLabel': '240p',
    'codecs': 'H.264, aac',
    'videoCodec': 'H.264',
    'audioCodec': 'aac',
    'bitrate': 150000,
    'audioBitrate': 48,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
    'isHLS': true,
  },
  {
    'itag': '91',
    'mimeType': 'video/ts; codecs="H.264, aac"',
    'container': 'ts',
    'qualityLabel': '144p',
    'codecs': 'H.264, aac',
    'videoCodec': 'H.264',
    'audioCodec': 'aac',
    'bitrate': 100000,
    'audioBitrate': 48,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
    'isHLS': true,
  },
];
