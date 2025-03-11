import 'package:flutter/services.dart';

/// Wrapper class to hold data on success or message on failure
class Result<T> {
  T? data;
  String? message;

  Result._({this.data, this.message});

  factory Result.success(final T? data) {
    return Result<T>._(data: data);
  }

  factory Result.error(final String? message) {
    return Result<T>._(message: message);
  }

  bool isSuccess() => data != null;
}

Future<Result<T>> handleError<T>(final Future<T?> future) async {
  try {
    final T? result = await future;
    return Result<T>.success(result);
  } on PlatformException catch (err) {
    return Result.error(err.message);
  } catch (err) {
    return Result.error("Something went wrong: $err");
  }
}
