typedef JsonParser<T> = T Function(dynamic json);

class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    required this.data,
    this.raw,
  });

  final int code;
  final String message;
  final T? data;
  final dynamic raw;
}
