import 'package:on_chain_bridge/database/exception/exception.dart';

class IDatabaseJSConstants {
  static const onDatabaseBlockError = IDatabaseException(
      "IndexedDB upgrade blocked: another tab or window is still using the database.");
  static const unableToUpgradeDatabase = IDatabaseException(
      "Database upgrade failed: unable to create table. Missing permissions.");
}
