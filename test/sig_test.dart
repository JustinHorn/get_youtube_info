import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_youtube_info/get_youtube_info.dart';

import 'package:nock/nock.dart';

main() {
  group('Get tokens', () {
    final key = 'en_US-vfljDEtYP';
    final url = 'https://s.ytimg.com/yts/jsbin/player-en_US-vfljDEtYP/base.js';

    test('Returns a set of tokens', () async {
      //final scope = nock(url).get('')..reply(200, )(200, filepath);
      var tokens = (await getTokens(url, {}));
      //scope.done();
      expect(tokens.length, greaterThan(0));
    });

    group('Hit the same video twice', () {
      test('Gets html5player tokens from cache', () async {
        //final scope = nock.url(url).replyWithFile(200, filepath);
        var tokens = await getTokens(url, {});
        // scope.done();
        expect(tokens.length, greaterThan(0));
        var tokens2 = await getTokens(url, {});
        expect(tokens.length, greaterThan(0));
      });
    });

    group('use nock', () {
      setUpAll(() {
        nock.init();
      });

      setUp(() {
        nock.cleanAll();
      });

      group('Get a bad html5player file', () {
        test('Gives an error', () async {
          final baseURL = 'https://s.ytimg.com';
          final path = '/yts/jsbin/player-en_US-bad/base.js';
          final scope = nock(baseURL).get(path)..reply(404, 'uh oh');

          try {
            await getTokens(baseURL + path, {});
            fail('there should have been an error');
          } catch (e) {
            expect(scope.isDone, true);
          }
        });
      });

      group('Unable to find tokens', () {
        final testKey = 'mykey';
        final testUrl = 'https://s.ytimg.com/yts/jsbin/player-$testKey/base.js';
        final contents = 'my personal contents';

        test('Gives an error', () async {
          final scope = nock(testUrl).get('')..reply(200, contents);

          try {
            await getTokens(testUrl, {});
            fail('there should have been an error');
          } catch (e) {
            expect(e.toString(),
                equals('Could not extract signature deciphering actions'));
            expect(scope.isDone, true);
          }
        });
      });
    });

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
        test("reverses", () {
          testDecipher(["r"], "abcdefg", "gfedcba");
        });

        test("swaps head and position", () {
          testDecipher(["w2"], "abcdefg", "cbadefg");
          testDecipher(["w3"], "abcdefg", "dbcaefg");
          testDecipher(["w5"], "abcdefg", "fbcdeag");
        });

        test("slices", () {
          testDecipher(["s3"], "abcdefg", "defg");
        });

        test("real set of tokens", () async {
          testDecipher(
              (await getHTML5player())["en_US-vfl0Cbn9e"].cast<String>(),
              "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
              "bbSdefghijklmnoaqrstuvwxyzAZCDEFGHIJKLMNOPQRpTUVWc");
        });
      });
    });
  });

  group('Set download URL', () {
    test('Adds signature to download URL', () {
      var format = {
        'fallback_host': 'tc.v9.cache7.googlevideo.com',
        'quality': 'small',
        'type': 'video/x-flv',
        'itag': '5',
        // eslint-disable-next-line max-len
        'url':
            'https://r4---sn-p5qlsnsr.googlevideo.com/videoplayback?nh=IgpwZjAxLmlhZDI2Kgw3Mi4xNC4yMDMuOTU&upn=utAH1aBebVk&source=youtube&sparams=cwbhb%2Cdur%2Cid%2Cinitcwndbps%2Cip%2Cipbits%2Citag%2Clmt%2Cmime%2Cmm%2Cmn%2Cms%2Cmv%2Cnh%2Cpl%2Crequiressl%2Csource%2Cupn%2Cexpire&initcwndbps=772500&pl=16&ip=0.0.0.0&lmt=1309008098017854&key=yt6&id=o-AJj1D_OYO_EieAH08Qa2tRsP6zid9dsuPAvktizyDRlv&expire=1444687469&mm=31&mn=sn-p5qlsnsr&itag=5&mt=1444665784&mv=m&cwbhb=yes&fexp=9408208%2C9408490%2C9408710%2C9409069%2C9414764%2C9415435%2C9416126%2C9417224%2C9417380%2C9417488%2C9417707%2C9418448%2C9418494%2C9419445%2C9419802%2C9420324%2C9420348%2C9420982%2C9421013%2C9421170%2C9422341%2C9422540&ms=au&sver=3&dur=298.109&requiressl=yes&ipbits=0&mime=video%2Fx-flv&ratebypass=yes',
        'container': 'flv',
        'resolution': '240p',
        'encoding': 'Sorenson H.283',
        'profile': null,
        'bitrate': '0.25',
        'audioEncoding': 'mp3',
        'audioBitrate': 64,
      };
      setDownloadURL(format, 'mysiggy');
      expect((format['url']! as String).indexOf('signature=mysiggy'),
          greaterThan(-1));
    });

    group('With a badly formatted URL', () {
      final format = {
        'url': 'https://r4---sn-p5qlsnsr.googlevideo.com/videoplayback?%',
      };

      test('Does not set URL', () {
        setDownloadURL(format, 'mysiggy');
        expect(
            (format['url'] as String).indexOf('signature=mysiggy'), equals(-1));
      });
    });

    group('Without a URL', () {
      test('Does not set URL', () {
        final format = {'bla': 'blu'};
        setDownloadURL(format, 'nothing');
        expect(format, equals({'bla': 'blu'}));
      });
    });
  });
}
