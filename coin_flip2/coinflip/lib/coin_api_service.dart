import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _adviceUrl = 'https://api.adviceslip.com/advice';

  Future<String?> getPrediction() async {
    try {
      final response = await http.get(
        Uri.parse(_adviceUrl),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['slip']['advice'];
      } else {
        throw Exception('Ошибка загрузки');
      }
    } catch (e) {
      return null;
    }
  }
}