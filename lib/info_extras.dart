part of get_youtube_info;

// const qs = require('querystring');
// const { parseTimestamp } = require('m3u8stream');

const BASE_URL = 'https://www.youtube.com/';
const BASE_URL_PATH = 'https://www.youtube.com/watch?v=';
const TITLE_TO_CATEGORY = {
  'song': {'name': 'Music', 'url': 'https://music.youtube.com/'},
};

final hourRegExp = RegExp(r'(\d{1,2}):(\d\d):(\d\d)');
final minuteRegExp = RegExp(r'(\d{1,2}):(\d\d)');
final secondsRegExp = RegExp(r'\d{1,2}');

int parseTimestamp(String timestamp) {
  if (hourRegExp.hasMatch(timestamp)) {
    var match = hourRegExp.firstMatch(timestamp);
    return ((int.parse(match![1]!) * 60 + int.parse(match[2]!)) * 60 +
            int.parse(match[3]!)) *
        1000;
  }

  if (minuteRegExp.hasMatch(timestamp)) {
    var match = minuteRegExp.firstMatch(timestamp);
    return (int.parse(match![1]!) * 60 + int.parse(match[2]!)) * 1000;
  }

  if (secondsRegExp.hasMatch(timestamp)) {
    var match = secondsRegExp.firstMatch(timestamp);
    return int.parse(match![0]!) * 1000;
  }
  throw 'no match for |$timestamp|';
}

final getText = (dynamic obj) => nodeIsTruthy(obj)
    ? nodeIsTruthy(obj['runs'])
        ? obj['runs'].first['text']
        : obj['simpleText']
    : null;

/// Get video media.
///
/// @param {Object} info
/// @returns {Object}
Map getMedia(Map<String, dynamic> info) {
  var media = {};
  var results = [];
  try {
    results = info['response']['contents']['twoColumnWatchNextResults']
        ['results']['results']['contents'];
  } catch (err) {
    // Do nothing
  }

  var result = results.firstWhere(
      (v) => nodeIsTruthy(v['videoSecondaryInfoRenderer']),
      orElse: () => null);
  if (!nodeIsTruthy(result)) {
    return {};
  }

  try {
    var metadataRows = nodeOr(
        result['metadataRowContainer'],
        result['videoSecondaryInfoRenderer']
            ['metadataRowContainer'])['metadataRowContainerRenderer']['rows'];
    for (var row in metadataRows) {
      if (nodeIsTruthy(row['metadataRowRenderer'])) {
        var title = getText(row['metadataRowRenderer']['title']).toLowerCase();
        var contents = row['metadataRowRenderer']['contents'].first;
        media[title] = getText(contents);
        var runs = contents['runs'];
        if (nodeIsTruthy(runs) &&
            nodeIsTruthy(runs.first['navigationEndpoint'])) {
          media['${title}_url'] = nodeURL(
              runs.first['navigationEndpoint']['commandMetadata']
                  ['webCommandMetadata']['url'],
              BASE_URL);
        }
        if (TITLE_TO_CATEGORY.containsKey(title)) {
          media['category'] = TITLE_TO_CATEGORY[title]!['name'];
          media['category_url'] = TITLE_TO_CATEGORY[title]!['url'];
        }
      } else if (nodeIsTruthy(row['richMetadataRowRenderer'])) {
        var contents = row['richMetadataRowRenderer']['contents'];
        var boxArt = contents
            .where((meta) =>
                meta['richMetadataRenderer']['style'] ==
                'RICH_METADATA_RENDERER_STYLE_BOX_ART')
            .toList();
        for (var box in boxArt) {
          var richMetadataRenderer = box['richMetadataRenderer'];
          var meta = richMetadataRenderer;
          media['year'] = getText(meta['subtitle']);
          var type = getText(meta['callToAction']).split(' ')[1];
          media[type] = getText(meta['title']);
          media['${type}_url'] = nodeURL(
              meta['endpoint']['commandMetadata']['webCommandMetadata']['url'],
              BASE_URL);
          media['thumbnails'] = meta['thumbnail']['thumbnails'];
        }
        var topic = (contents as List)
            .where((meta) =>
                meta['richMetadataRenderer']['style'] ==
                'RICH_METADATA_RENDERER_STYLE_TOPIC')
            .toList();
        for (var t in topic) {
          var meta = t['richMetadataRenderer'];
          media['category'] = getText(meta['title']);
          media['category_url'] = nodeURL(
              meta['endpoint']['commandMetadata']['webCommandMetadata']['url'],
              BASE_URL);
        }
      }
    }
  } catch (err) {
    // Do nothing.
  }

  return media;
}

final isVerified = (List? badges) => nodeIsTruthy(badges?.firstWhere(
    (b) => b['metadataBadgeRenderer']['tooltip'] == 'Verified',
    orElse: () => null));

/// Get video author.
///
/// @param {Object} info
/// @returns {Object}
getAuthor(Map<String, dynamic> info) {
  var channelId, thumbnails = [], subscriberCount, verified = false;
  try {
    var results = info['response']['contents']['twoColumnWatchNextResults']
        ['results']['results']['contents'] as List;
    var v = results.firstWhere((v2) => nodeIsTruthy(
        v2['videoSecondaryInfoRenderer']?['owner']?['videoOwnerRenderer']));
    var videoOwnerRenderer =
        v['videoSecondaryInfoRenderer']['owner']['videoOwnerRenderer'];
    channelId =
        videoOwnerRenderer['navigationEndpoint']['browseEndpoint']['browseId'];
    thumbnails = (videoOwnerRenderer['thumbnail']['thumbnails'] as List)
        .map((thumbnail) {
      thumbnail['url'] = nodeURL(thumbnail['url'], BASE_URL);
      return thumbnail;
    }).toList();
    subscriberCount = parseAbbreviatedNumber(
        getText(videoOwnerRenderer['subscriberCountText']));
    verified = isVerified(videoOwnerRenderer['badges']);
  } catch (err) {
    // Do nothing.
  }
  try {
    var videoDetails =
        info['player_response']['microformat']?['playerMicroformatRenderer'];
    var id = (nodeOr(nodeOr(videoDetails?['channelId'], channelId),
        info['player_response']['videoDetails']['channelId']));

    var videoDetailsExist = nodeIsTruthy(videoDetails);

    Map<String, dynamic> author = {
      'id': id,
      'name': videoDetailsExist
          ? videoDetails['ownerChannelName']
          : info['player_response']['videoDetails']['author'],
      'user': videoDetailsExist
          ? videoDetails['ownerProfileUrl'].split('/').last
          : null,
      'channel_url': 'https://www.youtube.com/channel/$id',
      'external_channel_url': videoDetailsExist
          ? 'https://www.youtube.com/channel/${videoDetails['externalChannelId']}'
          : '',
      'user_url': videoDetailsExist
          ? nodeURL(videoDetails['ownerProfileUrl'], BASE_URL).toString()
          : '',
      'thumbnails': thumbnails,
      'verified': verified,
      'subscriber_count': subscriberCount,
    };
    if (nodeIsTruthy(thumbnails.length)) {
      author['avatar'] = author['thumbnails'].first['url'];
      // deprecate(autho['avatar'] = author['thumbnails'].first['url'],
      //     'author.avatar', 'author.thumbnails[0].url');
    }
    return author;
  } catch (err) {
    return {};
  }
}

parseRelatedVideo(details, rvsParams) {
  if (!nodeIsTruthy(details)) return;
  try {
    var viewCount = getText(details['viewCountText']);
    var shortViewCount = getText(details['shortViewCountText']);
    var rvsDetails = rvsParams.firstWhere(
        (elem) => elem['id'] == details['videoId'],
        orElse: () => null);

    if (!RegExp('^\d').hasMatch(shortViewCount)) {
      shortViewCount = rvsDetails?['short_view_count_text'] ?? '';
    }
    viewCount = (RegExp('^\d').hasMatch(viewCount) ? viewCount : shortViewCount)
        .split(' ')
        .first;
    var browseEndpoint = details['shortBylineText']['runs']
        .first['navigationEndpoint']['browseEndpoint'];
    var channelId = browseEndpoint['browseId'];
    var name = getText(details['shortBylineText']);
    var user = (browseEndpoint?['canonicalBaseUrl'] ?? '').split('/').last;
    Map<String, dynamic> video = {
      'id': details['videoId'],
      'title': getText(details['title']),
      'published': getText(details['publishedTimeText']),
      'author': {
        'id': channelId,
        'name': name,
        'user': user,
        'channel_url': 'https://www.youtube.com/channel/$channelId',
        'user_url': 'https://www.youtube.com/user/$user',
        'thumbnails':
            details['channelThumbnail']['thumbnails'].map((thumbnail) {
          thumbnail['url'] = nodeURL(thumbnail['url'], BASE_URL);
          return thumbnail;
        }).toList(),
        'verified': isVerified(details['ownerBadges']),

        // [Symbol.toPrimitive]() {
        //   console.warn(`\`relatedVideo.author\` will be removed in a near future release, ` +
        //     `use \`relatedVideo.author.name\` instead.`);
        //   return video['author']['name'];
        // },
      },
      'short_view_count_text': shortViewCount.split(' ').first,
      'view_count': viewCount.replaceAll(',', ''),
      'length_seconds': nodeIsTruthy(details['lengthText'])
          ? ((parseTimestamp(getText(details['lengthText'])) / 1000)).round()
          : rvsParams?['length_seconds']?.toString() ?? '',
      'thumbnails': details['thumbnail']['thumbnails'],
      'richThumbnails': nodeIsTruthy(details['richThumbnail'])
          ? details['richThumbnail']['movingThumbnailRenderer']
              ['movingThumbnailDetails']['thumbnails']
          : [],
      'isLive': (details['badges'] != null &&
          details['badges'].firstWhere(
                  (b) => b['metadataBadgeRenderer']?['label'] == 'LIVE NOW',
                  orElse: () => null) !=
              null),
    };

    // deprecate(video, 'author_thumbnail', video.author.thumbnails[0].url,
    //   'relatedVideo.author_thumbnail', 'relatedVideo.author.thumbnails[0].url');
    // deprecate(video, 'ucid', video.author.id, 'relatedVideo.ucid', 'relatedVideo.author.id');
    // deprecate(video, 'video_thumbnail', video.thumbnails[0].url,
    //   'relatedVideo.video_thumbnail', 'relatedVideo.thumbnails[0].url');
    return video;
  } catch (err) {
    // Skip.
  }
}

/// Get related videos.
///
/// @param {Object} info
/// @returns {Array.<Object>}
getRelatedVideos(Map<String, dynamic> info) {
  var rvsParams = [], secondaryResults = [];
  try {
    rvsParams = info['response']['webWatchNextResponseExtensionData']
            ['relatedVideoArgs']
        .split(',')
        .map((e) => QueryString.parse(e))
        .toList();
  } catch (err) {
    // Do nothing.
  }
  try {
    secondaryResults = info['response']['contents']['twoColumnWatchNextResults']
        ['secondaryResults']['secondaryResults']['results'];
  } catch (err) {
    return [];
  }
  var videos = [];
  for (var result in secondaryResults) {
    var details = result['compactVideoRenderer'];
    if (nodeIsTruthy(details)) {
      var video = parseRelatedVideo(details, rvsParams);
      if (nodeIsTruthy(video)) videos.add(video);
    } else {
      var autoplay = nodeOr(
          result['compactAutoplayRenderer'], result['itemSectionRenderer']);
      if (autoplay == null || autoplay['contents'] is! List) continue;
      for (var content in autoplay['contents']) {
        var video =
            parseRelatedVideo(content['compactVideoRenderer'], rvsParams);
        if (nodeIsTruthy(video)) videos.add(video);
      }
    }
  }
  return videos;
}

/// Get like count.
///
/// @param {Object} info
/// @returns {number}
int? getLikes(info) {
  try {
    var contents = info['response']['contents']['twoColumnWatchNextResults']
        ['results']['results']['contents'];
    var video =
        contents.firstWhere((r) => nodeIsTruthy(r['videoPrimaryInfoRenderer']));
    var buttons = video['videoPrimaryInfoRenderer']['videoActions']
        ['menuRenderer']['topLevelButtons'];
    var like = buttons.firstWhere(
        (b) => b['toggleButtonRenderer']?['defaultIcon']['iconType'] == 'LIKE');
    return int.parse(like['toggleButtonRenderer']['defaultText']
            ['accessibility']['accessibilityData']['label']
        .replaceAll(RegExp(r'\D+'), ''));
  } catch (err) {
    return null;
  }
}

/// Get dislike count.
///
/// @param {Object} info
/// @returns {number}
int? getDislikes(info) {
  try {
    var contents = info['response']['contents']['twoColumnWatchNextResults']
        ['results']['results']['contents'];
    var video =
        contents.firstWhere((r) => nodeIsTruthy(r['videoPrimaryInfoRenderer']));
    var buttons = video['videoPrimaryInfoRenderer']['videoActions']
        ['menuRenderer']['topLevelButtons'];
    var dislike = buttons.firstWhere((b) =>
        b['toggleButtonRenderer']?['defaultIcon']['iconType'] == 'DISLIKE');
    return int.parse(dislike['toggleButtonRenderer']['defaultText']
            ['accessibility']['accessibilityData']['label']
        .replaceAll(RegExp(r'\D+'), ''));
  } catch (err) {
    return null;
  }
}

/// Cleans up a few fields on `videoDetails`.
///
/// @param {Object} videoDetails
/// @param {Object} info
/// @returns {Object}
cleanVideoDetails(Map<String, dynamic> videoDetails, info) {
  videoDetails['thumbnails'] = videoDetails['thumbnail']['thumbnails'];
  videoDetails.remove('thumbnail');
  // utils.deprecate(videoDetails, 'thumbnail', { thumbnails: videoDetails.thumbnails },
  //   'videoDetails.thumbnail.thumbnails', 'videoDetails.thumbnails');
  videoDetails['description'] = nodeOr(
      videoDetails['shortDescription'], getText(videoDetails['description']));
  videoDetails.remove('shortDescription');
  // utils.deprecate(videoDetails, 'shortDescription', videoDetails.description,
  //   'videoDetails.shortDescription', 'videoDetails.description');

  // Use more reliable `lengthSeconds` from `playerMicroformatRenderer`.
  videoDetails['lengthSeconds'] = info['player_response']['microformat']
      ?['playerMicroformatRenderer']['lengthSeconds'];
  return videoDetails;
}

/// Get storyboards info.
///
/// @param {Object} info
/// @returns {Array.<Object>}
getStoryboards(Map<String, dynamic> info) {
  final List? parts = info['player_response']['storyboards']
          ?['playerStoryboardSpecRenderer']?['spec']
      ?.split('|');

  if (parts == null) return [];
  var url = Uri.parse(parts.first);

  parts.removeAt(0);

  return parts.mapIndexed((part, i) {
    var propList = part.split('#');

    var thumbnailWidth = propList[0],
        thumbnailHeight = propList[1],
        thumbnailCount = propList[2],
        columns = propList[3],
        rows = propList[4],
        interval = propList[5],
        nameReplacement = propList[6],
        sigh = propList[7];

    url = Uri(
        scheme: url.scheme,
        path: url.path,
        queryParameters: {
          ...url.queryParameters,
          ...{'sigh': sigh},
        },
        fragment: url.fragment,
        host: url.host,
        port: url.port);

    //set('sigh', sigh);

    thumbnailCount = int.parse(thumbnailCount);
    columns = int.parse(columns);
    rows = int.parse(rows);

    final storyboardCount =
        ((thumbnailCount / (columns * rows)) as double).ceil();

    return {
      'templateUrl': url
          .toString()
          .replaceAll(r'$L', i.toString())
          .replaceAll(r'$N', nameReplacement.toString()),
      'thumbnailWidth': int.parse(thumbnailWidth),
      'thumbnailHeight': int.parse(thumbnailHeight),
      'thumbnailCount': thumbnailCount,
      'interval': int.parse(interval),
      'columns': columns,
      'rows': rows,
      'storyboardCount': storyboardCount,
    };
  }).toList();
}

/// Get chapters info.
///
/// @param {Object} info
/// @returns {Array.<Object>}
getChapters(info) {
  final playerOverlayRenderer =
      info['response']?['playerOverlays']?['playerOverlayRenderer'];
  final playerBar = playerOverlayRenderer?['decoratedPlayerBarRenderer']
      ?['decoratedPlayerBarRenderer']?['playerBar'];
  final markersMap = playerBar?['multiMarkersPlayerBarRenderer']?['markersMap'];
  final marker = markersMap is List
      ? markersMap.firstWhere(
          (m) => nodeIsTruthy(m['value']) && m['value']['chapters'] is List)
      : null;
  if (!nodeIsTruthy(marker)) return [];
  final chapters = marker['value']['chapters'];

  return chapters
      .map((chapter) => ({
            'title': getText(chapter?['chapterRenderer']?['title']),
            'start_time':
                chapter?['chapterRenderer']?['timeRangeStartMillis'] / 1000,
          }))
      .toList();
}
