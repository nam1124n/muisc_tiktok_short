import 'package:login_flutter/app/utils/search_text_normalizer.dart';

class SongMetadataSuggestion {
  final List<String> semanticTags;
  final int? energyLevel;
  final List<String> matchedRules;

  const SongMetadataSuggestion({
    required this.semanticTags,
    required this.energyLevel,
    required this.matchedRules,
  });

  bool get hasData => semanticTags.isNotEmpty || energyLevel != null;
}

SongMetadataSuggestion inferBasicSongMetadata({
  required String title,
  required String artist,
}) {
  final source = normalizeSearchText('$title $artist');
  final tags = <String>[];
  final matchedRules = <String>[];

  void addTags(String ruleName, List<String> values) {
    var added = false;
    for (final value in values) {
      if (!tags.contains(value)) {
        tags.add(value);
        added = true;
      }
    }
    if (added) {
      matchedRules.add(ruleName);
    }
  }

  if (_containsAny(source, _lofiSignals)) {
    addTags('lofi', ['lofi', 'chill', 'study']);
  }

  if (_containsAny(source, _chillSignals)) {
    addTags('chill', ['chill', 'thư giãn']);
  }

  if (_containsAny(source, _healingSignals)) {
    addTags('healing', ['healing', 'nhẹ nhàng']);
  }

  if (_containsAny(source, _sadSignals)) {
    addTags('sad', ['buồn', 'tâm trạng', 'ballad']);
  }

  if (_containsAny(source, _heartbreakSignals)) {
    addTags('heartbreak', ['thất tình', 'buồn']);
  }

  if (_containsAny(source, _nightSignals)) {
    addTags('night', ['đêm']);
  }

  if (_containsAny(source, _rainSignals)) {
    addTags('rain', ['mưa']);
  }

  if (_containsAny(source, _acousticSignals)) {
    addTags('acoustic', ['acoustic', 'nhẹ nhàng']);
  }

  if (_containsAny(source, _loveSignals)) {
    addTags('love', ['tình yêu']);
  }

  if (_containsAny(source, _happySignals)) {
    addTags('happy', ['vui', 'pop']);
  }

  if (_containsAny(source, _rapSignals)) {
    addTags('rap', ['rap']);
  }

  if (_containsAny(source, _danceSignals)) {
    addTags('dance', ['dance', 'sôi động']);
  }

  if (_containsAny(source, _edmSignals)) {
    addTags('edm', ['edm', 'sôi động']);
  }

  if (_containsAny(source, _trendSignals)) {
    addTags('trend', ['tiktok', 'trend']);
  }

  if (_containsAny(source, _remixSignals)) {
    addTags('remix', ['remix']);
  }

  if (_containsAny(source, _djSignals)) {
    addTags('dj', ['remix', 'sôi động']);
  }

  if (tags.isEmpty) {
    return const SongMetadataSuggestion(
      semanticTags: [],
      energyLevel: null,
      matchedRules: [],
    );
  }

  return SongMetadataSuggestion(
    semanticTags: tags,
    energyLevel: _inferEnergyFromTags(tags),
    matchedRules: matchedRules,
  );
}

bool _containsAny(String source, Set<String> phrases) {
  for (final phrase in phrases) {
    if (source.contains(phrase)) {
      return true;
    }
  }
  return false;
}

int _inferEnergyFromTags(List<String> tags) {
  if (_hasAnyTag(tags, const {'edm', 'dance', 'remix', 'sôi động', 'tiktok'})) {
    return 5;
  }

  if (_hasAnyTag(tags, const {'rap', 'vui', 'trend'})) {
    return 4;
  }

  if (_hasAnyTag(tags, const {
    'lofi',
    'chill',
    'study',
    'healing',
    'thư giãn',
  })) {
    return 1;
  }

  if (_hasAnyTag(tags, const {'buồn', 'thất tình', 'ballad', 'tâm trạng'})) {
    return 2;
  }

  return 3;
}

bool _hasAnyTag(List<String> tags, Set<String> candidates) {
  for (final tag in tags) {
    if (candidates.contains(tag)) {
      return true;
    }
  }
  return false;
}

const Set<String> _lofiSignals = {'lofi', 'study', 'study beat', 'tap trung'};

const Set<String> _chillSignals = {'chill', 'relax', 'thu gian', 'soft'};

const Set<String> _healingSignals = {
  'healing',
  'yen binh',
  'nhe nhang',
  'piano',
  'instrumental',
};

const Set<String> _sadSignals = {
  'buon',
  'co don',
  'tam trang',
  'sau',
  'lang le',
  'noi dau',
  'tuyet vong',
};

const Set<String> _heartbreakSignals = {
  'that tinh',
  'chia tay',
  'don phuong',
  'khoc',
  'nuoc mat',
  'tan vo',
  'vo tan',
};

const Set<String> _nightSignals = {'dem', 'midnight', 'night', 'moon'};

const Set<String> _rainSignals = {'mua', 'rain', 'storm'};

const Set<String> _acousticSignals = {
  'acoustic',
  'guitar',
  'piano version',
  'live session',
};

const Set<String> _loveSignals = {'tinh yeu', 'love', 'yeu', 'crush', 'thuong'};

const Set<String> _happySignals = {
  'happy',
  'vui',
  'summer',
  'yeu doi',
  'xinh',
  'cute',
};

const Set<String> _rapSignals = {'rap', 'hip hop', 'hiphop', 'trap', 'drill'};

const Set<String> _danceSignals = {'dance', 'party', 'quay', 'club'};

const Set<String> _edmSignals = {'edm', 'vinahouse', 'house', 'bass', 'drop'};

const Set<String> _trendSignals = {'tiktok', 'trend', 'viral', 'capcut'};

const Set<String> _remixSignals = {
  'remix',
  'sped up',
  'speed up',
  'nightcore',
  'mashup',
};

const Set<String> _djSignals = {'dj'};
