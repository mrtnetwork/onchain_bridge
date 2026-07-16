abstract class HttpAuthenticated {
  const HttpAuthenticated();
  Uri toUri(Uri uri);
  Map<String, String>? toHeaders(Map<String, String>? headers);
  HttpDigestAuthenticated? digestAuthenticated();
}

class HttpDigestAuthenticated {
  final String username;
  final String password;
  const HttpDigestAuthenticated(this.username, this.password);
}
