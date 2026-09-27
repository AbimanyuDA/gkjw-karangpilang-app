// test/helpers/fake_http.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// Adapter Dio palsu: merekam request dan mengembalikan respons yang disiapkan.
class FakeHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<ResponseBody Function(RequestOptions)> _responses = [];

  void reply(int status, Object body) {
    _responses.add((_) => ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ));
  }

  void fail(DioExceptionType type) {
    _responses.add((options) => throw DioException(requestOptions: options, type: type));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_responses.isEmpty) throw StateError('Tidak ada respons palsu untuk ${options.uri}');
    return _responses.removeAt(0)(options);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> ok(Object? data, {Map<String, dynamic>? meta}) => {
      'success': true,
      'data': data,
      'error': null,
      'meta': ?meta,
    };

Map<String, dynamic> err(String code, String message, {Map<String, String>? fields}) => {
      'success': false,
      'data': null,
      'error': {'code': code, 'message': message, 'fields': ?fields},
    };
