import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../models/blood_request.dart';
import '../models/donor.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('auth/refresh')) {
            final refreshed = await _refresh();
            if (refreshed) {
              final token = await _storage.read(key: 'access_token');
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              return handler.resolve(await _dio.fetch(error.requestOptions));
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  Future<bool> get isSignedIn async =>
      await _storage.read(key: 'refresh_token') != null;
  Future<String> get savedRole async =>
      await _storage.read(key: 'user_role') ?? 'user';

  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'auth/login/',
        data: {'email': email, 'password': password},
      );
      return await _saveTokens(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException(_message(error));
    }
  }

  Future<String?> requestRegistration(
    String email,
    String password,
    String confirmation,
  ) async {
    try {
      final response = await _dio.post(
        'auth/register/',
        data: {
          'email': email,
          'password': password,
          'confirm_password': confirmation,
        },
      );
      return response.data['debug_otp'] as String?;
    } on DioException catch (error) {
      throw ApiException(_message(error));
    }
  }

  Future<String> verifyRegistration(String email, String otp) async {
    try {
      final response = await _dio.post(
        'auth/register/verify/',
        data: {'email': email, 'otp': otp},
      );
      return await _saveTokens(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException(_message(error));
    }
  }

  Future<String?> resendRegistrationOTP(String email) async {
    try {
      final response = await _dio.post(
        'auth/register/resend/',
        data: {'email': email},
      );
      return response.data['debug_otp'] as String?;
    } on DioException catch (error) {
      throw ApiException(_message(error));
    }
  }

  Future<void> logout() => _storage.deleteAll();

  Future<bool> _refresh() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: apiBaseUrl))
          .post('auth/refresh/', data: {'refresh': refresh});
      await _storage.write(
        key: 'access_token',
        value: response.data['access'] as String,
      );
      if (response.data['refresh'] != null) {
        await _storage.write(
          key: 'refresh_token',
          value: response.data['refresh'] as String,
        );
      }
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<String> _saveTokens(Map<String, dynamic> data) async {
    final user = Map<String, dynamic>.from(data['user'] as Map? ?? {});
    final role = user['role'] as String? ?? 'user';
    await _storage.write(key: 'access_token', value: data['access'] as String);
    await _storage.write(
      key: 'refresh_token',
      value: data['refresh'] as String,
    );
    await _storage.write(key: 'user_role', value: role);
    return role;
  }

  Future<Map<String, dynamic>> profile() async =>
      Map<String, dynamic>.from((await _dio.get('profile/')).data as Map);

  Future<Map<String, dynamic>> saveProfile(
    Map<String, dynamic> values, {
    XFile? image,
  }) async {
    final data = FormData.fromMap(values);
    if (image != null) {
      data.files.add(
        MapEntry(
          'person_image',
          MultipartFile.fromBytes(
            await image.readAsBytes(),
            filename: image.name,
          ),
        ),
      );
    }
    final response = await _dio.patch('profile/', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Donor>> donors([Map<String, dynamic>? filters]) async {
    final response = await _dio.get('donors/', queryParameters: filters);
    final data = response.data;
    final items = data is Map ? data['results'] as List : data as List;
    return items
        .map((item) => Donor.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> locations() async =>
      Map<String, dynamic>.from((await _dio.get('locations/')).data as Map);

  Future<List<BloodRequest>> requests({bool mine = false}) async {
    final response = await _dio.get(
      'requests/',
      queryParameters: {if (mine) 'mine': 'true'},
    );
    final data = response.data;
    final items = data is Map ? data['results'] as List : data as List;
    return items
        .map(
          (item) =>
              BloodRequest.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> createRequest(Map<String, dynamic> values) async =>
      _dio.post('requests/', data: values);
  Future<void> setRequestStatus(int id, String value) async =>
      _dio.patch('requests/$id/status/', data: {'status': value});
  Future<void> setDonorAvailability(int id, bool available) async =>
      _dio.patch('donors/$id/availability/', data: {'is_available': available});

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      return data.values
          .map((value) => value is List ? value.join(' ') : value.toString())
          .join('\n');
    }
    return 'Could not connect to the server. Please try again.';
  }
}
