class Paginated<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
