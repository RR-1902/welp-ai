import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/message_model.dart';
import '../utils/constants.dart';

class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          ),
        ) {
    debugPrint('Using production API: ${AppConstants.apiBaseUrl}');
  }

  final Dio _dio;

  Future<String> sendMessage(
    List<MessageModel> messages, {
    required String system,
    String? imageBase64,
  }) async {
    final body = {
      'messages': messages
          .map(
            (message) => {
              'role': message.role,
              'content': message.content,
            },
          )
          .toList(),
      'system': system,
      if (imageBase64 != null && imageBase64.isNotEmpty)
        'imageBase64': imageBase64,
    };

    try {
      debugPrint('API URL: ${AppConstants.apiBaseUrl}${AppConstants.chatEndpoint}');
      debugPrint('Request body: $body');
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/chat',
        data: body,
      );
      debugPrint('Response: ${response.data}');

      final reply = response.data?['reply'] as String?;
      if (reply == null || reply.trim().isEmpty) {
        throw const FormatException('Backend returned an empty reply.');
      }
      return reply;
    } on DioException catch (error) {
      debugPrint('ERROR TYPE: ${error.runtimeType}');
      debugPrint('ERROR: $error');
      debugPrint('Dio Error: ${error.message}');
      return _fallbackReply();
    } catch (error) {
      debugPrint('ERROR TYPE: ${error.runtimeType}');
      debugPrint('ERROR: $error');
      return _fallbackReply();
    }
  }

  Future<Map<String, dynamic>?> testRawChatConnection() async {
    try {
      final response = await Dio().post<Map<String, dynamic>>(
        '${AppConstants.apiBaseUrl}${AppConstants.chatEndpoint}',
        data: {
          'messages': [
            {'role': 'user', 'content': 'ping'}
          ],
          'system': 'Return a short test reply.',
        },
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      debugPrint('RAW TEST RESPONSE: ${response.data}');
      return response.data;
    } catch (error) {
      debugPrint('RAW TEST ERROR TYPE: ${error.runtimeType}');
      debugPrint('RAW TEST ERROR: $error');
      rethrow;
    }
  }

  Future<String> sendChat({
    required List<MessageModel> messages,
    required String system,
    String? imageBase64,
  }) {
    return sendMessage(
      messages,
      system: system,
      imageBase64: imageBase64,
    );
  }

  Future<void> uploadResume(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      await _dio.post(
        AppConstants.uploadResumeEndpoint,
        data: formData,
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (error) {
      final detail = error.response?.data.toString() ?? error.message;
      throw Exception('Resume upload failed: $detail');
    } catch (error) {
      throw Exception('Unable to upload resume: $error');
    }
  }

  String _fallbackReply() {
    return '''
{
  "question": "Let's continue. Tell me more about your experience.",
  "feedback": "The connection was interrupted, so Welp.Ai is keeping the interview moving. Answer with one clear example and highlight the impact you created.",
  "score": 75,
  "shouldEnd": false,
  "summary": ""
}
''';
  }
}
