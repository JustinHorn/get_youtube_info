// final ytdl = require('..');
// final assert = require('assert-diff');
// final await nockFunction = require('./await nockFunction');
// final miniget = require('miniget');

import 'package:get_youtube_info/get_youtube_info.dart';
import 'package:flutter_test/flutter_test.dart';

import 'format_utils_test.dart';
import 'helper.dart';
import 'nock.dart';
import 'test_helper.dart';

main() {
  InfoClass.max_retries = 0;

  group('ytdl.getInfo()', () {
    // var minigetDefaults = miniget.defaultOptions;
    // before(() => miniget.defaultOptions = Object.assign({}, minigetDefaults, { maxRetries: 0 }));
    // after(() => miniget.defaultOptions = minigetDefaults);

    // group('After calling ytdl.getBasicInfo()', () {
    //   test('Does not make extra requests', () async {
    //     final id = '5qap5aO4i9A';
    //     final scope = await nockFunction(id, 'live-now');

    //     var info = await getBasicInfo(id, {});
    //     var info2 = await getInfo(id, {});

    //     scope.done();
    //     expectOk(info['html5player']);

    //     expect(info['formats'].length, info2['formats'].length);
    //     expect(info['formats'].first['url'], info2['formats'].first['url']);
    //   });
    // });

    // group('Use `ytdl.downloadFromInfo()`', () {
    //   test('Retrieves video file', () async {
    //     final expected = await getFileAsMap('./test/files/videos/regular/expected-info.json');
    //     final stream = downloadFromInfo(expected);
    //     var scope;
    //     stream.on('info', (info, format) => {
    //       scope = await nockFunction.url(format.url).reply(200);
    //     });
    //     stream.resume();
    //     stream.on('error', done);
    //     stream.on('end', () {
    //       scope.done();
    //       done();
    //     });
    //   });
    // });

    group('From a video with a cipher', () {
      test('Retrieves deciphered video formats', () async {
        final id = 'B3eAMGXFw1o';
        final scope = await nockFunction(id, 'cipher');
        var info = await getBasicInfo(id, {});
        expectOk(info);
        expectOk(info['formats']);
        expectOk(info['formats'].length);
        expectOk(info['formats']
            .any((format) => nodeIsTruthy(format['signatureCipher'])));
        info = await getInfo(id, {});

        final formats = info['formats'];
        expectOk(formats
            .every((format) => !nodeIsTruthy(format['signatureCipher'])));

        formats.forEach((format) => print(format['url']));
        expectOk(formats.every((format) => nodeIsTruthy(format['url'])));
        scope.done();
      });
    });

    // group('From a video that includes subtitles in DASH playlist', () {
    //   test('Does not include subtitle formats in formats list', () async {
    //     final id = '21X5lGlDOfg';
    //     final scope = await nockFunction(id, 'live-with-cc');
    //     var info = await ytdl.getInfo(id);
    //     scope.done();
    //     for (var format of info.formats) {
    //       assert.strictEqual(typeof format.itag, 'number');
    //     }
    //   });
    // });

    // group('When unable to find html5player', () {
    //   test('Uses backup endpoint', () async {
    //     final id = 'LuZu9N53Vd0';
    //     final scope = await nockFunction(id, 'use-backups', {
    //       watchHtml: [true, 200, body => body.replace(/"(player_ias\/base|jsUrl)"/g, '""')],
    //       watchJson: false,
    //       get_video_info: false,
    //       player: true,
    //     });
    //     var info = await ytdl.getInfo(id);
    //     scope.done();
    //     expectOk(info.html5player);
    //     expectOk(info.formats.length);
    //     expectOk(info.formats[0].url);
    //   });
    // });

    // group('Unable to find html5player anywhere', () {
    //   test('Fails gracefully', () async {
    //     final id = 'LuZu9N53Vd0';
    //     final scope = await nockFunction(id, 'use-backups', {
    //       watchHtml: [true, 200, body => body.replace(/"(player_ias\/base|jsUrl)"/g, '""')],
    //       embed: [true, 200, body => body.replace(/"(player_ias\/base|jsUrl)"/g, '""')],
    //       watchJson: false,
    //       get_video_info: false,
    //       player: false,
    //     });
    //     await assert.rejects(ytdl.getInfo(id), /Unable to find html5player file/);
    //     scope.done();
    //   });
    // });
  });
}
