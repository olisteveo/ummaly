import 'package:http/http.dart' as http;
import '../../config/config.dart';

class PingService {
  Future<void> testPing() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/ping'));
      print('✅ PING RESPONSE: ${response.body}');
    } catch (e) {
      print('❌ PING ERROR: $e');
    }
  }
}
