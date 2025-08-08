import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show max, min;

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

class SearchIsolateParams<T> {
  final String query;
  final SendPort sendPort;
  final List<T> items;
  final SearchSelector<T> searchSelector;
  SearchIsolateParams({
    required this.query,
    required this.sendPort,
    required this.items,
    required this.searchSelector,
  });
}

class SearchService {
  static final instance = SearchService();

  final Map<String, List<Isolate>> _isolates = {};
  final Map<String, List<ReceivePort>> _receivePorts = {};
  // final Map<String, List<Completer<SearchResult>>> _pendingSearches = {};

  Future<SearchResult<T>?> execute<T>(SearchParameterModel<T> params) async {
    try {
      final result = await _search<T>(params);
      return result;
    } catch (e) {
      if (e == 'Search cancelled') return null;
      rethrow;
    }
  }

  Future<SearchResult<T>> _search<T>(SearchParameterModel<T> params) async {
    final query = params.query.trim().toLowerCase();
    final searchList = params.searchList;
    final cpu = max(Platform.numberOfProcessors - 1, 1);
    final chunkSize = (searchList.length / cpu).ceil();

    final List<Future<SearchResult<T>>> futures = [];
    final List<Isolate> newIsolates = [];
    // _pendingSearches.clear();

    for (int i = 0; i < cpu; i++) {
      final start = i * chunkSize;
      final end = min((i + 1) * chunkSize, searchList.length);
      if (start >= end) break;

      final chunk = searchList.sublist(start, end);
      final receivePort = ReceivePort();
      final completer = Completer<SearchResult<T>>();
      // _pendingSearches.addAll( completer);

      final ports = _receivePorts[query] ?? [];
      ports.add(receivePort);
      _receivePorts.addAll({query: ports});
      dispose(query);
      final isolate = await Isolate.spawn(
        _searchEntryPoint<T>,
        SearchIsolateParams<T>(
          query: query,
          sendPort: receivePort.sendPort,
          items: chunk,
          searchSelector: params.searchSelector,
        ),
        // onError: receivePort.sendPort,
        // onExit: receivePort.sendPort,
      );

      newIsolates.add(isolate);

      receivePort.listen((message) {
        if (message is SearchResult<T> && !completer.isCompleted) {
          completer.complete(message);
        } else if (message is Error || message is String) {
          if (!completer.isCompleted) completer.completeError(message);
        }
      });

      futures.add(completer.future);
    }

    _isolates.addAll({query: newIsolates});

    try {
      final result = await Future.wait(futures);

      SearchResult<T> finalResult = SearchResult<T>(exactMatch: []);
      for (final r in result) {
        finalResult = finalResult.merge(r);
      }
      return finalResult;
    } finally {
      for (final isolate in newIsolates) {
        isolate.kill(priority: Isolate.immediate);
      }
      _isolates.remove(query);
      _receivePorts.remove(query);
      // _pendingSearches.clear();
    }
  }

  void dispose(String query) {
    if (_isolates.containsKey(query)) {
      _isolates.entries.map(
        (e) {
          if (e.key != query) {
            e.value.map(
              (e) => e.kill(priority: Isolate.immediate),
            );
            _isolates.remove(e.key);
          }
        },
      );
    } else {
      _isolates.values.map(
        (e) {
          e.map(
            (e) => e.kill(priority: Isolate.immediate),
          );
        },
      );
      _isolates.clear();
    }
    if (_receivePorts.containsKey(query)) {
      _receivePorts.entries.map(
        (e) {
          if (e.key != query) {
            e.value.map(
              (e) => e.close(),
            );
            _receivePorts.remove(e.key);
          }
        },
      );
    } else {
      _receivePorts.values.map(
        (e) {
          e.map(
            (e) => e.close(),
          );
        },
      );
      _receivePorts.clear();
    }

    // // Important: complete all pending completers
    // for (final completer in _pendingSearches) {
    //   if (!completer.isCompleted) {
    //     completer.complete(SearchResult(exactMatch: [])); // or completeError
    //   }
    // }
    // _pendingSearches.clear();

    // if (_currentSearchCompleter?.isCompleted == false) {
    //   _currentSearchCompleter?.completeError('Search cancelled');
    // }
    // _currentSearchCompleter = null;
  }
}

void _searchEntryPoint<T>(SearchIsolateParams<T> params) {
  final query = params.query;
  final queryWithRegEx =
      params.query.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
  final items = params.items;

  if (query.isEmpty) {
    params.sendPort.send(SearchResult(exactMatch: items));
    return;
  }

  final exactMatch = <T>[];
  final startWithResult = <T>[];
  final containResult = <T>[];
  final suggestedResult = <T>[];
  for (final item in items) {
    // log('loop ${params.loop} ->query: ${params.query}');
    final itemValue = params.searchSelector(item).trim().toLowerCase();
    if (itemValue == query) {
      exactMatch.add(item);
      continue;
    }
    if (itemValue.startsWith(query)) {
      startWithResult.add(item);
      continue;
    }
    if (itemValue.contains(query)) {
      containResult.add(item);
      continue;
    }
    if (itemValue.similarityTo(query) >= 0.5 ||
        itemValue
            .replaceAll(RegExp(r'[^\p{L}]', unicode: true), '')
            .contains(queryWithRegEx)) {
      suggestedResult.add(item);
    }
  }
  params.sendPort.send(SearchResult(
    exactMatch: exactMatch,
    startWithResult: startWithResult,
    containResult: containResult,
    suggestedResult: suggestedResult,
  ));
}
