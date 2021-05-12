import 'dart:convert';
import 'dart:typed_data';

import 'package:github/github.dart' as gh;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor/src/store/file_cache_store.dart';

// Global options
final options = CacheOptions(
  store: FileCacheStore('cache'),
  policy: CachePolicy.forceCache,
  hitCacheOnErrorExcept: [401, 403],
  maxStale: const Duration(days: 7),
  priority: CachePriority.normal,
  cipher: null,
  keyBuilder: CacheOptions.defaultCacheKeyBuilder,
  // Default. Allows to cache POST requests.
  // Overriding [keyBuilder] is strongly recommended.
  allowPostMethod: false,
);

final cachingDio = Dio()
  ..interceptors.add(DioCacheInterceptor(options: options));

class DioAsHttpClient implements http.Client {
  final Dio dio;
  DioAsHttpClient(this.dio);

  @override
  void close() {
    dio.close();
  }

  @override
  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    // TODO: implement head
    throw UnimplementedError();
  }

  @override
  Future<http.Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    // TODO: implement patch
    throw UnimplementedError();
  }

  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    // TODO: implement post
    throw UnimplementedError();
  }

  @override
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    // TODO: implement put
    throw UnimplementedError();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    // TODO: implement readBytes
    throw UnimplementedError();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    var options = Options(
        method: request.method,
        headers: request.headers,
        responseType: ResponseType.bytes);
    var response = await dio.requestUri(request.url, options: options);
    return http.StreamedResponse(
        http.ByteStream.fromBytes(response.data), response.statusCode!,
        contentLength: null,
        request: request,
        headers: request.headers,
        isRedirect: response.isRedirect ?? false,
        persistentConnection: true,
        reasonPhrase: response.statusMessage);
  }
}

var github = gh.GitHub(
    auth: gh.findAuthenticationFromEnvironment(),
    client: DioAsHttpClient(cachingDio));
