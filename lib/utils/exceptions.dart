class DatabaseException implements Exception {
  final String message;
  final dynamic error;

  DatabaseException(this.message, [this.error]);

  @override
  String toString() {
    if (error != null) {
      return 'DatabaseException: $message (Error: $error)';
    }
    return 'DatabaseException: $message';
  }
}

class StorageException implements Exception {
  final String message;
  final dynamic error;

  StorageException(this.message, [this.error]);

  @override
  String toString() {
    if (error != null) {
      return 'StorageException: $message (Error: $error)';
    }
    return 'StorageException: $message';
  }
}

class AuthException implements Exception {
  final String message;
  final dynamic error;

  AuthException(this.message, [this.error]);

  @override
  String toString() {
    if (error != null) {
      return 'AuthException: $message (Error: $error)';
    }
    return 'AuthException: $message';
  }
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  ValidationException(this.message, [this.fieldErrors]);

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return 'ValidationException: $message (Field errors: $fieldErrors)';
    }
    return 'ValidationException: $message';
  }
}
