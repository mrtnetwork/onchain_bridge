import 'package:on_chain_bridge/database/models/table.dart';

enum _StatementBuilderType {
  select,
  remove;

  bool get isRemove => this == remove;
}

class StatementBuilder {
  final StringBuffer buffer;
  bool _hasWhere = false;
  bool _hasOrder = false;
  bool _hasLimit = false;
  final _StatementBuilderType _type;
  StatementBuilder._(this.buffer, this._type);
  factory StatementBuilder.select({
    required List<String> columns,
    required String tableName,
  }) {
    String s = "SELECT ${columns.join(", ")}";
    s += " FROM $tableName";
    return StatementBuilder._(StringBuffer(s), _StatementBuilderType.select);
  }
  factory StatementBuilder.delete({
    required String tableName,
  }) {
    return StatementBuilder._(
        StringBuffer("DELETE FROM $tableName"), _StatementBuilderType.remove);
  }
  void and(String name) {
    if (_hasWhere) {
      buffer.write(' AND $name = ?');
    } else {
      buffer.write(' WHERE $name = ?');
      _hasWhere = true;
    }
  }

  void lt(String name) {
    if (_hasWhere) {
      buffer.write(' AND $name < ?');
    } else {
      buffer.write(' WHERE $name < ?');
      _hasWhere = true;
    }
  }

  void gt(String name) {
    if (_hasWhere) {
      buffer.write(' AND $name > ?');
    } else {
      buffer.write(' WHERE $name > ?');
      _hasWhere = true;
    }
  }

  void orderBy(String column, IDatabaseQueryOrdering order) {
    assert(!_hasLimit);
    if (!_hasOrder) {
      buffer.write(' ORDER BY $column ${order.value}');
      _hasOrder = true;
    } else {
      buffer.write(', $column ${order.value}');
    }
  }

  void limit(int? limit) {
    if (limit != null) {
      buffer.write(' LIMIT $limit');
      _hasLimit = true;
    }
  }

  void offset(int? offset) {
    assert(!_type.isRemove);
    if (offset != null) {
      assert(_hasLimit);
      buffer.write(' OFFSET $offset');
    }
  }

  String build() => buffer.toString();
}
