import '../core/api_service.dart';

class HealthService {
  HealthService({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<int> ping() async {
    // Try common FastAPI endpoints.
    try {
      final res = await _api.get('/docs');
      return res.statusCode ?? 0;
    } catch (_) {
      final res = await _api.get('/');
      return res.statusCode ?? 0;
    }
  }
}

