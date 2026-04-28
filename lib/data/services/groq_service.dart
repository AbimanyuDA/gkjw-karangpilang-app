// lib/data/services/groq_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../env.dart';

class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  final Dio _dio = Dio();

  // Track current key index — persists across calls within the same session
  static int _currentKeyIndex = 0;

  String get _currentKey => Env.groqApiKeys[_currentKeyIndex];

  void _rotateKey() {
    _currentKeyIndex = (_currentKeyIndex + 1) % Env.groqApiKeys.length;
  }

  Future<String> generateAyatAlkitab(String tema, String sesi) async {
    final systemPrompt = sesi == 'pagi'
        ? 'Kamu adalah asisten rohani Kristen. Berikan SATU ayat Alkitab yang relevan dan menginspirasi untuk sapaan pagi hari, sesuai dengan tema yang diberikan. Format respons: hanya teks ayat beserta referensinya (contoh: "Kasih karunia dan damai sejahtera dari Allah, Bapa kita, dan dari Tuhan Yesus Kristus menyertai kamu. (Roma 1:7)"). Jangan tambahkan penjelasan atau teks lain.'
        : 'Kamu adalah asisten rohani Kristen. Berikan SATU ayat Alkitab yang relevan dan menenangkan untuk sapaan malam hari, sesuai dengan tema yang diberikan. Format respons: hanya teks ayat beserta referensinya (contoh: "Aku mau tidur dan langsung tertidur; sebab hanya Engkaulah, ya TUHAN, yang membiarkan aku diam dengan aman. (Mazmur 4:9)"). Jangan tambahkan penjelasan atau teks lain.';

    // Try all keys before giving up
    final totalKeys = Env.groqApiKeys.length;
    int attempts = 0;

    while (attempts < totalKeys) {
      try {
        final response = await _dio.post(
          _baseUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $_currentKey',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
          data: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': 'Tema: $tema'},
            ],
            'max_tokens': 200,
            'temperature': 0.7,
          }),
        );

        if (response.statusCode == 200) {
          final content =
              response.data['choices'][0]['message']['content'] as String;
          return content.trim();
        }

        // Non-200 but not an exception — treat as error
        throw Exception(
            'Groq error: ${response.statusCode} ${response.statusMessage}');
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        // 429 = rate limit, 401 = invalid key → rotate and retry
        if (statusCode == 429 || statusCode == 401) {
          _rotateKey();
          attempts++;
          continue;
        }

        // Other network/server errors — don't retry
        if (e.response != null) {
          throw Exception(
              'Groq API error: $statusCode - ${e.response?.statusMessage}');
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } catch (e) {
        throw Exception('Failed to generate ayat: $e');
      }
    }

    throw Exception(
        'Semua API key telah mencapai batas. Coba lagi nanti.');
  }
}
