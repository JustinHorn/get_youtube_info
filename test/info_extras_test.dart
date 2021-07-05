// final expect = require('expect-diff');
// final fs = require('fs');
// final path = require('path');
// final sinon = require('sinon');
// final extras = require('../lib/info-extras');

import 'dart:convert';
import 'dart:io';

import 'package:get_youtube_info/get_youtube_info.dart';
import 'package:flutter_test/flutter_test.dart';

expectOk(dynamic x) => expect(nodeIsTruthy(x), true);
expectNotOk(dynamic x) => expect(nodeIsTruthy(x), false);

assertURL(url) {
  expect(RegExp('^https?://').hasMatch(url), true, reason: 'Not a URL: ${url}');
}

assertChannelURL(url) {
  expect(
      RegExp(r'^https?://www\.youtube\.com/channel/[a-zA-Z0-9_-]+$')
          .hasMatch(url),
      true,
      reason: 'Not a channel URL: ${url}');
}

assertUserID(str) {
  expect(RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(str), true,
      reason: 'Not a user id: ${str}');
}

assertUserName(str) {
  expect(RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(str), true,
      reason: 'Not a username: ${str}');
}

assertUserURL(url) {
  expect(
      RegExp(r'^https?://www\.youtube\.com/(user|channel)/[a-zA-Z0-9_-]+$')
          .hasMatch(url),
      true,
      reason: 'Not a user URL: ${url}');
}

assertThumbnails(thumbnails) {
  expect(thumbnails is List, true);
  for (var thumbnail in thumbnails) {
    assertURL(thumbnail['url']);
    expect(thumbnail['width'].runtimeType, 1.runtimeType);
    expect(thumbnail['height'].runtimeType, 1.runtimeType);
  }
}

assertRelatedVideos(relatedVideos, {assertRichThumbnails = false}) {
  expect(relatedVideos is List, true);
  expect(relatedVideos.length > 0, true);
  for (var video in relatedVideos) {
    expect(nodeIsTruthy(video['id']), true);
    expect(nodeIsTruthy(video['title']), true);
    expect(nodeIsTruthy(video['length_seconds']), true);
    assertThumbnails(video['thumbnails']);
    if (assertRichThumbnails) {
      expect(video['richThumbnails'].length > 0, true);
      assertThumbnails(video['richThumbnails']);
    }
    expect(video['isLive'].runtimeType, 'boolean');
    expectOk(RegExp('[a-zA-Z]+').hasMatch(video['author']));
    expectOk(nodeIsTruthy(video['author']?['id']));
    expectOk(nodeIsTruthy(video['author']?['name']));
    expectOk(nodeIsTruthy(video['author']?['channel_url']));
    assertThumbnails(video['author']['thumbnails']);
    expect(video['author']?['verified']?.runtimeType, 'boolean');
  }
}

Future<String> getFileString(String path) async {
  final fileString = await File(path).readAsString();
  return fileString;
}

Future<Map<String, dynamic>> getFileAsMap(String path) async {
  final fileString = await File(path).readAsString();
  final Map<String, dynamic> html5player = jsonDecode(fileString);
  return html5player;
}

Future<dynamic> infoFromWatchJSON(type, transformBody) async {
  var watchObj;
  if (nodeIsTruthy(transformBody)) {
    var watchJSON =
        await getFileString('./test/files/videos/${type}/watch.json');
    watchJSON = transformBody(watchJSON);
    watchObj = jsonDecode(watchJSON);
  } else {
    watchObj = await getFileAsMap('./test/files/videos/${type}/watch.json');
  }
  var info =
      (watchObj as List).fold({}, (Map part, curr) => ({...part, ...curr}));
  info['player_response'] =
      nodeOr(info['player_response'], info['playerResponse']);
  return info;
}

// extend expect with is okay function!

main() {
  // group('extras.getAuthor()', () {
  //   // To remove later.
  //   setUp(() {});
  //   tearDown(() {});

  //   test('Returns video author object', () async {
  //     final info =
  //         await getFileAsMap('./test/files/videos/regular/expected-info.json');
  //     final author = getAuthor(info);
  //     expect(nodeIsTruthy(author), true);
  //     assertURL(author['avatar']);
  //     assertThumbnails(author['thumbnails']);
  //     assertChannelURL(author['channel_url']);
  //     assertChannelURL(author['external_channel_url']);
  //     assertUserID(author['id']);
  //     assertUserName(author['user']);
  //     expect(nodeIsTruthy(author['name']), true);
  //     assertUserURL(author['user_url']);
  //     expect(author['verified'].runtimeType, true.runtimeType);
  //     expect(author['subscriber_count'].runtimeType, 1.runtimeType);
  //   });

  //   group('watch page without `playerMicroformatRenderer`', () {
  //     test('Uses backup author from `videoDetails`', () async {
  //       final _info = await infoFromWatchJSON('regular',
  //           (body) => body.replaceAll('playerMicroformatRenderer', ''));

  //       final info = Map<String, dynamic>.from(_info);
  //       final author = getAuthor(info);
  //       expect(nodeIsTruthy(author), true);
  //       expect(nodeIsTruthy(author['name']), true);
  //       assertChannelURL(author['channel_url']);
  //       assertThumbnails(author['thumbnails']);
  //       expect(author['verified'].runtimeType, true.runtimeType);
  //       expect(author['subscriber_count'].runtimeType, 1.runtimeType);
  //     });
  //   });

  //   group('watch page without `playerMicroformatRenderer` or `videoDetails`',
  //       () {
  //     test('Returns empty author object', () async {
  //       final _info = await infoFromWatchJSON(
  //           'regular',
  //           (body) => body
  //               .replaceAll('playerMicroformatRenderer', '')
  //               .replaceAll('videoDetails', ''));
  //       _info['player_response'] =
  //           nodeOr(_info['player_response'], _info['playerResponse']);
  //       final info = Map<String, dynamic>.from(_info);
  //       final author = getAuthor(info);
  //       expect(author, equals({}));
  //     });
  //   });

  //   group('from a rental', () {
  //     test('Returns video author object', () async {
  //       final info =
  //           await getFileAsMap('./test/files/videos/rental/expected-info.json');
  //       final author = getAuthor(info);
  //       expect(nodeIsTruthy(author), true);
  //       assertURL(author['avatar']);
  //       assertThumbnails(author['thumbnails']);
  //       assertChannelURL(author['channel_url']);
  //       assertChannelURL(author['external_channel_url']);
  //       assertUserID(author['id']);
  //       assertUserName(author['user']);
  //       expect(nodeIsTruthy(author['name']), true);
  //       assertUserURL(author['user_url']);
  //       expect(author['verified'].runtimeType, true.runtimeType);
  //       expect(nodeIsTruthy(author['subscriber_count']), false);
  //     });
  //   });
  // });

  group('extras.getMedia()', () {
    // test('Returns media object', () async {
    //   final _info =
    //       await getFileAsMap('./test/files/videos/music/expected-info.json');
    //   final info = Map<String, dynamic>.from(_info);
    //   final media = getMedia(info);
    //   expectOk(media);
    //   expect(media['artist'], 'Syn Cole');
    //   assertChannelURL(media['artist_url']);
    //   expect(media['category'], 'Music');
    //   assertURL(media['category_url']);
    // });

    group('On a video associated with a game', () {
      test('Returns media object', () async {
        final info =
            await getFileAsMap('./test/files/videos/game/expected-info.json');
        final media = getMedia(info);
        expectOk(media);
        expect(media['category'], 'Gaming');
        assertURL(media['category_url']);
        expect(media['game'], 'Pokémon Snap');
        assertURL(media['game_url']);
        expect(media['year'], '1999');
      });
    });

    group('With invalid input', () {
      test('Should return an empty object', () {
        final media = getMedia({'invalidObject': ''});
        expectOk(media);
        expect(media, equals({}));
      });
    });
  });

// group('extras.getRelatedVideos()', () {
//   // To remove later.
//   before(() => sinon.replace(console, 'warn', sinon.stub()));
//   after(() => sinon.restore());

//   test('Returns related videos', () {
//     final info = require('./files/videos/regular/expected-info.json');
//     assertRelatedVideos(extras.getRelatedVideos(info));
//   });

//   group('With richThumbnails', () {
//     test('Returns related videos', () {
//       final info = require('./files/videos/rich-thumbnails/expected-info.json');
//       assertRelatedVideos(extras.getRelatedVideos(info), true);
//     });
//   });

//   group('When able to choose the topic of related videos', () {
//     test('Returns related videos', () {
//       final info = require('./files/videos/related-topics/expected-info.json');
//       assertRelatedVideos(extras.getRelatedVideos(info));
//     });
//   });

//   group('Without `rvs` params', () {
//     test('Still able to find video params', () {
//       final info = require('./files/videos/regular/expected-info.json');
//       delete info.response.webWatchNextResponseExtensionData.relatedVideoArgs;
//       assertRelatedVideos(extras.getRelatedVideos(info));
//     });
//   });

//   group('Without `secondaryResults`', () {
//     test('Unable to find any videos', () {
//       final info = require('./files/videos/regular/expected-info.json');
//       delete info.response.contents.twoColumnWatchNextResults.secondaryResults.secondaryResults.results;
//       final relatedVideos = extras.getRelatedVideos(info);
//       expect(relatedVideos);
//       expect.deepEqual(relatedVideos, []);
//     });
//   });

//   group('With an unparseable video', () {
//     test('Catches errors', () {
//       final info = infoFromWatchJSON('regular', body => body.replace(/\bshortBylineText\b/g, '___'));
//       final relatedVideos = extras.getRelatedVideos(info);
//       expect.deepEqual(relatedVideos, []);
//     });
//   });
// });

// group('extras.getLikes()', () {
//   test('Returns like count', () {
//     final info = infoFromWatchJSON('regular');
//     final likes = extras.getLikes(info);
//     expect.strictEqual(typeof likes, 'number');
//   });

//   group('With no likes', () {
//     test('Does not return likes', () {
//       final info = infoFromWatchJSON('no-likes-or-dislikes');
//       final likes = extras.getLikes(info);
//       expect.strictEqual(likes, null);
//     });
//   });
// });

// group('extras.getDislikes()', () {
//   test('Returns dislike count', () {
//     final info = infoFromWatchJSON('regular');
//     final dislikes = extras.getDislikes(info);
//     expect.strictEqual(typeof dislikes, 'number');
//   });

//   group('With no dislikes', () {
//     test('Does not return dislikes', () {
//       final info = infoFromWatchJSON('no-likes-or-dislikes');
//       final dislikes = extras.getDislikes(info);
//       expect.strictEqual(dislikes, null);
//     });
//   });
// });

// group('extras.getStoryboards()', () {
//   test('Returns storyboards', () {
//     final info = infoFromWatchJSON('no-likes-or-dislikes');
//     final storyboards = extras.getStoryboards(info);

//     expect(Array.isArray(storyboards));
//     expect(storyboards.length > 0);

//     for (let storyboard of storyboards) {
//       assertURL(storyboard.templateUrl);
//       expect.strictEqual(typeof storyboard['thumbnailWidth'], 'number');
//       expect['strictEqual'](typeof storyboard['thumbnailHeight'], 'number');
//       expect['strictEqual'](typeof storyboard['thumbnailCount'], 'number');
//       expect['strictEqual'](typeof storyboard['interval'], 'number');
//       expect['strictEqual'](typeof storyboard['columns'], 'number');
//       expect['strictEqual'](typeof storyboard['rows'], 'number');
//       expect['strictEqual'](typeof storyboard['storyboardCount'], 'number');
//     }
//   });

//   group('With no storyboards', () {
//     test('Returns empty array', () {
//       final info = infoFromWatchJSON('regular');
//       final storyboards = extras.getStoryboards(info);
//       expect(Array.isArray(storyboards));
//       expect(storyboards.length === 0);
//     });
//   });
// });

// group('extras.getChapters()', () {
//   test('Returns chapters', () {
//     final info = require('./files/videos/chapters/expected-info.json');
//     final chapters = extras.getChapters(info);

//     expect(Array.isArray(chapters) && chapters.length);

//     for (final chapter of chapters) {
//       expect(chapter['title']);
//       expect['number'](chapter['start_time']);
//     }
//   });

//   group('With no chapters', () {
//     test('Returns empty array', () {
//       final info = infoFromWatchJSON('regular');
//       final chapters = extras.getChapters(info);

//       expect(Array.isArray(chapters) && !chapters.length);
//     });
//   });
// });
}
