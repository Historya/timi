import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:timi/services/dashscope_asr_service.dart';

void main() {
  group('DashScopeAsrService.extractTranscriptFromResponse', () {
    test('result-generated 提取文本', () {
      final response = jsonDecode('''
      {
        "header": {
          "action": "result-generated",
          "task_id": "test-123",
          "status_code": 200000
        },
        "payload": {
          "output": {
            "sentence": {
              "text": "\u5348\u9910\u6d88\u8d39 38 \u5143",
              "begin_time": 100,
              "end_time": 1500
            }
          }
        }
      }
      ''') as Map<String, dynamic>;
      final text =
          DashScopeAsrService.extractTranscriptFromResponse(response);
      expect(text, '午餐消费 38 元');
    });

    test('task-finished 提取最终文本', () {
      final response = jsonDecode('''
      {
        "header": {
          "action": "task-finished",
          "task_id": "test-123",
          "status_code": 200000
        },
        "payload": {
          "output": {
            "sentence": {
              "text": "\u6253\u8f66 23 \u5757\u94b1",
              "begin_time": 100,
              "end_time": 2000
            }
          }
        }
      }
      ''') as Map<String, dynamic>;
      final text =
          DashScopeAsrService.extractTranscriptFromResponse(response);
      expect(text, '打车 23 块钱');
    });

    test('task-started 返回 null', () {
      final response = jsonDecode('''
      {
        "header": {
          "action": "task-started",
          "task_id": "test-123",
          "status_code": 200000
        },
        "payload": {}
      }
      ''') as Map<String, dynamic>;
      final text =
          DashScopeAsrService.extractTranscriptFromResponse(response);
      expect(text, isNull);
    });

    test('空文本返回空字符串', () {
      final response = jsonDecode('''
      {
        "header": {
          "action": "result-generated",
          "task_id": "test-123",
          "status_code": 200000
        },
        "payload": {
          "output": {
            "sentence": {
              "text": "",
              "begin_time": 100,
              "end_time": 200
            }
          }
        }
      }
      ''') as Map<String, dynamic>;
      final text =
          DashScopeAsrService.extractTranscriptFromResponse(response);
      expect(text, '');
    });

    test('缺失 sentence 字段返回 null', () {
      final response = jsonDecode('''
      {
        "header": {
          "action": "result-generated",
          "task_id": "test-123",
          "status_code": 200000
        },
        "payload": {
          "output": {}
        }
      }
      ''') as Map<String, dynamic>;
      final text =
          DashScopeAsrService.extractTranscriptFromResponse(response);
      expect(text, isNull);
    });

    test('task-failed 返回 null', () {
      final response = jsonDecode('''
      {
        "header": {
          "action": "task-failed",
          "task_id": "test-123",
          "status_code": 400100
        },
        "payload": {
          "message": "Invalid API Key"
        }
      }
      ''') as Map<String, dynamic>;
      final text =
          DashScopeAsrService.extractTranscriptFromResponse(response);
      expect(text, isNull);
    });

    test('错误状态码 >= 400 返回 null', () {
      final response = jsonDecode('''
      {
        "header": {
          "action": "result-generated",
          "task_id": "test-123",
          "status_code": 400100
        },
        "payload": {
          "message": "Unauthorized"
        }
      }
      ''') as Map<String, dynamic>;
      final text =
          DashScopeAsrService.extractTranscriptFromResponse(response);
      expect(text, isNull);
    });

    test('未知 action 返回 null', () {
      final response = jsonDecode('''
      {
        "header": {
          "action": "unknown-action",
          "task_id": "test-123",
          "status_code": 200000
        },
        "payload": {}
      }
      ''') as Map<String, dynamic>;
      final text =
          DashScopeAsrService.extractTranscriptFromResponse(response);
      expect(text, isNull);
    });
  });
}
