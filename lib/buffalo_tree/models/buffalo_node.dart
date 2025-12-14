import 'package:flutter/material.dart';

/// Immutable representation of a buffalo in the genealogy tree.
class BuffaloNode {
  BuffaloNode({
    required this.id,
    required this.name,
    required this.birthYear,
    required this.generation,
    this.parentId,
    this.unit = 1,
    List<BuffaloNode>? children,
    Map<String, dynamic>? data,
  }) : children = children ?? [],
       data = data ?? const {};

  final String id;
  final String name;
  final String? parentId;
  final int birthYear;
  final int generation;
  final int unit;
  final List<BuffaloNode> children;
  final Map<String, dynamic> data;

  /// Convenience getter for displaying the age within a given year.
  int ageAtYear(int year) => year - birthYear;

  Color get generationColor =>
      Colors.primaries[generation % Colors.primaries.length];

  /// Creates a copy of this node with the given fields replaced by the new values.
  BuffaloNode copyWith({
    String? id,
    String? name,
    String? parentId,
    int? birthYear,
    int? generation,
    int? unit,
    List<BuffaloNode>? children,
    Map<String, dynamic>? data,
  }) {
    return BuffaloNode(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      birthYear: birthYear ?? this.birthYear,
      generation: generation ?? this.generation,
      unit: unit ?? this.unit,
      children: children ?? this.children,
      data: data ?? this.data,
    );
  }
}
