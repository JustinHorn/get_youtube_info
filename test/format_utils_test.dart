import 'package:get_youtube_info/get_youtube_info.dart';
import 'package:flutter_test/flutter_test.dart';

final formats = [
  {
    'itag': '18',
    'mimeType': 'video/mp4; codecs="avc1.42001E, mp4a.40.2"',
    'container': 'mp4',
    'qualityLabel': '360p',
    'codecs': 'avc1.42001E, mp4a.40.2',
    'videoCodec': 'avc1.42001E',
    'audioCodec': 'mp4a.40.2',
    'bitrate': 500000,
    'audioBitrate': 96,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
  },
  {
    'itag': '19',
    'mimeType': 'audio/mp4; codecs="avc1.42001E, mp4a.40.2"',
    'container': 'mp4',
    'qualityLabel': null,
    'codecs': 'avc1.42001E, mp4a.40.2',
    'videoCodec': null,
    'audioCodec': 'avc1.42001E, mp4a.40.2',
    'bitrate': 500000,
    'audioBitrate': 96,
    'url': 'https://googlevideo.com/',
    'hasVideo': false,
    'hasAudio': true,
  },
  {
    'itag': '43',
    'mimeType': 'video/webm; codecs="vp8.0, vorbis"',
    'container': 'webm',
    'qualityLabel': '360p',
    'codecs': 'vp8.0, vorbis',
    'videoCodec': 'vp8.0',
    'audioCodec': 'vorbis',
    'bitrate': 500000,
    'audioBitrate': 128,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
  },
  {
    'itag': '133',
    'mimeType': 'video/mp4; codecs="avc1.4d400d"',
    'container': 'mp4',
    'qualityLabel': '240p',
    'codecs': 'avc1.4d400d',
    'videoCodec': 'avc1.4d400d',
    'audioCodec': null,
    'bitrate': 300000,
    'audioBitrate': null,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': false,
  },
  {
    'itag': '36',
    'mimeType': 'video/3gpp; codecs="mp4v.20.3, mp4a.40.2"',
    'container': '3gp',
    'qualityLabel': '240p',
    'codecs': 'mp4v.20.3, mp4a.40.2',
    'videoCodec': 'mp4v.20.3',
    'audioCodec': 'mp4a.40.2',
    'bitrate': 170000,
    'audioBitrate': 38,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
  },
  {
    'itag': '5',
    'mimeType': 'video/flv; codecs="Sorenson H.283, mp3"',
    'container': 'flv',
    'qualityLabel': '240p',
    'codecs': 'Sorenson H.283, mp3',
    'videoCodec': 'Sorenson H.283',
    'audioCodec': 'mp3',
    'bitrate': 250000,
    'audioBitrate': 64,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
  },
  {
    'itag': '160',
    'mimeType': 'video/mp4; codecs="avc1.4d400c"',
    'container': 'mp4',
    'qualityLabel': '144p',
    'codecs': 'avc1.4d400c',
    'videoCodec': 'avc1.4d400c',
    'audioCodec': null,
    'bitrate': 100000,
    'audioBitrate': null,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': false,
  },
  {
    'itag': '17',
    'mimeType': 'video/3gpp; codecs="mp4v.20.3, mp4a.40.2"',
    'container': '3gp',
    'qualityLabel': '144p @ 60fps',
    'codecs': 'mp4v.20.3, mp4a.40.2',
    'videoCodec': 'mp4v.20.3',
    'audioCodec': 'mp4a.40.2',
    'bitrate': 50000,
    'audioBitrate': 24,
    'url': 'https://googlevideo.com/',
    'hasVideo': true,
    'hasAudio': true,
  },
  {
    'itag': '140',
    'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
    'container': 'mp4',
    'qualityLabel': null,
    'codecs': 'mp4a.40.2',
    'videoCodec': null,
    'audioCodec': 'mp4a.40.2',
    'bitrate': null,
    'audioBitrate': 128,
    'url': 'https://googlevideo.com/',
    'hasVideo': false,
    'hasAudio': true,
  },
  {
    'itag': '139',
    'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
    'container': 'mp4',
    'qualityLabel': null,
    'codecs': 'mp4a.40.2',
    'videoCodec': null,
    'audioCodec': 'mp4a.40.2',
    'bitrate': null,
    'audioBitrate': null,
    'hasVideo': false,
    'hasAudio': false,
  },
  {
    'itag': '138',
    'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
    'container': 'mp4',
    'qualityLabel': null,
    'codecs': 'mp4a.40.2',
    'videoCodec': null,
    'audioCodec': 'mp4a.40.2',
    'bitrate': null,
    'audioBitrate': null,
    'url': 'https://googlevideo.com/',
    'hasVideo': false,
    'hasAudio': false,
  },
];

var liveWithHLS = [
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

main() {
  group('sortFormats()', () {
    var live_With_HLS = formats
        .where((x) => x['isLive'] != null && x['isLive'] as bool)
        .toList();
    live_With_HLS.addAll(liveWithHLS);

    final getItags = (format) => format['itag'];
    group('With `highest` given', () {
      test('Sorts available formats from highest to lowest quality', () async {
        final sortedFormats = [...formats];
        sortedFormats.sort(sortFormats);
        final itags = sortedFormats.map(getItags);
        expect(
            itags,
            equals([
              '43',
              '18',
              '5',
              '36',
              '17',
              '133',
              '160',
              '19',
              '140',
              '139',
              '138',
            ]));
      });
    });
  });

  group('chooseFormat', () {
    final sortedFormats = formats.sublist(0);
    sortedFormats.sort(sortFormats);

    // group('with no options', () {
    //   test('Chooses highest quality', () {
    //     final format = chooseFormat(sortedFormats, {});
    //     expect(format['itag'], equals('43'));
    //   });
    // });

    // group('With lowest quality wanted', () {
    //   test('Chooses lowest itag', () {
    //     final format = chooseFormat(sortedFormats, {'quality': 'lowest'});
    //     expect(format['itag'], equals('138'));
    //   });
    // });

    // group('With highest audio quality wanted', () {
    //   test('Chooses highest audio itag', () {
    //     final format = chooseFormat(formats, {'quality': 'highestaudio'});
    //     expect(format['itag'], equals('43'));
    //   });

    //   group('and no formats passed', () {
    //     test('throws the regular no such format found error', () {
    //       expect(() => chooseFormat([], {'quality': 'highestaudio'}),
    //           throwsA(contains('No such format found')));
    //     });
    //   });

    //   group('and HLS formats are present', () {
    //     test('Chooses highest audio itag', () {
    //       final format = chooseFormat(liveWithHLS, {'quality': 'highestaudio'});
    //       expect(format['itag'], equals('95'));
    //     });
    //   });
    // });

    // group('With lowest audio quality wanted', () {
    //   test('Chooses lowest audio itag', () {
    //     final format = chooseFormat(formats, {'quality': 'lowestaudio'});
    //     expect(format['itag'], '17');
    //   });

    //   group('and HLS formats are present', () {
    //     test('Chooses lowest audio itag', () {
    //       final format = chooseFormat(liveWithHLS, {'quality': 'lowestaudio'});
    //       expect(format['itag'], equals('91'));
    //     });
    //   });
    // });

    // group('With highest video quality wanted', () {
    //   test('Chooses highest video itag', () {
    //     final format = chooseFormat(formats, {'quality': 'highestvideo'});
    //     expect(format['itag'], equals('18'));
    //   });

    //   group('and no formats passed', () {
    //     test('throws the regular no such format found error', () {
    //       expect(() => chooseFormat([], {'quality': 'highestvideo'}),
    //           throwsA(contains('No such format found')));
    //     });
    //   });

    //   group('and HLS formats are present', () {
    //     test('Chooses highest video itag', () {
    //       final format = chooseFormat(liveWithHLS, {'quality': 'highestvideo'});
    //       expect(format['itag'], equals('96.worse.audio'));
    //     });
    //   });
    // });

    // group('With lowest video quality wanted', () {
    //   test('Chooses lowest video itag', () {
    //     final format = chooseFormat(formats, {'quality': 'lowestvideo'});
    //     expect(format['itag'], '17');
    //   });

    //   group('and HLS formats are present', () {
    //     test('Chooses lowest audio itag', () {
    //       final format = chooseFormat(liveWithHLS, {'quality': 'lowestvideo'});
    //       expect(format['itag'], equals('91'));
    //     });
    //   });
    // });

    // group('With itag given', () {
    //   test('Chooses matching format', () {
    //     final format = chooseFormat(sortedFormats, {'quality': 5});
    //     expect(format['itag'], equals('5'));
    //   });

    //   group('that is not in the format list', () {
    //     test('Returns an error', () {
    //       expect(() => chooseFormat(sortedFormats, {'quality': 42}),
    //           throwsA(contains(r'No such format found: ')));
    //     });
    //   });
    // });

    // group('With list of itags given', () {
    //   test('Chooses matching format', () {
    //     final format = chooseFormat(sortedFormats, {
    //       'quality': [99, 160, 18]
    //     });
    //     expect(format['itag'], '160');
    //   });
    // });

    // group('With format object given', () {
    //   test('Chooses given format without searching', () {
    //     final format = chooseFormat(sortedFormats, {'format': formats[0]});
    //     expect(format, equals(formats[0]));
    //   });

    //   group('from `getBasicInfo()`', () {
    //     test('Throws error', () {
    //       expect(
    //           () => chooseFormat(sortedFormats, {
    //                 'format': formats
    //                     .where((format) => !nodeIsTruthy(format['url']))
    //                     .toList()[0]
    //               }),
    //           throwsA(contains('Invalid format given')));
    //     });
    //   });
    // });

    group('With filter given', () {
      group('that matches a format', () {
        test('Chooses a format', () {
          final choosenFormat = chooseFormat(sortedFormats, {
            'filter': (format) => format['container'] == 'mp4',
          });
          expect(choosenFormat['itag'], equals('18'));
        });
      });

      group('that matches audio only formats', () {
        group('and only non-HLS-livestream would match', () {
          test('throws the no format found exception', () {
            expect(() => chooseFormat(liveWithHLS, {'quality': 'audioonly'}),
                throwsA(contains('No such format found')));
          });
        });
      });

      group('that does not match a format', () {
        test('Returns an error', () {
          expect(() => chooseFormat(sortedFormats, {'filter': () => false}),
              throwsA(contains('No such format found')));
        });
      });
    });
  });
}

// group('filterFormats', () => {
//   test('Tries to find formats that match', () => {
//     const filter = format => format.container === 'mp4';
//     const itags = filterFormats(formats, filter).map(getItags);
//     assert.deepEqual(itags, ['18', '19', '133', '160', '140', '138']);
//   });

//   test('Ignores formats without a `url`', () => {
//     const itags = filterFormats(formats, () => true).map(getItags);
//     assert.deepEqual(itags, ['18', '19', '43', '133', '36', '5', '160', '17', '140', '138']);
//   });

//   test('Is exposed in module', () => {
//     assert.strictEqual(ytdl.filterFormats, filterFormats);
//   });

//   group('that doesn\'t match any format', () => {
//     test('Returns an empty list', () => {
//       const list = filterFormats(formats, () => false);
//       assert.strictEqual(list.length, 0);
//     });
//   });

//   group('With `video` given', () => {
//     test('Returns only matching formats', () => {
//       const itags = filterFormats(formats, 'video').map(getItags);
//       assert.deepEqual(itags, ['18', '43', '133', '36', '5', '160', '17']);
//     });
//   });

//   group('With `videoonly` given', () => {
//     test('Returns only matching formats', () => {
//       const itags = filterFormats(formats, 'videoonly').map(getItags);
//       assert.deepEqual(itags, ['133', '160']);
//     });
//   });

//   group('With `audio` given', () => {
//     test('Returns only matching formats', () => {
//       const itags = filterFormats(formats, 'audio').map(getItags);
//       assert.deepEqual(itags, ['18', '19', '43', '36', '5', '17', '140']);
//     });
//   });

//   group('With `audioonly` given', () => {
//     test('Returns only matching formats', () => {
//       const itags = filterFormats(formats, 'audioonly').map(getItags);
//       assert.deepEqual(itags, ['19', '140']);
//     });
//   });

//   group('With `audioandvideo` given', () => {
//     test('Returns only matching formats', () => {
//       const itags = filterFormats(formats, 'audioandvideo').map(getItags);
//       assert.deepEqual(itags, ['18', '43', '36', '5', '17']);
//     });
//   });

//   group('With `videoandaudio` given', () => {
//     test('Returns only matching formats', () => {
//       const itags = filterFormats(formats, 'videoandaudio').map(getItags);
//       assert.deepEqual(itags, ['18', '43', '36', '5', '17']);
//     });
//   });

//   group('With unsupported filter given', () => {
//     test('Returns only matching formats', () => {
//       assert.throws(() => {
//         filterFormats(formats, 'aaaa').map(getItags);
//       }, /not supported/);
//     });
//   });
// });


// group('addFormatMeta()', () => {
//   test('Adds extra metadata to a format', () => {
//     let format = addFormatMeta({
//       itag: 94,
//       url: 'http://video.com/1/2.ts',
//     });
//     assert.deepEqual(format, {
//       itag: 94,
//       url: 'http://video.com/1/2.ts',
//       mimeType: 'video/ts; codecs="H.264, aac"',
//       container: 'ts',
//       codecs: 'H.264, aac',
//       videoCodec: 'H.264',
//       audioCodec: 'aac',
//       qualityLabel: '480p',
//       bitrate: 800000,
//       audioBitrate: 128,
//       isLive: false,
//       isHLS: false,
//       isDashMPD: false,
//       hasVideo: true,
//       hasAudio: true,
//     });
//   });
//   group('With an unknown itag', () => {
//     test('Does not add extra metadata to a format', () => {
//       let format = addFormatMeta({
//         itag: -1,
//         url: 'http://video.com/3/4.ts',
//       });
//       assert.deepEqual(format, {
//         itag: -1,
//         url: 'http://video.com/3/4.ts',
//         container: null,
//         codecs: null,
//         videoCodec: null,
//         audioCodec: null,
//         isLive: false,
//         isHLS: false,
//         isDashMPD: false,
//         hasVideo: false,
//         hasAudio: false,
//       });
//     });
//   });
// });
