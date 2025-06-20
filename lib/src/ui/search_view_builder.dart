import 'package:advanced_search/src/functions/search.dart';
import 'package:advanced_search/src/model/search_result.dart';
import 'package:advanced_search/src/ui/search_view_parent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../functions/controller.dart';

typedef ViewBuilder = Widget Function(
  BuildContext context,
  bool isLoading,
  SearchResult searchResult,
);
typedef SearchSelector<T> = String Function(T value);
typedef SearchFilter<T> = bool Function(T value);

class SearchViewBuilder<T> extends StatefulWidget {
  const SearchViewBuilder({
    super.key,
    required this.searchController,
    required this.builder,
    required this.searchStringSelector,
    this.searchFilter,
    required this.items,
  });
  final CustomSearchController searchController;
  final ViewBuilder builder;
  final SearchSelector searchStringSelector;
  final SearchFilter? searchFilter;
  final T items;

  @override
  State<SearchViewBuilder> createState() => _SearchViewBuilder();

//   @override
//   bool updateShouldNotify(covariant InheritedWidget oldWidget) {
//     return false;
//   }

//   static CustomSearchBuilder of(BuildContext context) {
//     final CustomSearchBuilder? result =
//         context.dependOnInheritedWidgetOfExactType<CustomSearchBuilder>();
//     assert(
//         (result != null), 'No CustomSearchBuilder found in this widget tree');
//     return result!;
//   }
}

class _SearchViewBuilder extends State<SearchViewBuilder> {
  bool isLoading = false;
  SearchFilter? _searchFilter;
  SearchResult searchResult = SearchResult(exactMatch: [], suggestedResult: []);
  @override
  void initState() {
    _searchFilter = widget.searchFilter ?? (v) => true;
    searchResult = SearchResult(exactMatch: widget.items, suggestedResult: []);
    widget.searchController.addSearchListener(
      (query) async {
        if (mounted) {
          setState(() {
            isLoading = true;
          });
        }
        final SearchResult result =
            await compute<SearchParameterModel, SearchResult>(
          Search.execute,
          SearchParameterModel(
            searchList: widget.items,
            query: query,
            searchSelector: widget.searchStringSelector,
          ),
        );
        setState(() {
          isLoading = false;
          searchResult = result;
        });
      },
    );
    widget.searchController
        .addFilterListener((SearchFilter searchFilter) async {
      setState(() {
        _searchFilter = searchFilter;
      });
    });
    super.initState();
  }

  SearchResult applyFilter<T>(SearchResult result) {
    final List<T> exactMatch = result.exactMatch
        .where((element) => _searchFilter!(element))
        .toList() as List<T>;
    final List<T> suggestedResult = result.suggestedResult
        .where((element) => _searchFilter!(element))
        .toList() as List<T>;

    return SearchResult(
        exactMatch: exactMatch, suggestedResult: suggestedResult);
  }

  @override
  Widget build(BuildContext context) {
    return SearchViewParent(
        searchController: widget.searchController,
        child: widget.builder(context, isLoading, applyFilter(searchResult)));
  }
}
