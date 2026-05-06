import 'package:dio/dio.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService extends GetxService {
  late Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl: AppStrings.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          Get.offAllNamed(AppRoutes.login);
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> postForm(String path, dio.FormData data) =>
      _dio.post(path, data: data);

  // Session specific methods
  Future<Response> getSessions({String? category, String? sort}) {
    Map<String, dynamic> params = {};
    if (category != null) params['category'] = category;
    if (sort != null) params['sort'] = sort;
    return get('/sessions', params: params);
  }

  Future<Response> getUpcomingBookings() => get('/sessions/upcoming');

  Future<Response> getMyBookings() => get('/sessions/my-bookings');

  Future<Response> bookSession(int sessionId) =>
      post('/sessions/$sessionId/book');

  Future<Response> cancelBooking(int sessionId) =>
      delete('/sessions/$sessionId/cancel');

  Future<Response> rateSession(int sessionId,
          {required int rating, String? review}) =>
      post('/sessions/$sessionId/rate',
          data: {'rating': rating, 'review': review});
}
