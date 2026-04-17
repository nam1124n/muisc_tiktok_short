String normalizeSearchText(String value) {
  var normalized = value.toLowerCase().trim();

  const replacements = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };

  replacements.forEach((replacement, chars) {
    normalized = normalized.replaceAll(RegExp('[$chars]'), replacement);
  });

  return normalized
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> tokenizeSearchInputs(Iterable<String> values) {
  final tokens = <String>[];
  final seen = <String>{};

  for (final value in values) {
    for (final token in normalizeSearchText(value).split(' ')) {
      if (token.isEmpty ||
          token.length < 2 ||
          _searchStopWords.contains(token)) {
        continue;
      }

      if (seen.add(token)) {
        tokens.add(token);
      }
    }
  }

  return tokens;
}

List<String> normalizeSearchPhrases(Iterable<String> values) {
  final phrases = <String>[];
  final seen = <String>{};

  for (final value in values) {
    final normalized = normalizeSearchText(value);
    if (normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    phrases.add(normalized);
  }

  return phrases;
}

const Set<String> _searchStopWords = {
  'bai',
  'cho',
  'gi',
  'hay',
  'hom',
  'kiem',
  'la',
  'listen',
  'mot',
  'muon',
  'music',
  'nay',
  'nao',
  'need',
  'nghe',
  'nhac',
  'song',
  'the',
  'thi',
  'tim',
  'today',
  'toi',
  'tui',
  'vao',
  'voi',
  'what',
  'xin',
};
