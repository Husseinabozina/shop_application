import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';

/// Custom exception class to encapsulate error details.
class APIException {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;

  APIException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
  });

  @override
  String toString() {
    return "APIException: $message (Status: $statusCode, Code: $errorCode, Details: $details)";
  }
}

/// ExceptionHandler class to handle various exceptions and provide APIException instances.
class ExceptionHandler {
  static APIException handle(dynamic error) {
    if (error is APIException) {
      return error;
    } else if (error is http.ClientException) {
      return APIException(
        message:
            "Failed to connect to the server. Please check your internet connection.",
      );
    } else if (error is SocketException) {
      return APIException(
        message:
            "Network error. Please ensure you have an active internet connection.",
      );
    } else if (error is HttpException) {
      return APIException(
        message: "HTTP error: ${error.message}. Please try again later.",
      );
    } else if (error is FormatException) {
      return APIException(
        message: "Invalid response format. Please contact support.",
      );
    } else if (error is FirebaseException) {
      return _handleFirebaseError(error);
    } else if (error is TimeoutException) {
      return APIException(
        message: "Request timed out. Please try again later.",
      );
    } else {
      return APIException(
        message: "An unexpected error occurred.",
        details: error.toString(),
      );
    }
  }

  static const _authMessages = <String, String>{
    'EMAIL_EXISTS': 'This email already has an account. Sign in instead.',
    'INVALID_EMAIL': 'Enter a valid email address.',
    'INVALID_LOGIN_CREDENTIALS': 'The email or password is incorrect.',
    'EMAIL_NOT_FOUND': 'The email or password is incorrect.',
    'INVALID_PASSWORD': 'The email or password is incorrect.',
    'MISSING_PASSWORD': 'Enter your password.',
    'WEAK_PASSWORD': 'Choose a stronger password with at least 6 characters.',
    'PASSWORD_DOES_NOT_MEET_REQUIREMENTS':
        'Choose a stronger password that meets the account password requirements.',
    'USER_DISABLED': 'This account has been disabled. Contact support.',
    'TOO_MANY_ATTEMPTS_TRY_LATER':
        'Too many attempts. Please wait a little and try again.',
    'QUOTA_EXCEEDED': 'Too many requests. Please try again later.',
    'OPERATION_NOT_ALLOWED':
        'Email and password sign-in is unavailable. Contact support.',
    'API_KEY_INVALID': 'Sign-in is not configured correctly. Contact support.',
    'INVALID_API_KEY': 'Sign-in is not configured correctly. Contact support.',
    'CONFIGURATION_NOT_FOUND':
        'Sign-in is not configured correctly. Contact support.',
    'PROJECT_NOT_FOUND':
        'Sign-in is not configured correctly. Contact support.',
  };

  /// Decode REST errors without retaining server text that may contain user data.
  static APIException handleFirebaseAuthResponse(http.Response response) {
    String? code;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is Map) {
        final message = body['error']['message'];
        if (message is String) {
          final candidate = message.split(':').first.trim();
          if (_authMessages.containsKey(candidate)) {
            code = candidate;
          }
        }
      }
    } on FormatException {
      // HTML, empty, and malformed responses use the safe fallback below.
    }
    return APIException(
      message:
          _authMessages[code] ??
          'Could not sign in. Please try again. If this continues, contact support.',
      statusCode: response.statusCode,
      errorCode: code ?? 'AUTH_REQUEST_FAILED',
    );
  }

  static APIException handleHttpResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return APIException(message: "Success", statusCode: response.statusCode);
    } else {
      try {
        final body = jsonDecode(response.body);
        return APIException(
          message: body['error'] ?? "Server error.",
          statusCode: response.statusCode,
          details: body,
        );
      } catch (e) {
        return APIException(
          message: "Server responded with status code ${response.statusCode}.",
          statusCode: response.statusCode,
        );
      }
    }
  }

  static APIException _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'network-request-failed':
        return APIException(
          message:
              "Failed to connect to Firebase. Please check your internet connection.",
          errorCode: error.code,
        );
      case 'permission-denied':
        return APIException(
          message: "You do not have permission to perform this action.",
          errorCode: error.code,
        );
      case 'unauthenticated':
        return APIException(
          message: "User authentication required. Please log in.",
          errorCode: error.code,
        );
      default:
        return APIException(
          message: "Firebase error: ${error.message}.",
          errorCode: error.code,
        );
    }
  }
}
