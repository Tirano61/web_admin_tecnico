class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;

  factory PagedResult.fromDynamic(
    dynamic body,
    T Function(Map<String, dynamic> json) mapper, {
    int fallbackPage = 1,
    int fallbackLimit = 10,
  }) {
    final root = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final rawItems = _extractItems(body);

    final items = rawItems
        .whereType<Map>()
        .map((raw) => mapper(Map<String, dynamic>.from(raw)))
        .toList();

    final meta = _extractMeta(root);
    final page = _parseInt(meta['page']) ?? _parseInt(root['page']) ?? fallbackPage;
    final limit = _parseInt(meta['limit']) ??
        _parseInt(meta['pageSize']) ??
        _parseInt(root['limit']) ??
        _parseInt(root['pageSize']) ??
        fallbackLimit;
    final total = _parseInt(meta['total']) ??
        _parseInt(meta['totalItems']) ??
        _parseInt(root['total']) ??
        _parseInt(root['count']) ??
        _parseInt(root['totalItems']) ??
        items.length;

    return PagedResult<T>(
      items: items,
      total: total,
      page: page,
      limit: limit,
    );
  }

  static List<dynamic> _extractItems(dynamic body) {
    if (body is List) {
      return body;
    }

    if (body is Map<String, dynamic>) {
      const keys = <String>['items', 'data', 'results', 'rows'];
      for (final key in keys) {
        final value = body[key];
        if (value is List) {
          return value;
        }
        if (value is Map<String, dynamic>) {
          for (final nestedKey in keys) {
            final nestedValue = value[nestedKey];
            if (nestedValue is List) {
              return nestedValue;
            }
          }
        }
      }
    }

    return const <dynamic>[];
  }

  static Map<String, dynamic> _extractMeta(Map<String, dynamic> root) {
    final meta = root['meta'];
    if (meta is Map<String, dynamic>) {
      return meta;
    }

    final pagination = root['pagination'];
    if (pagination is Map<String, dynamic>) {
      return pagination;
    }

    return const <String, dynamic>{};
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) {
      return value.toInt();
    }
    return null;
  }
}
