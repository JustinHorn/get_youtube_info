part of get_youtube_info;

/// Get video ID.
///
/// There are a few type of video URL formats.
///  - https://www.youtube.com/watch?v=VIDEO_ID
///  - https://m.youtube.com/watch?v=VIDEO_ID
///  - https://youtu.be/VIDEO_ID
///  - https://www.youtube.com/v/VIDEO_ID
///  - https://www.youtube.com/embed/VIDEO_ID
///  - https://music.youtube.com/watch?v=VIDEO_ID
///  - https://gaming.youtube.com/watch?v=VIDEO_ID
///
/// @param {string} link
/// @return {string}
/// @throws {Error} If unable to find a id
/// @throws {TypeError} If videoid doesn't match specs
final validQueryDomains = Set<String>.from([
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'music.youtube.com',
  'gaming.youtube.com',
]);
final validPathDomains = RegExp(
    r"^https?:\/\/(youtu\.be\/|(www\.)?youtube.com\/(embed|v|shorts)\/)");
String Function(String link) getURLVideoID = (link) {
  final parsed = Uri.parse(link);
  var id = parsed.queryParameters['v'];
  if (validPathDomains.hasMatch(link) && id == null) {
    final paths = parsed.path.split('/');
    id = paths[paths.length - 1];
  } else if (parsed.host != '' && !validQueryDomains.contains(parsed.host)) {
    throw 'Not a YouTube domain';
  }
  if (id == null) {
    throw 'No video id found: $link';
  }
  id = id.substring(0, 11);
  if (!validateID(id)) {
    throw FormatException('Video id (${id}) does not match expected' +
        'format (${idRegex.toString()})');
  }
  return id;
};

/// Gets video ID either from a url or by checking if the given string
/// matches the video ID format.
///
/// @param {string} str
/// @returns {string}
/// @throws {Error} If unable to find a id
/// @throws {TypeError} If videoid doesn't match specs
final urlRegex = RegExp(r"^https?:\/\/");
String Function(String str) getVideoID = (str) {
  if (validateID(str)) {
    return str;
  } else if (urlRegex.hasMatch(str)) {
    return getURLVideoID(str);
  } else {
    throw 'No video id found: ${str}';
  }
};

/// Returns true if given id satifies YouTube's id format.
///
/// @param {string} id
/// @return {boolean}
final idRegex = RegExp(r'^[a-zA-Z0-9-_]{11}$');
final validateID = (String id) => idRegex.hasMatch(id);

/// Checks wether the input string includes a valid id.
///
/// @param {string} string
/// @returns {boolean}
bool Function(String string) validateURL = (String string) {
  try {
    getURLVideoID(string);
    return true;
  } catch (e) {
    return false;
  }
};
