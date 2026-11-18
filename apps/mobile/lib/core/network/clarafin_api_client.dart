import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/profile/presentation/providers/user_profile_provider.dart';
import '../services/local_storage_service.dart';

/// Build-time and runtime configuration for Clarafin Go API access.
class ClarafinApiConfig {
  static const String envBaseUrl = String.fromEnvironment(
    'CLARAFIN_API_BASE_URL',
    defaultValue: '',
  );

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration streamReceiveTimeout;

  const ClarafinApiConfig({
    this.baseUrl = envBaseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.streamReceiveTimeout = const Duration(seconds: 120),
  });

  factory ClarafinApiConfig.fromUrl(
    String url, {
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration streamReceiveTimeout = const Duration(seconds: 120),
  }) {
    return ClarafinApiConfig(
      baseUrl: url.trim(),
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      streamReceiveTimeout: streamReceiveTimeout,
    );
  }

  bool get isConfigured => baseUrl.trim().isNotEmpty;
  bool get isRemoteEnabled => isConfigured;

  String get normalizedBaseUrl =>
      baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
}

/// Structured Clarafin backend error parsed from `{"error": {...}}` envelopes.
class ClarafinApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;
  final String? requestId;
  final Map<String, dynamic>? details;

  const ClarafinApiException({
    this.statusCode,
    required this.code,
    required this.message,
    this.requestId,
    this.details,
  });

  bool get isQuotaExceeded => code == 'QUOTA_EXCEEDED' || statusCode == 402;
  bool get isRateLimited => code == 'RATE_LIMITED' || statusCode == 429;
  bool get isUnauthorized => code == 'UNAUTHORIZED' || statusCode == 401;

  @override
  String toString() => 'ClarafinApiException($statusCode, $code): $message';
}

/// Dio HTTP client managing bearer JWT acquisition, request IDs, and SSE streams.
class ClarafinApiClient {
  static const String _prefTokenKey = 'clarafin_api_dev_jwt';
  static const String _prefExpiryKey = 'clarafin_api_dev_jwt_expiry';
  static const String _prefUserIdKey = 'clarafin_api_dev_user_id';
  static const Uuid _uuid = Uuid();

  final ClarafinApiConfig config;
  final Dio _dio;
  final SharedPreferences? _prefs;
  final Future<String?> Function()? _externalTokenProvider;
  final String? _devEmail;
  final String? _devFullName;
  final String? _devUserId;
  final DateTime Function() _clock;

  String? _explicitToken;
  String? _cachedDevToken;
  DateTime? _cachedDevExpiry;
  String? _cachedUserId;
  Future<String?>? _inFlightTokenFuture;

  ClarafinApiClient({
    required this.config,
    Dio? dio,
    SharedPreferences? prefs,
    String? accessToken,
    Future<String?> Function()? tokenProvider,
    String? devEmail,
    String? devFullName,
    String? devUserId,
    DateTime Function()? clock,
  }) : _prefs = prefs,
       _externalTokenProvider = tokenProvider,
       _devEmail = devEmail,
       _devFullName = devFullName,
       _devUserId = devUserId,
       _clock = clock ?? DateTime.now,
       _explicitToken = _trimOrNull(accessToken),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.normalizedBaseUrl,
               connectTimeout: config.connectTimeout,
               receiveTimeout: config.receiveTimeout,
               headers: const {'Accept': 'application/json'},
             ),
           ) {
    if (_dio.options.baseUrl.isEmpty && config.isConfigured) {
      _dio.options.baseUrl = config.normalizedBaseUrl;
    }
    _restorePersistedDevToken();
  }

  Dio get dio => _dio;
  String? get cachedUserId => _cachedUserId;

  void setAccessToken(String? token, {DateTime? expiresAt}) {
    _explicitToken = _trimOrNull(token);
    if (_explicitToken == null) {
      clearCachedToken();
    } else if (expiresAt != null) {
      _cachedDevExpiry = expiresAt;
    }
  }

  void clearCachedToken() {
    _cachedDevToken = null;
    _cachedDevExpiry = null;
    _cachedUserId = null;
    _prefs?.remove(_prefTokenKey);
    _prefs?.remove(_prefExpiryKey);
    _prefs?.remove(_prefUserIdKey);
  }

  /// Resolves an active bearer JWT, calling `POST /v1/dev/token` lazily when needed.
  Future<String?> ensureAccessToken({
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    if (_explicitToken != null && !forceRefresh) {
      return _explicitToken;
    }
    if (_externalTokenProvider != null) {
      final external = _trimOrNull(await _externalTokenProvider());
      if (external != null) return external;
    }
    if (!config.isConfigured) return null;

    if (!forceRefresh && _hasValidCachedDevToken()) {
      return _cachedDevToken;
    }

    if (_inFlightTokenFuture != null) {
      return _inFlightTokenFuture!;
    }

    final future = _fetchDevToken(cancelToken: cancelToken);
    _inFlightTokenFuture = future;
    try {
      return await future;
    } finally {
      _inFlightTokenFuture = null;
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final res = await _requestWithAuthRetry<dynamic>(
      () async => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: await _authOptions(cancelToken: cancelToken),
      ),
      cancelToken: cancelToken,
    );
    return _unwrapDataEnvelope(res.data);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) async {
    final res = await _requestWithAuthRetry<dynamic>(
      () async => _dio.post<dynamic>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: await _authOptions(cancelToken: cancelToken),
      ),
      cancelToken: cancelToken,
    );
    return _unwrapDataEnvelope(res.data);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) async {
    final res = await _requestWithAuthRetry<dynamic>(
      () async => _dio.patch<dynamic>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: await _authOptions(cancelToken: cancelToken),
      ),
      cancelToken: cancelToken,
    );
    return _unwrapDataEnvelope(res.data);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    CancelToken? cancelToken,
  }) async {
    final res = await _requestWithAuthRetry<dynamic>(
      () async => _dio.delete<dynamic>(
        path,
        cancelToken: cancelToken,
        options: await _authOptions(cancelToken: cancelToken),
      ),
      cancelToken: cancelToken,
    );
    return _unwrapDataEnvelope(res.data);
  }

  /// Opens an authenticated SSE stream (`ResponseType.stream`) for AI endpoints.
  Future<Response<ResponseBody>> postSseStream(
    String path, {
    Object? data,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
  }) async {
    final opts = await _authOptions(
      cancelToken: cancelToken,
      extraHeaders: {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        ...?headers,
      },
      responseType: ResponseType.stream,
      receiveTimeout: config.streamReceiveTimeout,
    );
    return _dio.post<ResponseBody>(
      path,
      data: data,
      cancelToken: cancelToken,
      options: opts,
    );
  }

  Future<Response<T>> _requestWithAuthRetry<T>(
    Future<Response<T>> Function() execute, {
    CancelToken? cancelToken,
  }) async {
    try {
      return await execute();
    } on DioException catch (err) {
      if (err.response?.statusCode == 401 && _explicitToken == null) {
        clearCachedToken();
        await ensureAccessToken(forceRefresh: true, cancelToken: cancelToken);
        return execute();
      }
      throw await extractApiException(err);
    }
  }

  Future<Options> _authOptions({
    CancelToken? cancelToken,
    Map<String, dynamic>? extraHeaders,
    ResponseType? responseType,
    Duration? receiveTimeout,
  }) async {
    final token = await ensureAccessToken(cancelToken: cancelToken);
    return Options(
      responseType: responseType,
      receiveTimeout: receiveTimeout,
      headers: {
        'X-Request-Id': _uuid.v4(),
        if (token != null) 'Authorization': 'Bearer $token',
        ...?extraHeaders,
      },
    );
  }

  Future<String?> _fetchDevToken({CancelToken? cancelToken}) async {
    final payload = <String, dynamic>{};
    final validUuid = _validNonNilUuid(_devUserId);
    if (validUuid != null) {
      payload['user_id'] = validUuid;
    }
    final email = _trimOrNull(_devEmail);
    if (email != null && email.contains('@')) {
      payload['email'] = email;
    }
    final fullName = _trimOrNull(_devFullName);
    if (fullName != null) {
      payload['full_name'] =
          fullName.length > 120 ? fullName.substring(0, 120) : fullName;
    }

    final res = await _dio.post<dynamic>(
      '/v1/dev/token',
      data: payload,
      cancelToken: cancelToken,
      options: Options(headers: {'X-Request-Id': _uuid.v4()}),
    );

    final data = _unwrapDataEnvelope(res.data);
    final token = _trimOrNull(data['access_token']?.toString());
    if (token == null) return null;

    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 86400;
    final parsedExpiry =
        DateTime.tryParse(data['expires_at']?.toString() ?? '')?.toUtc() ??
        _clock().toUtc().add(Duration(seconds: expiresIn));

    final userMap = data['user'];
    final userId =
        userMap is Map ? _trimOrNull(userMap['id']?.toString()) : null;

    _cachedDevToken = token;
    _cachedDevExpiry = parsedExpiry;
    _cachedUserId = userId;

    await _prefs?.setString(_prefTokenKey, token);
    await _prefs?.setString(_prefExpiryKey, parsedExpiry.toIso8601String());
    if (userId != null) {
      await _prefs?.setString(_prefUserIdKey, userId);
    }
    return token;
  }

  bool _hasValidCachedDevToken() {
    if (_cachedDevToken == null || _cachedDevExpiry == null) return false;
    final cutoff = _clock().toUtc().add(const Duration(seconds: 60));
    return _cachedDevExpiry!.isAfter(cutoff);
  }

  void _restorePersistedDevToken() {
    final token = _trimOrNull(_prefs?.getString(_prefTokenKey));
    final expiryRaw = _trimOrNull(_prefs?.getString(_prefExpiryKey));
    final userId = _trimOrNull(_prefs?.getString(_prefUserIdKey));
    final expiry = expiryRaw != null ? DateTime.tryParse(expiryRaw)?.toUtc() : null;
    if (token != null && expiry != null) {
      _cachedDevToken = token;
      _cachedDevExpiry = expiry;
      _cachedUserId = userId;
    }
  }

  /// Extracts a structured [ClarafinApiException] from JSON or streamed [ResponseBody] errors.
  static Future<ClarafinApiException> extractApiException(
    DioException error,
  ) async {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ClarafinApiException(
        statusCode: error.response?.statusCode,
        code: 'NETWORK_TIMEOUT',
        message: 'Koneksi ke server Clarafin melebihi batas waktu.',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return const ClarafinApiException(
        code: 'CONNECTION_ERROR',
        message: 'Tidak dapat terhubung ke server Clarafin.',
      );
    }

    final status = error.response?.statusCode;
    final bodyMap = await _decodeResponseMap(error.response?.data);
    final errObj = bodyMap['error'] is Map
        ? Map<String, dynamic>.from(bodyMap['error'] as Map)
        : bodyMap;

    final code = _trimOrNull(errObj['code']?.toString()) ??
        switch (status) {
          402 => 'QUOTA_EXCEEDED',
          429 => 'RATE_LIMITED',
          401 => 'UNAUTHORIZED',
          _ => 'API_ERROR',
        };
    final message = _trimOrNull(errObj['message']?.toString()) ??
        error.message ??
        'Permintaan ke server Clarafin gagal diproses.';
    final requestId = _trimOrNull(errObj['request_id']?.toString());
    final details = errObj['details'] is Map
        ? Map<String, dynamic>.from(errObj['details'] as Map)
        : null;

    return ClarafinApiException(
      statusCode: status,
      code: code,
      message: message,
      requestId: requestId,
      details: details,
    );
  }

  static Future<Map<String, dynamic>> _decodeResponseMap(dynamic raw) async {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is ResponseBody) {
      try {
        final chunks = await raw.stream.toList();
        final bytes = chunks.expand((c) => c).toList();
        final text = utf8.decode(bytes, allowMalformed: true).trim();
        if (text.isEmpty) return const {};
        final decoded = jsonDecode(text);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return const {};
      }
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return const {};
      }
    }
    return const {};
  }

  static Map<String, dynamic> _unwrapDataEnvelope(dynamic raw) {
    final map = switch (raw) {
      Map<String, dynamic> m => m,
      Map m => Map<String, dynamic>.from(m),
      String s when s.trim().isNotEmpty =>
        Map<String, dynamic>.from(jsonDecode(s) as Map),
      _ => <String, dynamic>{},
    };
    final inner = map['data'];
    if (inner is Map) {
      return Map<String, dynamic>.from(inner);
    }
    return map;
  }

  static String? _validNonNilUuid(String? raw) {
    final trimmed = _trimOrNull(raw);
    if (trimmed == null) return null;
    if (trimmed == '00000000-0000-0000-0000-000000000000') return null;
    return Uuid.isValidUUID(fromString: trimmed) ? trimmed : null;
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

final clarafinApiConfigProvider = Provider<ClarafinApiConfig>((ref) {
  return const ClarafinApiConfig();
});

final clarafinApiClientProvider = Provider<ClarafinApiClient>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    prefs = null;
  }
  String? devEmail;
  String? devFullName;
  try {
    devEmail = ref.watch(userProfileProvider.select((u) => u.email));
    devFullName = ref.watch(userProfileProvider.select((u) => u.name));
  } catch (_) {}
  return ClarafinApiClient(
    config: ref.watch(clarafinApiConfigProvider),
    prefs: prefs,
    devEmail: devEmail,
    devFullName: devFullName,
  );
});
