import 'package:advanced_search/advanced_search.dart';
import 'package:flutter/material.dart';

class SearchViewParent extends InheritedWidget {
  const SearchViewParent(
      {super.key, required super.child, required this.searchController});
  final CustomSearchController searchController;

  static SearchViewParent? of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<SearchViewParent>();
    assert(result != null, 'No SearchViewBuilder found in context');
    return result;
  }

  @override
  bool updateShouldNotify(covariant SearchViewParent oldWidget) {
    return oldWidget.searchController != searchController;
  }
}
