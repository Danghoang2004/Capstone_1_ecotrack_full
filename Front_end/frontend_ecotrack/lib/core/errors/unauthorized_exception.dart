class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = "Unauthorized"]);

  @override
  String toString() => "UnauthorizedException: $message";
}
