import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_youtube_info/get_youtube_info.dart';

import 'package:nock/nock.dart';

main() {
  group('Get tokens', () {
    // final key = 'en_US-vfljDEtYP';
    // final url = 'https://s.ytimg.com/yts/jsbin/player-en_US-vfljDEtYP/base.js';

    // test('Returns a set of tokens', () async {
    //   //final scope = nock(url).get('')..reply(200, )(200, filepath);
    //   var tokens = (await getTokens(url, {}));
    //   //scope.done();
    //   expect(tokens.length, greaterThan(0));
    // });

    // group('Hit the same video twice', () {
    //   test('Gets html5player tokens from cache', () async {
    //     //final scope = nock.url(url).replyWithFile(200, filepath);
    //     var tokens = await getTokens(url, {});
    //     // scope.done();
    //     expect(tokens.length, greaterThan(0));
    //     var tokens2 = await getTokens(url, {});
    //     expect(tokens.length, greaterThan(0));
    //   });
    // });

    // group('use nock', () {
    //   setUpAll(() {
    //     nock.init();
    //   });

    //   setUp(() {
    //     nock.cleanAll();
    //   });

    //   group('Get a bad html5player file', () {
    //     test('Gives an error', () async {
    //       final baseURL = 'https://s.ytimg.com';
    //       final path = '/yts/jsbin/player-en_US-bad/base.js';
    //       final scope = nock(baseURL).get(path)..reply(404, 'uh oh');

    //       try {
    //         await getTokens(baseURL + path, {});
    //         fail('there should have been an error');
    //       } catch (e) {
    //         expect(scope.isDone, true);
    //       }
    //     });
    //   });

    //   group('Unable to find tokens', () {
    //     final testKey = 'mykey';
    //     final testUrl = 'https://s.ytimg.com/yts/jsbin/player-$testKey/base.js';
    //     final contents = 'my personal contents';

    //     test('Gives an error', () async {
    //       final scope = nock(testUrl).get('')..reply(200, contents);

    //       try {
    //         await getTokens(testUrl, {});
    //         fail('there should have been an error');
    //       } catch (e) {
    //         expect(e.toString(),
    //             equals('Could not extract signature deciphering actions'));
    //         expect(scope.isDone, true);
    //       }
    //     });
    //   });
    // });

    var html5Player;

    Future<Map<String, dynamic>> getHTML5player() async {
      if (html5Player != null) return html5Player;
      final fileString = await File('./test/html5player.json').readAsString();
      final Map<String, dynamic> html5player = jsonDecode(fileString);
      return html5player;
    }

    group("Signature decipher", () {
      group("extract deciphering actions", () {
        test("Returns the correct set of actions", () async {
          var total = 0;

          final Map<String, dynamic> html5player = await getHTML5player();

          for (var name in html5player.keys) {
            total++;
            var body =
                await File('./test/files/html5player/$name.js').readAsString();

            final actions = extractActions(body);
            expect(actions, html5player[name]);
          }
        });
      });
      testDecipher(List<String> tokens, input, expected) {
        final result = decipher(tokens, input);
        expect(result, equals(expected));
      }

      group("properly apply actions based on tokens", () {
        // test("reverses", () {
        //   testDecipher(["r"], "abcdefg", "gfedcba");
        // });

        // test("swaps head and position", () {
        //   testDecipher(["w2"], "abcdefg", "cbadefg");
        //   testDecipher(["w3"], "abcdefg", "dbcaefg");
        //   testDecipher(["w5"], "abcdefg", "fbcdeag");
        // });

        // test("slices", () {
        //   testDecipher(["s3"], "abcdefg", "defg");
        // });

        test("real set of tokens", () async {
          testDecipher(
              (await getHTML5player())["en_US-vfl0Cbn9e"].cast<String>(),
              "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
              "bbSdefghijklmnoaqrstuvwxyzAZCDEFGHIJKLMNOPQRpTUVWc");
        });
      });
    });
  });
}
