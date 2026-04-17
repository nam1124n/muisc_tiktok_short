class SearchPlanEntity {
  final String originalQuery;
  final List<String> keywords;
  final List<String> artistHints;
  final List<String> titleHints;
  final List<String> tagHints;
  final String provider;
  final String reason;

  const SearchPlanEntity({
    required this.originalQuery,
    required this.keywords,
    required this.artistHints,
    required this.titleHints,
    required this.tagHints,
    required this.provider,
    required this.reason,
  });
}
