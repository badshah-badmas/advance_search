import 'package:advanced_search/advanced_search.dart';

class CustomSearchController<T> {
  void Function(String)? _searchCallback;
  void Function(SearchFilter searchFilter)? _filterCallback;
  String _query = '';

  void addSearchListener(void Function(String query) callback) {
    _searchCallback = callback;
  }

  void addFilterListener(void Function(SearchFilter searchFilter) callback) {
    _filterCallback = callback;
  }

  void search(String query) {
    _query = query;
    if (_searchCallback != null) _searchCallback!(query);
  }

  void applyFilter(SearchFilter filter) {
    if (_filterCallback != null) _filterCallback!(filter);
  }

  String get query => _query;
}
