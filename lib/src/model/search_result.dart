class SearchResult<T> {
  final List<T> exactMatch;
  final List<T> startWithResult;
  final List<T> containResult;
  final List<T> suggestedResult;

  SearchResult({
    this.exactMatch = const [],
    this.startWithResult = const [],
    this.containResult = const [],
    this.suggestedResult = const [],
  });

  /// Combined result in priority order
  List<T> get orderedMatches =>
      [...exactMatch, ...startWithResult, ...containResult];

  /// Suggestions (fuzzy results)
  List<T> get suggestions => suggestedResult;

  /// Returns a new merged result (does not mutate this)
  SearchResult<T> merge(SearchResult<T> other) {
    return SearchResult<T>(
      exactMatch: [...exactMatch, ...other.exactMatch],
      startWithResult: [...startWithResult, ...other.startWithResult],
      containResult: [...containResult, ...other.containResult],
      suggestedResult: [...suggestedResult, ...other.suggestedResult],
    );
  }

  @override
  String toString() {
    return 'SearchResult {\n'
        '  exactMatch: $exactMatch,\n'
        '  startWithResult: $startWithResult,\n'
        '  containResult: $containResult,\n'
        '  suggestedResult: $suggestedResult\n'
        '}';
  }
}
