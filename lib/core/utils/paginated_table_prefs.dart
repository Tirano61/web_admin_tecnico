List<int> buildRowsPerPageOptions(
  int rowsPerPage, {
  List<int> defaults = const <int>[6],
}) {
  final values = defaults.where((value) => value > 0).toSet().toList()..sort();
  if (values.isEmpty) {
    return const <int>[6];
  }
  return values;
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