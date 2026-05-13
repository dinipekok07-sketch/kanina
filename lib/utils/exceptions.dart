class AppException implements Exception {
  final String message;
  final String? code;

  AppException({required this.message, this.code});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  AuthException({required super.message, super.code});
}

class VotingException extends AppException {
  VotingException({required super.message, super.code});
}

class NetworkException extends AppException {
  NetworkException({required super.message, super.code});
}

class ValidationException extends AppException {
  ValidationException({required super.message, super.code});
}
