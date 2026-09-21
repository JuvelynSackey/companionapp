import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/assistant/gemini_assistant_service.dart';
import 'package:mobile/features/assistant/models/assistant_message.dart';

AssistantMessage _msg(MessageSender sender, String text) =>
    AssistantMessage(id: text, text: text, sender: sender, timestamp: DateTime(2030), isFallback: false);

AssistantMessage _user(String text) => _msg(MessageSender.user, text);
AssistantMessage _bot(String text) => _msg(MessageSender.assistant, text);

/// Records the request and answers with [body] / [status] instead of sending it.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.body, this.status = 200, this.fail = false});
  final Map<String, dynamic>? body;
  final int status;
  final bool fail;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    if (fail) throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    return ResponseBody.fromString(jsonEncode(body ?? {}), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _reply(String text) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    };

GeminiAssistantService _service(_Adapter adapter, {String apiKey = 'test-key'}) =>
    GeminiAssistantService(dio: Dio()..httpClientAdapter = adapter, apiKey: apiKey);

List<String> _roles(List<Map<String, dynamic>> contents) => [for (final c in contents) c['role'] as String];
List<String> _texts(List<Map<String, dynamic>> contents) =>
    [for (final c in contents) ((c['parts'] as List).first as Map)['text'] as String];

void main() {
  group('buildContents', () {
    test('with no history it is just the question, as a user turn', () {
      final contents = GeminiAssistantService.buildContents(history: const [], query: 'When is my exam?');
      expect(_roles(contents), ['user']);
      expect(_texts(contents), ['When is my exam?']);
    });

    test('earlier turns come first, in order, and the new question last', () {
      final contents = GeminiAssistantService.buildContents(
        history: [_user('What classes today?'), _bot('You have Maths at 10.')],
        query: 'And tomorrow?',
      );
      expect(_roles(contents), ['user', 'model', 'user']);
      expect(_texts(contents), ['What classes today?', 'You have Maths at 10.', 'And tomorrow?']);
    });

    test('the assistant side is sent as role "model", which is what Gemini expects', () {
      final contents = GeminiAssistantService.buildContents(history: [_user('hi'), _bot('hello')], query: 'ok');
      expect(_roles(contents), isNot(contains('assistant')));
    });

    test('only the most recent messages are sent', () {
      final history = [for (var i = 0; i < 30; i++) i.isEven ? _user('q$i') : _bot('a$i')];
      final contents = GeminiAssistantService.buildContents(history: history, query: 'now');

      // 10 kept history messages + the new question.
      expect(contents.length, GeminiAssistantService.maxHistoryMessages + 1);
      expect(_texts(contents).last, 'now');
      expect(_texts(contents).first, 'q20', reason: 'the 10 newest of 30 start at index 20');
    });

    test('a leading model turn is dropped (a conversation must start with the user)', () {
      final contents = GeminiAssistantService.buildContents(
        history: [_bot('orphan'), _user('hi'), _bot('hello')],
        query: 'more',
      );
      expect(_roles(contents), ['user', 'model', 'user']);
      expect(_texts(contents).first, 'hi');
    });

    test('consecutive turns from one side are merged so roles alternate', () {
      final contents = GeminiAssistantService.buildContents(
        history: [_user('one'), _user('two'), _bot('answer')],
        query: 'three',
      );
      expect(_roles(contents), ['user', 'model', 'user']);
      expect(_texts(contents).first, 'one\n\ntwo');
    });

    test('a trailing unanswered user turn is merged with the new question', () {
      final contents = GeminiAssistantService.buildContents(history: [_user('unanswered')], query: 'again');
      expect(_roles(contents), ['user']);
      expect(_texts(contents), ['unanswered\n\nagain']);
    });

    test('blank messages are skipped', () {
      final contents = GeminiAssistantService.buildContents(history: [_user('   '), _bot('')], query: 'hello');
      expect(_texts(contents), ['hello']);
    });
  });

  group('ask', () {
    test('sends the system prompt, the history and the question, and returns the reply', () async {
      final adapter = _Adapter(body: _reply('  You have Maths at 10.  '));
      final reply = await _service(adapter).ask(
        systemPrompt: 'You are the assistant.',
        query: 'And tomorrow?',
        history: [_user('What classes today?'), _bot('Maths at 10.')],
      );

      expect(reply, 'You have Maths at 10.', reason: 'trimmed');
      final sent = adapter.last!.data as Map;
      expect(((sent['systemInstruction'] as Map)['parts'] as List).first, {'text': 'You are the assistant.'});
      expect(_texts((sent['contents'] as List).cast<Map<String, dynamic>>()), [
        'What classes today?',
        'Maths at 10.',
        'And tomorrow?',
      ]);
      expect(adapter.last!.queryParameters['key'], 'test-key');
    });

    test('with no API key it makes no request and returns null', () async {
      final adapter = _Adapter(body: _reply('never used'));
      final reply = await _service(adapter, apiKey: '').ask(systemPrompt: 's', query: 'q');

      expect(reply, isNull);
      expect(adapter.last, isNull, reason: 'nothing was sent');
    });

    test('a network failure returns null so the caller can use the local engine', () async {
      expect(await _service(_Adapter(fail: true)).ask(systemPrompt: 's', query: 'q'), isNull);
    });

    test('an error status returns null', () async {
      expect(await _service(_Adapter(status: 429, body: {'error': 'quota'})).ask(systemPrompt: 's', query: 'q'), isNull);
    });

    test('empty, blank and malformed replies return null', () async {
      expect(await _service(_Adapter(body: {'candidates': []})).ask(systemPrompt: 's', query: 'q'), isNull);
      expect(await _service(_Adapter(body: _reply('   '))).ask(systemPrompt: 's', query: 'q'), isNull);
      expect(await _service(_Adapter(body: {'unexpected': true})).ask(systemPrompt: 's', query: 'q'), isNull);
    });
  });
}
