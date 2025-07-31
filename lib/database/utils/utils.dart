class IDatabaseUtils {
  static bool isValidSnakeCase(String input) {
    final snakeCaseRegExp = RegExp(r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$');
    return snakeCaseRegExp.hasMatch(input);
  }

  static int createOrConvertDateTimeSecound([DateTime? datetime]) {
    return (datetime ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime dateTimeFromSconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  // static DateTime nowAsSeconds(int seconds) {
  //   return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  // }
}
