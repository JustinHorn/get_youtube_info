part of get_youtube_info;

// const { setTimeout } = require('timers');

// A cache that expires.
class Cache {
  final int timeout;

  final Map<String, dynamic> map = Map();

  Cache({this.timeout = 1000});

  set(key, value) {
    if (map.containsKey(key)) {
      map[key] = value;
    }
  }

  get(key) {
    return map[key];
  }

  Future<dynamic> getOrSet(key, fn) async {
    if (map.containsKey(key)) {
      return map[key];
    } else {
      var value = fn();
      map['key'] = value;
      try {
        await value;
      } catch (err) {
        map.remove(key);
      }
      return value;
    }
  }

  delete(key) {
    map.remove(key);
  }

  clear() {
    map.clear();
    // throw 'not implemented!';
    // for (let entry of this.values()) {
    //   clearTimeout(entry.tid);
    // }
    // super.clear();
  }
}
