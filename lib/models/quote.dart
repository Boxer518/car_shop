class PriceQuote {
  const PriceQuote({
    required this.basePrice,
    required this.optionsTotal,
    required this.automaticPercent,
    required this.totalPercent,
    required this.finalPrice,
    required this.cap,
  });

  final int basePrice;
  final int optionsTotal;
  final int automaticPercent;
  final int totalPercent;
  final int finalPrice;
  final int cap;

  factory PriceQuote.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final value = json[key];
      if (value is num) {
        return value.round();
      }
      return int.tryParse('$value') ?? 0;
    }

    return PriceQuote(
      basePrice: read('basePrice'),
      optionsTotal: read('optionsTotal'),
      automaticPercent: read('automaticPercent'),
      totalPercent: read('totalPercent'),
      finalPrice: read('finalPrice'),
      cap: read('cap'),
    );
  }
}

class BrandSlice {
  const BrandSlice({
    required this.brand,
    required this.count,
    required this.sum,
  });

  final String brand;
  final int count;
  final int sum;

  factory BrandSlice.fromJson(Map<String, dynamic> json) {
    final count = json['count'];
    final sum = json['sum'];
    return BrandSlice(
      brand: '${json['brand'] ?? ''}',
      count: count is num ? count.round() : int.tryParse('$count') ?? 0,
      sum: sum is num ? sum.round() : int.tryParse('$sum') ?? 0,
    );
  }
}

class SalonReport {
  const SalonReport({
    required this.carsInStock,
    required this.carsReserved,
    required this.carsSold,
    required this.dealsCount,
    required this.dealsSum,
    required this.plannedDrives,
    required this.byBrand,
  });

  final int carsInStock;
  final int carsReserved;
  final int carsSold;
  final int dealsCount;
  final int dealsSum;
  final int plannedDrives;
  final List<BrandSlice> byBrand;

  factory SalonReport.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final value = json[key];
      if (value is num) {
        return value.round();
      }
      return int.tryParse('$value') ?? 0;
    }

    final rows = json['byBrand'];
    return SalonReport(
      carsInStock: read('carsInStock'),
      carsReserved: read('carsReserved'),
      carsSold: read('carsSold'),
      dealsCount: read('dealsCount'),
      dealsSum: read('dealsSum'),
      plannedDrives: read('plannedDrives'),
      byBrand: rows is List
          ? rows
                .whereType<Map>()
                .map(
                  (row) => BrandSlice.fromJson(Map<String, dynamic>.from(row)),
                )
                .toList()
          : const [],
    );
  }
}
