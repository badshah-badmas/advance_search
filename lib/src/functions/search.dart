import 'package:advanced_search/advanced_search.dart';
import 'package:advanced_search/src/model/search_result.dart';
import 'package:string_similarity/string_similarity.dart';

class SearchParameterModel<T> {
  List<T> searchList;
  String query;
  SearchSelector<T> searchSelector;
  SearchParameterModel(
      {required this.searchList,
      required this.query,
      required this.searchSelector});
}

class Search {
  static SearchResult execute<T>(SearchParameterModel<T> searchParameter) {
    List<T> searchList = searchParameter.searchList;
    String query = searchParameter.query;
    List<T> finalResult = [];
    List<T> startWithResult = [];
    List<T> containResult = [];
    List<T> deepContainResult = [];
    List<T> suggestedResult = [];
    if (query.isEmpty) {
      return SearchResult(
          exactMatch: searchList, suggestedResult: suggestedResult);
    }

    for (final T item in searchList) {
      if (searchParameter
          .searchSelector(item)
          .toLowerCase()
          .startsWith(query.toLowerCase())) {
        startWithResult.add(item);
      } else if (searchParameter
          .searchSelector(item)
          .toLowerCase()
          .contains(query.toLowerCase())) {
        containResult.add(item);
      } else if (_deepSearch(
          value: searchParameter.searchSelector(item), query: query)) {
        deepContainResult.add(item);
      } else if (searchParameter.searchSelector(item).similarityTo(query) >=
          0.3) {
        suggestedResult.add(item);
      }
    }

    finalResult = (startWithResult + containResult + deepContainResult);

    final SearchResult searchResult =
        SearchResult(exactMatch: finalResult, suggestedResult: suggestedResult);
    return searchResult;
  }

  static bool _deepSearch({required String value, required String query}) {
    if (!query.contains(' ')) {
      return false;
    }
    List<String> querySlice =
        query.split(' ').where((element) => element.isNotEmpty).toList();

    final bool result = querySlice.every(
      (element) {
        return value.toLowerCase().contains(element.toLowerCase());
      },
    );

    return result;
  }
}
