import 'dart:convert';
import 'dart:io';

import 'package:get_youtube_info/get_youtube_info.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helper.dart';
import 'test_helper.dart';

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
    expect(video['isLive'].runtimeType, true.runtimeType);
    expectOk(video['author'] is String
        ? RegExp('[a-zA-Z]+').hasMatch(video['author'])
        : true);
    expectOk(nodeIsTruthy(video['author']?['id']));
    expectOk(nodeIsTruthy(video['author']?['name']));
    expectOk(nodeIsTruthy(video['author']?['channel_url']));
    assertThumbnails(video['author']['thumbnails']);
    expect(video['author']?['verified']?.runtimeType, true.runtimeType);
  }
}

Future<Map<String, dynamic>> infoFromWatchJSON(type, transformBody) async {
  var watchObj;
  if (nodeIsTruthy(transformBody)) {
    var watchJSON =
        await getFileAsString('./test/files/videos/$type/watch.json');
    watchJSON = transformBody(watchJSON);
    watchObj = jsonDecode(watchJSON);
  } else {
    watchObj = await getFileAsMapOrList('./test/files/videos/$type/watch.json');
  }
  var info =
      (watchObj as List).fold({}, (Map part, curr) => ({...part, ...curr}));
  info['player_response'] =
      nodeOr(info['player_response'], info['playerResponse']);
  return Map<String, dynamic>.from(info);
}

main() {
  group('extras.getAuthor()', () {
    // To remove later.
    setUp(() {});
    tearDown(() {});

    test('Returns video author object', () async {
      final info =
          await getFileAsMap('./test/files/videos/regular/expected-info.json');
      final author = getAuthor(info);
      expect(nodeIsTruthy(author), true);
      assertURL(author['avatar']);
      assertThumbnails(author['thumbnails']);
      assertChannelURL(author['channel_url']);
      assertChannelURL(author['external_channel_url']);
      assertUserID(author['id']);
      assertUserName(author['user']);
      expect(nodeIsTruthy(author['name']), true);
      assertUserURL(author['user_url']);
      expect(author['verified'].runtimeType, true.runtimeType);
      expect(author['subscriber_count'].runtimeType, 1.runtimeType);
    });

    group('watch page without `playerMicroformatRenderer`', () {
      test('Uses backup author from `videoDetails`', () async {
        final _info = await infoFromWatchJSON('regular',
            (body) => body.replaceAll('playerMicroformatRenderer', ''));

        final info = Map<String, dynamic>.from(_info);
        final author = getAuthor(info);
        expect(nodeIsTruthy(author), true);
        expect(nodeIsTruthy(author['name']), true);
        assertChannelURL(author['channel_url']);
        assertThumbnails(author['thumbnails']);
        expect(author['verified'].runtimeType, true.runtimeType);
        expect(author['subscriber_count'].runtimeType, 1.runtimeType);
      });
    });

    group('watch page without `playerMicroformatRenderer` or `videoDetails`',
        () {
      test('Returns empty author object', () async {
        final _info = await infoFromWatchJSON(
            'regular',
            (body) => body
                .replaceAll('playerMicroformatRenderer', '')
                .replaceAll('videoDetails', ''));
        _info['player_response'] =
            nodeOr(_info['player_response'], _info['playerResponse']);
        final info = Map<String, dynamic>.from(_info);
        final author = getAuthor(info);
        expect(author, equals({}));
      });
    });

    group('from a rental', () {
      test('Returns video author object', () async {
        final info =
            await getFileAsMap('./test/files/videos/rental/expected-info.json');
        final author = getAuthor(info);
        expect(nodeIsTruthy(author), true);
        assertURL(author['avatar']);
        assertThumbnails(author['thumbnails']);
        assertChannelURL(author['channel_url']);
        assertChannelURL(author['external_channel_url']);
        assertUserID(author['id']);
        assertUserName(author['user']);
        expect(nodeIsTruthy(author['name']), true);
        assertUserURL(author['user_url']);
        expect(author['verified'].runtimeType, true.runtimeType);
        expect(nodeIsTruthy(author['subscriber_count']), false);
      });
    });
  });

  group('extras.getMedia()', () {
    test('Returns media object', () async {
      final _info =
          await getFileAsMap('./test/files/videos/music/expected-info.json');
      final info = Map<String, dynamic>.from(_info);
      final media = getMedia(info);
      expectOk(media);
      expect(media['artist'], 'Syn Cole');
      assertChannelURL(media['artist_url']);
      expect(media['category'], 'Music');
      assertURL(media['category_url']);
    });

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

  group('extras.getRelatedVideos()', () {
    // To remove later.
    // before(() => sinon.replace(console, 'warn', sinon.stub()));
    // after(() => sinon.restore());

    // test('Returns related videos', () async {
    //   final info =
    //       await getFileAsMap('./test/files/videos/regular/expected-info.json');
    //   var relatedVideos = getRelatedVideos(info);
    //   assertRelatedVideos(relatedVideos);
    // });

    group('With richThumbnails', () {
      test('Returns related videos', () async {
        final info = await getFileAsMap(
            './test/files/videos/rich-thumbnails/expected-info.json');
        assertRelatedVideos(getRelatedVideos(info), assertRichThumbnails: true);
      });
    });

    group('When able to choose the topic of related videos', () {
      test('Returns related videos', () async {
        final info = await getFileAsMap(
            './test/files/videos/related-topics/expected-info.json');
        assertRelatedVideos(getRelatedVideos(info));
      });
    });

    group('Without `rvs` params', () {
      test('Still able to find video params', () async {
        final info = await getFileAsMap(
            './test/files/videos/regular/expected-info.json');
        (info['response']['webWatchNextResponseExtensionData'] as Map)
            .remove('relatedVideoArgs');
        assertRelatedVideos(getRelatedVideos(info));
      });
    });

    group('Without `secondaryResults`', () {
      test('Unable to find any videos', () async {
        final info = await getFileAsMap(
            './test/files/videos/regular/expected-info.json');
        (info['response']['contents']['twoColumnWatchNextResults']
                ['secondaryResults']['secondaryResults'] as Map)
            .remove('results');
        final relatedVideos = getRelatedVideos(info);
        expectOk(relatedVideos);
        expect(relatedVideos, equals([]));
      });
    });

    group('With an unparseable video', () {
      test('Catches errors', () async {
        final Map<String, dynamic> info = await infoFromWatchJSON('regular',
            (body) => body.replaceAll(RegExp(r"\bshortBylineText\b"), '___'));
        final relatedVideos = getRelatedVideos(info);
        expect(relatedVideos, equals([]));
      });
    });
  });

  group('extras.getLikes()', () {
    test('Returns like count', () async {
      final info = await infoFromWatchJSON('regular', null);
      final likes = getLikes(info);
      expect(likes.runtimeType, 1.runtimeType);
    });

    group('With no likes', () {
      test('Does not return likes', () async {
        final info = infoFromWatchJSON('no-likes-or-dislikes', null);
        final likes = getLikes(info);
        expect(likes, null);
      });
    });
  });

  group('extras.getDislikes()', () {
    test('Returns dislike count', () async {
      final info = await infoFromWatchJSON('regular', null);
      final dislikes = getDislikes(info);
      expect(dislikes.runtimeType, 1.runtimeType);
    });

    group('With no dislikes', () {
      test('Does not return dislikes', () async {
        final info = await infoFromWatchJSON('no-likes-or-dislikes', null);
        final dislikes = getDislikes(info);
        expect(dislikes, null);
      });
    });
  });

  expectNumber(dynamic d) {
    expect(d.runtimeType, 1.runtimeType);
  }

  group('extras.getStoryboards()', () {
    test('Returns storyboards', () async {
      final info = await infoFromWatchJSON('no-likes-or-dislikes', null);
      final storyboards = getStoryboards(info);

      expectOk(storyboards is List);
      expectOk(storyboards.length > 0);

      for (var storyboard in storyboards) {
        assertURL(storyboard['templateUrl']);
        expectNumber(storyboard['thumbnailWidth']);
        expectNumber(storyboard['thumbnailHeight']);
        expectNumber(storyboard['thumbnailCount']);
        expectNumber(storyboard['interval']);
        expectNumber(storyboard['columns']);
        expectNumber(storyboard['rows']);
        expectNumber(storyboard['storyboardCount']);
      }
    });

    group('With no storyboards', () {
      test('Returns empty array', () async {
        final info = await infoFromWatchJSON('regular', null);
        final storyboards = getStoryboards(info);
        expectOk((storyboards is List));
        expectOk(storyboards.length == 0);
      });
    });
  });

  group('extras.getChapters()', () {
    test('Returns chapters', () async {
      final info =
          await getFileAsMap('./test/files/videos/chapters/expected-info.json');
      final chapters = getChapters(info);

      expectOk(chapters is List && chapters.length > 0);

      for (final chapter in chapters) {
        expectOk(chapter['title']);
        expect(double.tryParse("${chapter['start_time']}").runtimeType,
            1.0.runtimeType);
      }
    });

    group('With no chapters', () {
      test('Returns empty array', () async {
        final info = await infoFromWatchJSON('regular', null);
        final chapters = getChapters(info);

        expectOk((chapters is List) && chapters.length == 0);
      });
    });
  });
}
