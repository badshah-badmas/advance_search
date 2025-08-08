import 'dart:async';

import 'package:flutter/material.dart';
import '../functions/controller.dart';
import 'package:advanced_search/src/functions/search.dart';
import 'package:advanced_search/src/model/search_result.dart';
import 'package:advanced_search/src/ui/search_view_parent.dart';

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
  final SearchSelector<T> searchStringSelector;
  final SearchFilter<T>? searchFilter;
  final List<T> items;

  @override
  State<SearchViewBuilder<T>> createState() => _SearchViewBuilder<T>();
}

class _SearchViewBuilder<T> extends State<SearchViewBuilder<T>> {
  bool isLoading = false;
  late SearchFilter<T> _searchFilter;
  late SearchResult<T> searchResult;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _searchFilter = widget.searchFilter ?? (_) => true;
    searchResult = SearchResult<T>(exactMatch: widget.items);

    widget.searchController.addSearchListener(_onSearchQueryChanged);
    widget.searchController.addFilterListener(_onFilterChanged);
    // widget.searchController.onCancel = _onCancel;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final result = await SearchService.instance.execute<T>(
        SearchParameterModel<T>(
          searchList: widget.items,
          query: query,
          searchSelector: widget.searchStringSelector,
        ),
      );

      if (mounted) {
        setState(() {
          isLoading = false;
          if (result != null) {
            searchResult = result;
          }
        });
      }
    });
  }

  void _onFilterChanged(SearchFilter<T> newFilter) {
    setState(() {
      _searchFilter = newFilter;
    });
  }


  SearchResult _applyFilter(SearchResult result) {
    final ordered =
        result.orderedMatches.whereType<T>().where(_searchFilter).toList();
    final suggested =
        result.suggestions.whereType<T>().where(_searchFilter).toList();

    return SearchResult(exactMatch: ordered, suggestedResult: suggested);
  }

  @override
  Widget build(BuildContext context) {
    return SearchViewParent(
      searchController: widget.searchController,
      child: widget.builder(
        context,
        isLoading,
        _applyFilter(searchResult),
      ),
    );
  }
}
