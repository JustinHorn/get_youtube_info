import 'package:flutter_test/flutter_test.dart';

import 'package:get_youtube_info/get_youtube_info.dart';

void main() {
  group('utils ', () {
    test('exposed miniget', () async {
      final req = exposedMiniget('https://test.com/', options: {});
      await req;
    });
  });

  group('url-utils', () {
    test('getVideoID', () {
      var id;
      id = getVideoID('http://www.youtube.com/watch?v=RAW_VIDEOID');
      expect(id, equals('RAW_VIDEOID'));
      id = getVideoID('http://youtu.be/RAW_VIDEOID');
      expect(id, equals('RAW_VIDEOID'));
      id = getVideoID('http://youtube.com/v/RAW_VIDEOID');
      expect(id, equals('RAW_VIDEOID'));
      id = getVideoID('http://youtube.com/embed/RAW_VIDEOID');
      expect(id, equals('RAW_VIDEOID'));
      id = getVideoID('http://youtube.com/shorts/RAW_VIDEOID');
      expect(id, equals('RAW_VIDEOID'));
      id = getVideoID(
        'https://music.youtube.com/watch?v=RAW_VIDEOID&list=RDAMVMmtLgabce8KQ',
      );
      expect(id, equals('RAW_VIDEOID'));
      id = getVideoID('https://gaming.youtube.com/watch?v=RAW_VIDEOID');
      expect(id, equals('RAW_VIDEOID'));

      expect(
        () => getVideoID('https://any.youtube.com/watch?v=RAW_VIDEOID'),
        throwsA('Not a YouTube domain'),
      );
      expect(
        () => getVideoID('https://www.twitch.tv/user/v/1234'),
        throwsA('Not a YouTube domain'),
      );
      expect(
        () => getVideoID('www.youtube.com'),
        throwsA('No video id found: www.youtube.com'),
      );
      expect(
        () => getVideoID('http://www.youtube.com/playlist?list=1337'),
        throwsA('No video id found: http://www.youtube.com/playlist?list=1337'),
      );
      expect(
        () => getVideoID('http://www.youtube.com/watch?v=asdf\$%^ddf-'),
        throwsFormatException,
      );
    });
  });
}
