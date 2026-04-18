List<int> buildRowsPerPageOptions(
  int rowsPerPage, {
  List<int> defaults = const <int>[6],
}) {
  final values = defaults.where((value) => value > 0).toSet();
  if (rowsPerPage > 0) {
    values.add(rowsPerPage);
  }
  final sorted = values.toList()..sort();
  if (sorted.isEmpty) {
    return const <int>[6];
  }
  return sorted;
}

int normalizeRowsPerPage(
  int rowsPerPage, {
  List<int> defaults = const <int>[6],
}) {
  final options = buildRowsPerPageOptions(rowsPerPage, defaults: defaults);
  if (rowsPerPage > 0 && options.contains(rowsPerPage)) {
    return rowsPerPage;
  }

  int closest = options.first;
  int minDiff = (rowsPerPage - closest).abs();
  for (final option in options.skip(1)) {
    final diff = (rowsPerPage - option).abs();
    if (diff < minDiff) {
      minDiff = diff;
      closest = option;
    }
  }
  return closest;
}