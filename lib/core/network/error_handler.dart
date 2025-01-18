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
    if (error is http.ClientException) {
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

  static APIException handleHttpResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return APIException(
        message: "Success",
        statusCode: response.statusCode,
      );
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
