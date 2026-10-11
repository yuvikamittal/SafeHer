// Verifies the Safety Assistant returns a distinct, relevant reply for each
// quick prompt — guards against the "safe route" → generic-"safe" regression.

import 'package:flutter_test/flutter_test.dart';

import 'package:safeher/services/assistant_service.dart';

void main() {
  final svc = AssistantService.instance;

  test('each quick prompt maps to its own relevant reply', () {
    final route = svc.keywordReplyTo('Plan a safe route home');
    final area = svc.keywordReplyTo('Is my area safe right now?');
    final emergency = svc.keywordReplyTo('What to do in an emergency?');
    final location = svc.keywordReplyTo('Share my location with contacts');

    // Correct intent per prompt.
    expect(route, contains('Recommended'));
    expect(area, contains('safety score of 84'));
    expect(emergency, contains('Emergency Steps'));
    expect(location, contains('live location'));

    // The regression: "safe route" must NOT return the area-safety reply.
    expect(route, isNot(equals(area)));

    // All four prompts produce four different replies.
    expect({route, area, emergency, location}.length, 4);
  });

  test('safety tips and unknown input still resolve', () {
    expect(svc.keywordReplyTo('give me a safety tip'), contains('Safety Tips'));
    expect(svc.keywordReplyTo('xyzzy random text'), contains('analysing your request'));
  });
}
