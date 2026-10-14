/// The rows and the number of changed rows of one SQL statement.
class ResultSet {
  const ResultSet(this.rows, this.affectedRows);

  final List<Map<String, Object?>> rows;
  final int affectedRows;

  bool get isEmpty => rows.isEmpty;

  /// The first row, or null when there are no rows.
  Map<String, Object?>? get firstOrNull => rows.isEmpty ? null : rows.first;
}
