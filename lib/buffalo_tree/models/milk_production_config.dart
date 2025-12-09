class MilkProductionConfig {
  static const double pricePerLiter = 100.0;
  
  static const Map<String, ProductionPeriod> productionSchedule = {
    'high': ProductionPeriod(months: 5, litersPerDay: 10), // Jan-May
    'medium': ProductionPeriod(months: 3, litersPerDay: 5), // Jun-Aug
    'rest': ProductionPeriod(months: 4, litersPerDay: 0), // Sep-Dec
  };
  
  static const int milkProductionStartAge = 3;
}

class ProductionPeriod {
  final int months;
  final double litersPerDay;
  
  const ProductionPeriod({
    required this.months,
    required this.litersPerDay,
  });
}

class YearlyMilkData {
  final int year;
  final int producingBuffaloes;
  final int nonProducingBuffaloes;
  final int totalBuffaloes;
  final double liters;
  final double revenue;
  
  const YearlyMilkData({
    required this.year,
    required this.producingBuffaloes,
    required this.nonProducingBuffaloes,
    required this.totalBuffaloes,
    required this.liters,
    required this.revenue,
  });
}

class MilkProductionResult {
  final List<YearlyMilkData> yearlyData;
  final double totalRevenue;
  final double totalLiters;
  final double averageAnnualRevenue;
  
  const MilkProductionResult({
    required this.yearlyData,
    required this.totalRevenue,
    required this.totalLiters,
    required this.averageAnnualRevenue,
  });
}
