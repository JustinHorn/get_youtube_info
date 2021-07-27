// final ytdl = require('..');
// final assert = require('assert-diff');
// final nock = require('./nock');
// final miniget = require('miniget');

import "package:get_youtube_info/get_youtube_info.dart";
import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';

import 'helper.dart';
import 'test_helper.dart';
import 'nock.dart';

const DEFAULT_USER_AGENT =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.101 Safari/537.36';
main() {
  InfoClass.max_retries = 0;

  tearDown(() => nock.cleanAll());
  tearDown(() {
    Sig.cache.clear();
    InfoClass.cache.clear();
    InfoClass.cookieCache.clear();
    InfoClass.watchPageCache.clear();
  });
  group('ytdl.getBasicInfo()', () {
    // before(() nock.disableNetConnect());
    // after(()  nock.enableNetConnect());
    // setUpAll(() => nock.init());

    // var minigetDefaults = miniget.defaultOptions;
    // before(() => miniget.defaultOptions = Object.assign({}, minigetDefaults, { maxRetries: 0 }));
    // after(() => miniget.defaultOptions = minigetDefaults);

    group('From a regular video', () {
      test('Retrieves correct metainfo', () async {
        final expected = await getFileAsMap(
            './test/files/videos/regular/expected-info.json');
        final id = '_HSylqgVYQI';
        final scope = await nockFunction(id, 'regular', opts: {
          'watchHtml': false,
          'player': false,
        });
        var info = await getBasicInfo(id, {
          'requestOptions': {'maxRetries': 0}
        });
        scope.done();
        expectOk(info['videoDetails']['description'].length);
        expect(info['formats'].length, expected['formats'].length);
      });

      test('Retrieves just enough metainfo without all formats', () async {
        final id = '5qap5aO4i9A';
        final expected = await getFileAsMap(
            './test/files/videos/live-now/expected-info.json');
        final scope = await nockFunction(id, 'live-now', opts: {
          'player': false,
          'dashmpd': false,
          'm3u8': false,
        });
        var info = await getBasicInfo(id, {
          'requestOptions': {'maxRetries': 0}
        });
        scope.done();
        expectOk(info['formats'].length != expected['formats'].length);
      });

      // group('Use `ytdl.downloadFromInfo()`', () { // ytdl download?
      //   test('Throw error', ()async {
      //     final id = '5qap5aO4i9A';
      //     final scope = nockFunction(id, 'regular',opts: {
      //       'watchHtml': false,
      //       'player': false,
      //     });
      //     var info = await getBasicInfo(id,{ 'requestOptions': {'maxRetries': 0}});
      //     scope.done();
      //     expect() {
      //       ytdl.downloadFromInfo(info);
      //     }, /Cannot use/);
      //   });
      // });

      group('Pass request options', () {
        test('Request gets called with more headers', () async {
          final id = '_HSylqgVYQI';
          final scope = await nockFunction(id, 'regular', opts: {
            'headers': {'X-Hello': '42'},
            'watchHtml': false,
            'player': false,
          });

          await getBasicInfo(id, {
            'requestOptions': {
              'headers': {'X-Hello': '42'},
              'maxRetries': 0
            },
          });
          scope.done();
        });
      });

      group('Called twice', () {
        test('Makes requests once', () async {
          final expected = await getFileAsMap(
              './test/files/videos/regular/expected-info.json');
          final id = '_HSylqgVYQI';
          final scope = await nockFunction(id, 'regular', opts: {
            'watchHtml': false,
            'player': false,
          });
          var info1 = await getBasicInfo(id, {
            'requestOptions': {'maxRetries': 0}
          });
          expectOk(info1["videoDetails"]?["description"]?.length);
          expect(info1["formats"].length, expected["formats"].length);
          print('____________');
          print('expect____okay');
          var info2 = await getBasicInfo(id, {
            'requestOptions': {'maxRetries': 0}
          });
          scope.done();
          expect(info2, info1);
        });
      });

      //   group('With user-agent header', () {
      test('Uses default user-agent if no user-agent is provided', () async {
        final id = '_HSylqgVYQI';
        final scope = await nockFunction(id, 'rich-thumbnails', opts: {
          'headers': {
            'User-Agent': DEFAULT_USER_AGENT,
          },
          'watchHtml': false,
          'player': false,
        });
        await getBasicInfo(id, {
          'requestOptions': {'maxRetries': 0}
        });
        scope.done();
      });

      test('Uses provided user-agent instead of default', () async {
        final id = '_HSylqgVYQI';
        final scope = await nockFunction(id, 'regular', opts: {
          'headers': {
            'User-Agent': 'yay',
          },
          'watchHtml': false,
          'player': false,
        });
        await getBasicInfo(id, {
          'requestOptions': {
            'headers': {
              'User-Agent': 'yay',
            },
            'maxRetries': 0
          },
        });
        scope.done();
      });
    });
  });

  group('From a live video', () {
    test('Returns correct video metainfo', () async {
      final id = '5qap5aO4i9A';
      final scope = await nockFunction(id, 'live-now', opts: {
        'player': false,
        'dashmpd': false,
        'm3u8': false,
      });
      var info = await getBasicInfo(id, {
        'requestOptions': {'maxRetries': 0}
      });
      scope.done();
      expectOk(info['formats'].length);
      expectOk(info['videoDetails']);
      expectOk(info['videoDetails']['title']);
    });
  });

  group('From an age restricted video', () {
    test('Returns correct video metainfo', () async {
      final expected = await getFileAsMap(
          './test/files/videos/age-restricted/expected-info.json');
      final id = 'LuZu9N53Vd0';
      final scope = await nockFunction(id, 'age-restricted');
      var info = await getBasicInfo(id, {
        "requestOptions": {"maxRetries": 0}
      });
      scope.done();
      expect(info['formats'].length, expected['formats'].length);
      expectOk(info['videoDetails']['age_restricted']);
      expectOk(info['formats'].length);
    });
  });

  group('From a video that was live streamed but not currently live', () {
    test('Returns correct video metainfo', () async {
      final id = 'nu5uzMXfuLc';
      final scope = await nockFunction(id, 'live-past');
      var info = await getBasicInfo(id, {
        "requestOptions": {"maxRetries": 0}
      });
      scope.done();
      expect(info['formats'].length, 10);
    });
  });

  group('From a video that is not embeddable outside of YouTube', () {
    test('Returns correct video metainfo', () async {
      final id = 'GFg8BP01F5Q';
      final scope = await nockFunction(id, 'no-embed');
      var info = await getBasicInfo(id, {
        "requestOptions": {"maxRetries": 0}
      });
      scope.done();
      expectOk(info['formats'].length);
    });
  });

  group('From videos without formats', () {
    group('Rental video', () {
      test('Gets video details', () async {
        final id = 'SyKPsFRP_Oc';
        final scope = await nockFunction(id, 'rental');
        var info = await getBasicInfo(id, {
          "requestOptions": {"maxRetries": 0}
        });
        scope.done();
        expectOk(info);
        expectOk(info['videoDetails']);
        expectOk(info['videoDetails']['title']);
      });
    });
    group('Not yet broadcasted', () {
      test('Gets video details', () async {
        final id = 'VIBFo3Ti5vQ';
        final scope = await nockFunction(id, 'live-future');
        var info = await getBasicInfo(id, {
          'requestOptions': {'maxRetries': 0}
        });
        scope.done();
        expectOk(info);
        expectOk(info['videoDetails']);
        expectOk(info['videoDetails']['title']);
      });
    });
  });

  group('From the longest video uploaded', () {
    test('Gets correct `lengthSeconds`', () async {
      final id = 'TceijYjxdrQ';
      final scope = await nockFunction(id, 'longest-upload');
      var info = await getBasicInfo(id, {
        "requestOptions": {"maxRetries": 0}
      });
      scope.done();
      expectOk(info);
      expectOk(info['videoDetails']);
      expect(info['videoDetails']['lengthSeconds'], '805000');
    });
  });

  group('With cookie headers', () {
    final id = '_HSylqgVYQI';
    group('`x-youtube-identity-token` given', () {
      test('Does not make extra request to watch.html page', () async {
        final scope = await nockFunction(id, 'regular', opts: {
          'watchHtml': [true, 500],
          'player': false,
        });
        var info = await getBasicInfo(id, {
          'requestOptions': {
            'headers': {
              'cookie': 'abc=1',
              'x-youtube-identity-token': '1324',
            },
          },
        });
        scope.done();
        expectOk(info['formats'].length);
      });
    });
    group('`x-youtube-identity-token` not given', () {
      test('Retrieves identity-token from watch.html page', () async {
        final scope = await nockFunction(id, 'regular', opts: {
          'watchHtml': [true, 400],
          'get_video_info': false,
          'player': false,
        });
        final scope2 = await nockFunction(id, 'regular', opts: {
          'watchHtml': [true, 200, (body) => '$body\n{"ID_TOKEN":"abcd"}'],
          'watchJson': false,
          'get_video_info': false,
          'player': false,
        });
        var info = await getBasicInfo(id, {
          'requestOptions': {
            'headers': {'cookie': 'abc=1'},
          },
        });
        scope.done();
        scope2.done();
        expectOk(info['formats'].length);
      });

      group('Unable to find token', () {
        test('Returns an error', () async {
          final scope = await nockFunction(id, 'regular', opts: {
            'watchHtml': [
              [true, 500],
              [true, 200],
            ],
            'watchJson': false,
            'get_video_info': false,
            'player': false,
          });
          try {
            var r = await getBasicInfo(id, {
              'requestOptions': {
                'headers': {'cookie': 'abc=1'},
              },
            });
            fail('no error');
          } catch (e) {
            expect((e as UnrecoverableError).message,
                'Cookie header used in request, but unable to find YouTube identity token');
          }

          scope.done();
        });
      });

      group('Called from a web browser with cookies in requests', () {
        test('Tries to get identity-token from watch.html page', () async {
          final scope = await nockFunction(id, 'regular', opts: {
            'watchHtml': [
              [true, 500],
              [true, 500],
              [true, 200],
            ],
            'watchJson': [
              [true, 200, '}]{"reload":"now"}'],
              [true, 200],
            ],
            'get_video_info': false,
            'player': false,
          });
          var info = await getBasicInfo(id, {
            'requestOptions': {
              // Assume cookie header is given by the browser.
              'headers': {},
              'maxRetries': 1,
              'backoff': {'inc': 0},
            },
          });
          scope.done();
          expectOk(info['formats'].length);
        });
      });
    });
    group('`x-youtube-identity-token` already in cache', () {
      test('Does not make extra request to watch.html page', () async {
        MainCache.cookie.set('abc=1', 'token!');
        final scope = await nockFunction(id, 'regular', opts: {
          'watchHtml': [true, 500],
          'player': false,
        });
        var info;
        try {
          info = await getBasicInfo(id, {
            'requestOptions': {
              'headers': {
                'cookie': 'abc=1',
              },
            },
          });
        } catch (e) {}
        scope.done();
        expectOk(info['formats'].length);
      });
    });
  });

  group('When there is a recoverable error', () {
    group('Unable to find json field', () {
      test('Uses backup endpoint', () async {
        final expected = await getFileAsMap(
            './test/files/videos/use-backups/expected-info.json');
        final id = 'LuZu9N53Vd0';
        final scope = await nockFunction(id, 'use-backups', opts: {
          'watchJson': [true, 200, '{"reload":"now"}'],
          'watchHtml': [true, 200, '<html></html>'],
          'embed': false,
          'player': false,
        });
        var info = await getBasicInfo(id, {});
        scope.done();
        expect(info['formats'].length, expected['formats'].length);
      });
    });

    group('Unable to parse watch.json page config', () {
      test('Uses backup', () async {
        final id = 'LuZu9N53Vd0';
        final scope = await nockFunction(id, 'use-backups', opts: {
          'watchHtml': [true, 500],
          'watchJson': [true, 200, '{]}'],
          'embed': false,
          'player': false,
        });
        var info = await getBasicInfo(id, {});
        scope.done();
        expectOk(info['formats'].length);
        expectOk(info['formats'].first['url']);
      });
    });

    group('When watch.json page gives back `{"reload":"now"}`', () {
      test('Retries the request', () async {
        final id = '_HSylqgVYQI';
        final scope1 = await nockFunction(id, 'regular', opts: {
          'watchHtml': [
            [true, 500],
            [true, 500],
          ],
          'watchJson': [
            [true, 200, '{"reload":"now"}'],
            [true, 200],
          ],
          'get_video_info': false,
          'player': false,
        });
        var info = await getBasicInfo(id, {
          'requestOptions': {'maxRetries': 1}
        });
        scope1.done();
        expectOk(info['formats'].length);
        expectOk(info['formats'].first['url']);
      });

      group('Too many times', () {
        test('Uses backup endpoint', () async {
          final id = 'LuZu9N53Vd0';
          final scope = await nockFunction(id, 'use-backups', opts: {
            'watchHtml': [
              [true, 500],
              [true, 500],
            ],
            'watchJson': [
              [true, 200, '{"reload":"now"}'],
              [true, 200, '{"reload":"now"}'],
            ],
            'embed': false,
            'player': false,
          });
          var info = await getBasicInfo(id, {
            'requestOptions': {
              'maxRetries': 1,
              'backoff': {'inc': 0},
            },
          });
          scope.done();
          expectOk(info['formats'].length);
        });
      });
    });

    group('When watch.json page gives back an empty response', () {
      test('Uses backup endpoint', () async {
        final id = 'LuZu9N53Vd0';
        final scope1 = await nockFunction(id, 'use-backups', opts: {
          'watchHtml': false,
          'watchJson': [true, 200, '[]'],
          'embed': false,
          'player': false,
        });
        var info = await getBasicInfo(id, {
          'requestOptions': {'maxRetries': 0}
        });
        scope1.done();
        expectOk(info['formats'].length);
        expectOk(info['formats'].first['url']);
      });
    });

    group('When an endpoint gives back a 500 server error', () {
      test('Retries the request', () async {
        final id = '_HSylqgVYQI';
        final scope1 = await nockFunction(id, 'regular', opts: {
          'watchHtml': [
            [true, 500],
            [true, 200],
          ],
          'watchJson': false,
          'player': false,
        });
        var info = await getBasicInfo(id, {
          'requestOptions': {'maxRetries': 1}
        });
        scope1.done();
        expectOk(info['formats'].length);
        expectOk(info['formats'].first['url']);
      });

      group('Too many times', () {
        test('Uses the next endpoint as backup', () async {
          final id = 'LuZu9N53Vd0';
          final scope = await nockFunction(id, 'use-backups', opts: {
            'watchHtml': [true, 502],
            'embed': false,
            'player': false,
          });
          var info = await getBasicInfo(id, {});
          scope.done();
          expectOk(info['formats'].length);
          expectOk(info['formats'].first['url']);
          expectNotOk(info['videoDetails']['age_restricted']);
        });
      });
    });
  });

  group('When there is an unrecoverable error', () {
    group('With a private video', () {
      test('Fails gracefully', () async {
        final id = 'z2jeHsa0UG0';
        final scope = await nockFunction(id, 'private');
        try {
          await getBasicInfo(id, {
            'requestOptions': {'maxRetries': 1}
          });
        } catch (e) {
          expect((e as UnrecoverableError).message, contains('private video'));
        }

        scope.done();
      });
    });

    group('From a non-existant video', () {
      final id = '99999999999';
      test('Should give an error', () async {
        final scope = await nockFunction(id, 'non-existent');
        try {
          await getBasicInfo(id, {
            'requestOptions': {'maxRetries': 1}
          });
        } catch (e) {
          expect(
              (e as UnrecoverableError).message, contains('Video unavailable'));
        }

        scope.done();
      });
    });

    group('With a bad video ID', () {
      test('Throws a catchable error', () async {
        // TODO: check this! bad error message
        final id = 'bad';
        try {
          await getBasicInfo(id, {});
        } catch (err) {
          print(err.runtimeType);
          expect(err.toString(), contains('No video id found'));
          return;
        }
        throw Exception('should not get here');
      });
      // test('Promise is rejected with caught error', () async { // this as well!
      //   final id = 'https://website.com';
      //   var catchError = (getBasicInfo(id, {}).catchError((err) {
      //     print(err.toString());
      //     expectOk(true);
      //            assert.ok(/Not a YouTube domain/.test(err.message));

      //   }));

      //   var t = await catchError;
      // });
    });

    // group('No endpoint works', () {
    //   test('Fails gracefully', () async {
    //     final id = 'LuZu9N53Vd0';
    //     final scope = await nockFunction(id, 'use-backups', opts: {
    //       'watchJson': [true, 500],
    //       'watchHtml': [true, 500],
    //       'get_video_info': [true, 500],
    //       'embed': false,
    //       'player': false,
    //     });
    //     try {
    //       await getBasicInfo(id, {
    //         'requestOptions': {'maxRetries': 0},
    //       });
    //     } catch (e) {
    //       print(e.toString());
    //       //    /Status code: 500/

    //       expectOk(true);
    //     }
    //     scope.done();
    //   });
    // });
    // });
  });
}
