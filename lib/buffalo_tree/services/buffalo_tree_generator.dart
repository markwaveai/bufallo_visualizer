import 'dart:math';

import 'package:buffalo_visualizer/buffalo_tree/models/buffalo_node.dart';
import 'package:buffalo_visualizer/buffalo_tree/models/milk_production_config.dart';

class BuffaloTreeResult {
  final List<BuffaloNode> roots;
  final List<BuffaloNode> allNodes;
  final MilkProductionResult milkData;
  final int units;
  final int years;
  final int startYear;

  const BuffaloTreeResult({
    required this.roots,
    required this.allNodes,
    required this.milkData,
    required this.units,
    required this.years,
    required this.startYear,
  });

  int get depth => allNodes.fold<int>(
    0,
    (int value, BuffaloNode node) => max(value, node.generation),
  );
}

class BuffaloTreeGenerator {
  const BuffaloTreeGenerator();

  BuffaloTreeResult generate({
    required String rootName,
    required int startYear,
    required int years,
    required int units,
  }) {
    final List<BuffaloNode> allNodes = <BuffaloNode>[];
    final List<BuffaloNode> roots = <BuffaloNode>[];

    int nextId = 1;

    // Create one founder buffalo per unit
    // Create two founder buffaloes per unit (matching React logic)
    for (int u = 0; u < units; u++) {
      // First founder
      final BuffaloNode founder1 = BuffaloNode(
        id: 'buffalo-$nextId',
        name: '$rootName Unit ${u + 1} A',
        birthYear: startYear - 5, // Start at age 5 (mature, 60+ months)
        generation: 0,
        unit: u + 1,
      );
      nextId++;
      allNodes.add(founder1);
      roots.add(founder1);

      // Second founder
      final BuffaloNode founder2 = BuffaloNode(
        id: 'buffalo-$nextId',
        name: '$rootName Unit ${u + 1} B',
        birthYear: startYear - 5, // Start at age 5 (mature, 60+ months)
        generation: 0,
        unit: u + 1,
      );
      nextId++;
      allNodes.add(founder2);
      roots.add(founder2);
    }

    // Simulate years and breeding
    for (int year = 1; year <= years; year++) {
      final int currentYear = startYear + (year - 1);
      final List<BuffaloNode> moms = allNodes
          .where(
            (b) => (currentYear - b.birthYear) >= 3, // Age 3 or older
          )
          .toList();

      for (final BuffaloNode mom in moms) {
        // AI Injections: 100% Female Births
        final BuffaloNode calf = BuffaloNode(
          id: 'buffalo-$nextId',
          name: '${mom.name.split(' ').first} Jr. $year',
          birthYear: currentYear,
          generation: mom.generation + 1,
          parentId: mom.id,
          unit: mom.unit,
        );
        nextId++;
        allNodes.add(calf);

        // Add child to parent's children list
        mom.children.add(calf);
      }
    }

    // Calculate milk production data
    final MilkProductionResult milkData = _calculateMilkProduction(
      allNodes,
      startYear,
      years,
    );

    return BuffaloTreeResult(
      roots: roots,
      allNodes: allNodes,
      milkData: milkData,
      units: units,
      years: years,
      startYear: startYear,
    );
  }

  MilkProductionResult _calculateMilkProduction(
    List<BuffaloNode> herd,
    int startYear,
    int totalYears,
  ) {
    final List<YearlyMilkData> yearlyData = [];
    double totalRevenue = 0;
    double totalLiters = 0;

    for (int year = startYear; year < startYear + totalYears; year++) {
      double yearLiters = 0;
      int producingBuffaloes = 0;
      int totalBuffaloesInYear = 0;

      for (final BuffaloNode buffalo in herd) {
        final double milkProduction = _calculateYearlyMilkProduction(
          buffalo,
          year,
        );
        yearLiters += milkProduction;
        if (milkProduction > 0) producingBuffaloes++;

        // Count buffaloes alive in this year
        if (buffalo.birthYear <= year) {
          totalBuffaloesInYear++;
        }
      }

      final double yearRevenue =
          yearLiters * MilkProductionConfig.pricePerLiter;
      totalRevenue += yearRevenue;
      totalLiters += yearLiters;

      yearlyData.add(
        YearlyMilkData(
          year: year,
          producingBuffaloes: producingBuffaloes,
          nonProducingBuffaloes: totalBuffaloesInYear - producingBuffaloes,
          totalBuffaloes: totalBuffaloesInYear,
          liters: yearLiters,
          revenue: yearRevenue,
        ),
      );
    }

    return MilkProductionResult(
      yearlyData: yearlyData,
      totalRevenue: totalRevenue,
      totalLiters: totalLiters,
      averageAnnualRevenue: totalRevenue / totalYears,
    );
  }

  double _calculateYearlyMilkProduction(BuffaloNode buffalo, int year) {
    final int buffaloAgeInYear = year - buffalo.birthYear;

    // Only buffaloes aged 3 or older produce milk
    if (buffaloAgeInYear < MilkProductionConfig.milkProductionStartAge) {
      return 0;
    }

    // Calculate annual milk production based on schedule
    final highProduction = MilkProductionConfig.productionSchedule['high']!;
    final mediumProduction = MilkProductionConfig.productionSchedule['medium']!;

    final double highProductionLiters =
        highProduction.months * 30 * highProduction.litersPerDay;
    final double mediumProductionLiters =
        mediumProduction.months * 30 * mediumProduction.litersPerDay;

    return highProductionLiters + mediumProductionLiters;
  }
}
