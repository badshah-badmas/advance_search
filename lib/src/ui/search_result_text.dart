import 'package:advanced_search/src/model/highlight_index.dart';
import 'package:advanced_search/src/ui/search_view_parent.dart';
import 'package:flutter/material.dart';

class SearchResultText extends StatelessWidget {
  const SearchResultText(this.value,
      {super.key, this.textStyle, this.highlightTextStyle});

  final String value;
  final TextStyle? textStyle;
  final TextStyle? highlightTextStyle;

  @override
  Widget build(BuildContext context) {
    final String? query = SearchViewParent.of(context)?.searchController.query;
    final TextStyle textStyle = this.textStyle ?? const TextStyle();
    final TextStyle highlightTextStyle = this.highlightTextStyle ??
        const TextStyle(color: Colors.amber, backgroundColor: Colors.black26);
    return arrangeText(
      query: query ?? '',
      value: value,
      
      textStyle: textStyle,
      highlightTextStyle: highlightTextStyle,
    );
  }
}

Widget arrangeText({
  required String query,
  required String value,
  required TextStyle textStyle,
  required TextStyle highlightTextStyle,
}) {
  return RichText(
    text: TextSpan(
      children: textSpanGenerator(
        value: value,
        query: query,
        textStyle: textStyle,
        highlightTextStyle: highlightTextStyle,
      ),
    ),
  );
}

List<TextSpan> textSpanGenerator({
  required String value,
  required String query,
  required TextStyle textStyle,
  required TextStyle highlightTextStyle,
}) {
  List<TextSpan> result = [];

  final List<HighlightIndex> highlightIndex =
      manageIndex(value: value, query: query);

  if (highlightIndex.isEmpty) {
    return [TextSpan(text: value, style: textStyle)];
  }

  for (int index = 0; index < highlightIndex.length; index++) {
    if (index == 0) {
      const int startIndex = 0;
      final int endIndex = highlightIndex[index].startIndex;
      final String text = value.substring(startIndex, endIndex);
      result.add(TextSpan(text: text, style: textStyle));
    }
    final int startIndex = highlightIndex[index].startIndex;
    final int endIndex = highlightIndex[index].endIndex;
    final text = value.substring(startIndex, endIndex);
    result.add(TextSpan(text: text, style: highlightTextStyle));

    if (index + 1 < highlightIndex.length) {
      final int startIndex = highlightIndex[index].endIndex;
      final int endIndex = highlightIndex[index + 1].startIndex;
      final String text = value.substring(startIndex, endIndex);
      result.add(TextSpan(text: text, style: textStyle));
    } else {
      final int startIndex = highlightIndex[index].endIndex;
      final String text = value.substring(startIndex);
      result.add(TextSpan(text: text, style: textStyle));
    }
  }

  return result;
}

List<HighlightIndex> manageIndex(
    {required String value, required String query}) {
  List<HighlightIndex> substringIndexes = [];
  List<String> querySlice =
      query.split(' ').where((element) => element.isNotEmpty).toList();

  for (var e in querySlice) {
    if (!value.toLowerCase().contains(e.toLowerCase())) {
      continue;
    }
    final int startIndex = value.toLowerCase().indexOf(e.toLowerCase());
    final int endIndex = startIndex + e.length;
    final HighlightIndex highlightIndex =
        HighlightIndex(startIndex: startIndex, endIndex: endIndex);
    substringIndexes.add(highlightIndex);
  }

  substringIndexes.sort((a, b) {
    return a.startIndex.compareTo(b.startIndex);
  });

  return checkOverlaps(substringIndexes);
}

/// Function to check and merge overlapping ranges
List<HighlightIndex> checkOverlaps(List<HighlightIndex> highlightIndices) {
  if (highlightIndices.isEmpty) {
    return [];
  }

  // Sort the list by startIndex to ensure proper comparison
  highlightIndices.sort((a, b) => a.startIndex.compareTo(b.startIndex));

  List<HighlightIndex> result = [];
  HighlightIndex current = highlightIndices.first;

  for (int i = 1; i < highlightIndices.length; i++) {
    HighlightIndex next = highlightIndices[i];

    // Check if the current range overlaps with the next
    if (current.endIndex >= next.startIndex) {
      // Merge ranges
      current = HighlightIndex(
        startIndex: current.startIndex,
        endIndex: current.endIndex >= next.endIndex
            ? current.endIndex
            : next.endIndex,
      );
    } else {
      // No overlap, add the current range to the result and move to the next
      result.add(current);
      current = next;
    }
  }
  // Add the final merged range
  result.add(current);

  return result;
}
