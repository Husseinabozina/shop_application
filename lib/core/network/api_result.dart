import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shop_application/core/network/error_handler.dart';

part 'api_result.freezed.dart';

@Freezed()
class APIResult<T> with _$APIResult<T> {
  /// Represents a successful API call with data.
  const factory APIResult.success(T data) = Success<T>;

  /// Represents a failed API call with an [APIException].
  const factory APIResult.failure(APIException error) = Failure<T>;
}
