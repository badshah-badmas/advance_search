import 'package:advanced_search/advanced_search.dart';

class SearchResult<T>  {
  List<T> exactMatch;
  List<T> suggestedResult;
  SearchResult({required this.exactMatch, required this.suggestedResult});
}
