class ListQuery {
  const ListQuery({
    this.search = '',
    this.sort = 'id',
    this.descending = false,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
    this.filters = const {},
  });

  final String search;
  final String sort;
  final bool descending;
  final int page;
  final int size;
  final bool includeDeleted;
  final Map<String, String> filters;

  factory ListQuery.fromParameters(
    Map<String, String> parameters, {
    required String defaultSort,
    Set<String> allowedSorts = const {},
  }) {
    final rawSort = parameters['sort'] ?? '';
    final parts = rawSort.split(',');
    final field = parts.first;
    final sort = allowedSorts.contains(field) ? field : defaultSort;
    final size = int.tryParse(parameters['size'] ?? '') ?? 10;
    final page = int.tryParse(parameters['page'] ?? '') ?? 1;
    final filters = <String, String>{};
    parameters.forEach((key, value) {
      const reserved = {'search', 'sort', 'page', 'size', 'includeDeleted'};
      if (!reserved.contains(key) && value.isNotEmpty) {
        filters[key] = value;
      }
    });
    return ListQuery(
      search: parameters['search'] ?? '',
      sort: sort,
      descending: parts.length > 1 && parts[1] == 'desc',
      page: page < 1 ? 1 : page,
      size: size == 25 || size == 50 ? size : 10,
      includeDeleted: parameters['includeDeleted'] == '1',
      filters: filters,
    );
  }

  Map<String, String> toParameters() {
    final result = <String, String>{
      'sort': '$sort,${descending ? 'desc' : 'asc'}',
      'page': '$page',
      'size': '$size',
    };
    if (search.isNotEmpty) {
      result['search'] = search;
    }
    if (includeDeleted) {
      result['includeDeleted'] = '1';
    }
    filters.forEach((key, value) {
      if (value.isNotEmpty) {
        result[key] = value;
      }
    });
    return result;
  }

  ListQuery copyWith({
    String? search,
    String? sort,
    bool? descending,
    int? page,
    int? size,
    bool? includeDeleted,
    Map<String, String>? filters,
  }) {
    return ListQuery(
      search: search ?? this.search,
      sort: sort ?? this.sort,
      descending: descending ?? this.descending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
      filters: filters ?? this.filters,
    );
  }
}
