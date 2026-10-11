import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

/// Safety Assistant.
///
/// [replyTo] calls the Gemini API with full conversation history. If no API
/// key is configured, the device is offline, or the call fails, it silently
/// falls back to the original keyword-matched canned replies so the chat
/// always works.
class AssistantService {
  AssistantService._();
  static final AssistantService instance = AssistantService._();

  // ── Gemini configuration ──────────────────────────────────────────────
  // Key lives in lib/config/api_keys.dart (gitignored).
  static const String _apiKey = geminiApiKey;

  static const String _model = 'gemini-2.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static const String _systemPrompt =
      'You are the SafeHer Safety Assistant — a calm, supportive AI inside a '
      "women's personal safety app in India. Help with: personal safety advice, "
      'safe-route planning, area safety awareness, emergency guidance, and '
      'using app features (SOS button, live location sharing with trusted '
      'contacts). Key emergency numbers: 112 (National Emergency), '
      '181 (Women Helpline), 1091 (Women Police Helpline). '
      'Keep replies short (under 120 words), practical, and reassuring. Use '
      'occasional relevant emojis like the app does (🛡️ 🗺️ 🚨 📍 💡). '
      'If the user seems to be in immediate danger, first tell them to call '
      '112 and press the SOS button in the app. Never invent live data like '
      'exact safety scores or route times — speak in general, honest terms.';

  /// In-memory conversation history sent to Gemini on every turn.
  final List<Map<String, dynamic>> _history = [];

  static const String welcome =
      "👋 Hi! I'm your Safety Assistant. I'm here to help you stay safe.\n\n"
      'You can ask me about safe routes, nearby safety scores, emergency steps, '
      'or safety tips. How can I help you today?';

  static const List<String> quickPrompts = [
    'Is my area safe right now?',
    'Plan a safe route home',
    'What to do in an emergency?',
    'Share my location with contacts',
  ];

  /// Clears conversation memory (call when the chat screen is disposed).
  void resetConversation() => _history.clear();

  /// Returns an AI reply from Gemini, falling back to keyword matching on
  /// any failure so the assistant keeps working offline.
  Future<String> replyTo(String input) async {
    if (_apiKey.isEmpty) return keywordReplyTo(input);

    _history.add({
      'role': 'user',
      'parts': [
        {'text': input},
      ],
    });

    try {
      final res = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': _systemPrompt},
                ],
              },
              'contents': _history,
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 300,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (((data['candidates'] as List?)?.first
                  as Map<String, dynamic>?)?['content']?['parts'] as List?)
              ?.map((p) => (p as Map<String, dynamic>)['text'] ?? '')
              .join()
              .trim() ??
          '';

      if (text.isEmpty) throw Exception('Empty response');

      _history.add({
        'role': 'model',
        'parts': [
          {'text': text},
        ],
      });
      return text;
    } catch (e) {
      // ignore: avoid_print
      print('Gemini error: $e');
      // Remove the failed turn so history stays valid, then fall back.
      _history.removeLast();
      return keywordReplyTo(input);
    }
  }

  // ── Offline keyword fallback (original mock behaviour) ────────────────

  static const String _fallback =
      "🤔 I'm analysing your request. For best results, try asking about safe "
      "routes, your area's safety, emergency steps, location sharing, or safety tips.";

  static const Map<String, String> _responses = {
    'safe':
        '🛡️ Based on current reports, your area has a safety score of 84/100. '
        'No critical incidents in the last 2 hours. Street lighting is adequate '
        'and foot traffic is moderate. I recommend staying on main roads if heading out.',
    'route':
        '🗺️ Analysing routes from your current location…\n\n'
        'Recommended: MG Road → Park Street\n'
        '• Distance: 2.1 km · ~14 min walk\n'
        '• Safety score: 92%\n'
        '• Well-lit, CCTV coverage, active foot traffic\n\n'
        'Would you like me to share this with your trusted contacts?',
    'emergency':
        '🚨 Emergency Steps:\n\n'
        '1. Move to a public, well-lit area immediately\n'
        '2. Call 112 (National Emergency)\n'
        '3. Use the SOS button in this app to alert your contacts\n'
        '4. Stay on the line with emergency services\n'
        '5. Share your live location with trusted contacts\n\n'
        'Shall I activate SOS mode now?',
    'location':
        '📍 Your live location is ready to share. I can send it to your 3 trusted '
        'contacts — Priya, Meena, and Mom — with a message "I am heading home, '
        'tracking active."\n\nShall I share now?',
    'tip':
        "💡 Today's Safety Tips:\n\n"
        '• Avoid poorly lit shortcuts after 8 PM\n'
        '• Keep your phone charged above 20%\n'
        '• Trust your instincts — change routes if uncomfortable\n'
        '• Walk confidently and stay aware of surroundings\n'
        '• Save 112, 181 (Women Helpline) on speed dial',
  };

  /// Returns a canned reply for [input] using keyword matching.
  ///
  /// Intents are checked in priority order — more specific first — so a phrase
  /// like "plan a safe route home" matches the route intent rather than the
  /// generic "safe" (area) intent that shares the word "safe".
  String keywordReplyTo(String input) {
    final lower = input.toLowerCase();
    final intents = <(String, List<String>)>[
      ('route', [
        'route',
        'navigat',
        'direction',
        'way home',
        'get home',
        'walk home',
        'reach home',
        'go home',
      ]),
      ('emergency', [
        'emergency',
        'danger',
        'attack',
        'sos',
        'help me',
        'unsafe',
        'follow',
        'scared',
        'threat',
        'harass',
      ]),
      ('location', [
        'location',
        'share',
        'track',
        'contacts',
        'where am i',
      ]),
      ('tip', ['tip', 'advice', 'precaution', 'suggestion']),
      ('safe', [
        'safe',
        'area',
        'safety score',
        'risk',
        'right now',
        'around me',
      ]),
    ];
    for (final (key, keywords) in intents) {
      for (final kw in keywords) {
        if (lower.contains(kw)) return _responses[key]!;
      }
    }
    return _fallback;
  }
}
