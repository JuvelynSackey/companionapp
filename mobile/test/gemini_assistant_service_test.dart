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
/// [earlierStatuses] are answered first, one per request, with an error body.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.body, this.status = 200, this.fail = false, List<int> earlierStatuses = const []})
      : _earlier = [...earlierStatuses];
  final Map<String, dynamic>? body;
  final int status;
  final bool fail;
  final List<int> _earlier;
  RequestOptions? last;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    requests++;
    if (fail) throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    if (_earlier.isNotEmpty) {
      return ResponseBody.fromString(jsonEncode({'error': 'busy'}), _earlier.removeAt(0), headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
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
    GeminiAssistantService(dio: Dio()..httpClientAdapter = adapter, apiKey: apiKey, retryDelay: Duration.zero);

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

    test('a busy reply (503 or 429) is retried once, and the retry\'s answer is used', () async {
      for (final busy in [503, 429]) {
        final adapter = _Adapter(earlierStatuses: [busy], body: _reply('Second time lucky.'));
        expect(await _service(adapter).ask(systemPrompt: 's', query: 'q'), 'Second time lucky.');
        expect(adapter.requests, 2, reason: 'one retry after $busy');
      }
    });

    test('the request goes to Flash-Lite, and a busy retry goes to the other model', () async {
      final adapter = _Adapter(earlierStatuses: [503], body: _reply('ok'));
      final seen = <String>[];
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        seen.add(options.path);
        handler.next(options);
      }));
      final service = GeminiAssistantService(dio: dio, apiKey: 'k', retryDelay: Duration.zero);
      expect(await service.ask(systemPrompt: 's', query: 'q'), 'ok');
      expect(seen.first, contains('/models/gemini-3.5-flash-lite:generateContent'));
      expect(seen.last, contains('/models/gemini-3.1-flash-lite:generateContent'));
    });

    test('attached slides are sent once, inline, with the newest question', () async {
      final adapter = _Adapter(body: _reply('From slide 3.'));
      final slides = GeminiAttachment(name: 'week3.pdf', mimeType: 'application/pdf', bytes: Uint8List.fromList([1, 2, 3]));
      final answer = await _service(adapter).ask(
        systemPrompt: 's',
        query: 'Summarise these slides',
        history: [_user('Hi'), _bot('Hello')],
        attachment: slides,
      );
      expect(answer, 'From slide 3.');
      final contents = (adapter.last!.data as Map)['contents'] as List;
      expect(contents.length, 3);
      final lastParts = (contents.last as Map)['parts'] as List;
      expect((lastParts.first as Map)['inline_data'], {'mime_type': 'application/pdf', 'data': base64Encode([1, 2, 3])});
      expect((lastParts.last as Map)['text'], 'Summarise these slides');
      expect(((contents.first as Map)['parts'] as List).length, 1, reason: 'earlier turns carry no file');
    });

    test('a second busy reply gives up (null) instead of retrying again', () async {
      final adapter = _Adapter(earlierStatuses: [503, 503], body: _reply('never reached'));
      expect(await _service(adapter).ask(systemPrompt: 's', query: 'q'), isNull);
      expect(adapter.requests, 2);
    });

    test('other errors are not retried', () async {
      final badRequest = _Adapter(status: 400, body: {'error': 'bad'});
      expect(await _service(badRequest).ask(systemPrompt: 's', query: 'q'), isNull);
      expect(badRequest.requests, 1);

      final offline = _Adapter(fail: true);
      expect(await _service(offline).ask(systemPrompt: 's', query: 'q'), isNull);
      expect(offline.requests, 1);
    });

    test('empty, blank and malformed replies return null', () async {
      expect(await _service(_Adapter(body: {'candidates': []})).ask(systemPrompt: 's', query: 'q'), isNull);
      expect(await _service(_Adapter(body: _reply('   '))).ask(systemPrompt: 's', query: 'q'), isNull);
      expect(await _service(_Adapter(body: {'unexpected': true})).ask(systemPrompt: 's', query: 'q'), isNull);
    });
  });
}
