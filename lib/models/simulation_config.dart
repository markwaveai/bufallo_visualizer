import 'dart:convert';
import 'package:flutter/services.dart';

class SimulationConfig {
  final double defaultUnits;
  final int defaultYears;
  final int defaultStartYear;
  final int defaultStartMonth;
  final int defaultStartDay;
  final double milkPrice;
  final double feedingCostPerDay;
  final double otherCostPerDay;
  final double cpfMonthlyCost;
  final int cpfAgeThresholdMonths;
  final int milkingStartAgeMonths;
  final int maturityAgeYears;
  final int motherAgeYears;
  final Map<String, RevenuePhase> revenuePhases;
  final InitialBuffaloesConfig initialBuffaloesPerUnit;
  final Map<int, double> assetValues;

  SimulationConfig({
    required this.defaultUnits,
    required this.defaultYears,
    required this.defaultStartYear,
    required this.defaultStartMonth,
    required this.defaultStartDay,
    required this.milkPrice,
    required this.feedingCostPerDay,
    required this.otherCostPerDay,
    required this.cpfMonthlyCost,
    required this.cpfAgeThresholdMonths,
    required this.milkingStartAgeMonths,
    required this.maturityAgeYears,
    required this.motherAgeYears,
    required this.revenuePhases,
    required this.initialBuffaloesPerUnit,
    required this.assetValues,
  });

  factory SimulationConfig.fromJson(Map<String, dynamic> json) {
    // Parse asset values map (keys are strings in JSON, need int)
    final assetsJson = json['assetValues'] as Map<String, dynamic>;
    final assetsMap = assetsJson.map(
      (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
    );

    return SimulationConfig(
      defaultUnits: (json['defaultUnits'] as num).toDouble(),
      defaultYears: json['defaultYears'] as int,
      defaultStartYear: json['defaultStartYear'] as int,
      defaultStartMonth: json['defaultStartMonth'] as int,
      defaultStartDay: json['defaultStartDay'] as int,
      milkPrice: (json['milkPrice'] as num).toDouble(),
      feedingCostPerDay: (json['feedingCostPerDay'] as num).toDouble(),
      otherCostPerDay: (json['otherCostPerDay'] as num).toDouble(),
      cpfMonthlyCost: (json['cpfMonthlyCost'] as num).toDouble(),
      cpfAgeThresholdMonths: json['cpfAgeThresholdMonths'] as int,
      milkingStartAgeMonths: json['milkingStartAgeMonths'] as int,
      maturityAgeYears: json['maturityAgeYears'] as int,
      motherAgeYears: json['motherAgeYears'] as int,
      revenuePhases: (json['revenuePhases'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, RevenuePhase.fromJson(value)),
      ),
      initialBuffaloesPerUnit: InitialBuffaloesConfig.fromJson(
        json['initialBuffaloesPerUnit'],
      ),
      assetValues: assetsMap,
    );
  }

  static Future<SimulationConfig> load() async {
    final String response = await rootBundle.loadString(
      'assets/simulation_config.json',
    );
    final data = await json.decode(response);
    return SimulationConfig.fromJson(data);
  }
}

class RevenuePhase {
  final int months;
  final double monthlyRevenue;

  RevenuePhase({required this.months, required this.monthlyRevenue});

  factory RevenuePhase.fromJson(Map<String, dynamic> json) {
    return RevenuePhase(
      months: json['months'] as int,
      monthlyRevenue: (json['monthlyRevenue'] as num).toDouble(),
    );
  }
}

class InitialBuffaloesConfig {
  final int mothers;
  final int calves;
  final int batchGapMonths;
  final double buffaloPrice;
  final double cpfPerUnitInitial;
  final int revenueStartDelayMonths;

  InitialBuffaloesConfig({
    required this.mothers,
    required this.calves,
    required this.batchGapMonths,
    required this.buffaloPrice,
    required this.cpfPerUnitInitial,
    required this.revenueStartDelayMonths,
  });

  factory InitialBuffaloesConfig.fromJson(Map<String, dynamic> json) {
    return InitialBuffaloesConfig(
      mothers: json['mothers'] as int,
      calves: json['calves'] as int,
      batchGapMonths: json['batchGapMonths'] as int,
      buffaloPrice: (json['buffaloPrice'] as num?)?.toDouble() ?? 175000,
      cpfPerUnitInitial:
          (json['cpfPerUnitInitial'] as num?)?.toDouble() ?? 13000,
      revenueStartDelayMonths: json['revenueStartDelayMonths'] as int? ?? 2,
    );
  }
}
