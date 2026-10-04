import '../models.dart';
import 'db.dart';

class AlreadyAnsweredException implements Exception {}

class SurveyService {
  final Db _db = Db.instance;

  Set<String> _answeredKeys(dynamic responses, String residentId) {
    final out = <String>{};
    for (final e in entriesOf(responses)) {
      final v = e.value;
      if (v is Map && '${v['resident_id']}' == residentId) {
        out.add('${v['survey_id']}');
      }
    }
    return out;
  }

  /// Active surveys whose date window includes today (same rule as the web
  /// dashboard). Each one is flagged completed if this resident already
  /// answered it; open surveys are listed first.
  Future<List<SurveySummary>> available(String residentId) async {
    final results = await Future.wait([_db.get('surveys'), _db.get('responses')]);
    final today = Fmt.date(DateTime.now());
    final answered = _answeredKeys(results[1], residentId);
    final out = <SurveySummary>[];
    for (final e in entriesOf(results[0])) {
      final s = e.value;
      if (s is! Map) continue;
      final start = '${s['start_date'] ?? '9999-12-31'}';
      final end = '${s['end_date'] ?? '0000-01-01'}';
      final live = '${s['status']}' == 'active' &&
          start.compareTo(today) <= 0 &&
          today.compareTo(end) <= 0;
      if (live) {
        out.add(SurveySummary(
          e.key,
          '${s['title'] ?? 'Untitled survey'}',
          completed: answered.contains(e.key),
        ));
      }
    }
    // stable sort: open surveys first, completed ones below
    final open = out.where((s) => !s.completed);
    final done = out.where((s) => s.completed);
    return [...open, ...done];
  }

  Future<bool> hasAnswered(String residentId, String surveyKey) async {
    final r = await _db.get('responses');
    return _answeredKeys(r, residentId).contains(surveyKey);
  }

  Future<SurveyDetail?> load(String key) async {
    final s = await _db.get('surveys/$key');
    if (s is! Map) return null;
    final questions = <Question>[];
    for (final qe in entriesOf(s['questions'])) {
      final q = qe.value;
      if (q is! Map) continue;
      final choices = <Choice>[
        for (final ce in entriesOf(q['choices']))
          if (ce.value is Map)
            Choice(ce.key, '${(ce.value as Map)['choice_text'] ?? ''}'),
      ];
      questions.add(Question(
        id: qe.key,
        text: '${q['question_text'] ?? ''}',
        type: '${q['question_type'] ?? 'multiple_choice'}',
        required: asInt(q['is_required']) == 1,
        choices: choices,
      ));
    }
    return SurveyDetail(
      key: key,
      title: '${s['title'] ?? 'Survey'}',
      description: '${s['description'] ?? ''}',
      questions: questions,
    );
  }

  /// answers: questionId -> {'choice_id': ..., 'answer_text': ...}
  /// Written in the shape of the web tables responses / survey_results.
  Future<void> submit({
    required String residentId,
    required String residentName,
    required String surveyKey,
    required Map<String, Map<String, String>> answers,
  }) async {
    if (await hasAnswered(residentId, surveyKey)) {
      throw AlreadyAnsweredException();
    }
    var next = asInt(await _db.get('counters/responses')) + 1;
    while (await _db.get('responses/$next', shallow: true) != null) {
      next++;
    }
    await _db.patch('', {
      'responses/$next': {
        'survey_id': surveyKey,
        'resident_id': residentId,
        'resident_name': residentName,
        'submitted_at': Fmt.dateTime(DateTime.now()),
        'answers': {
          for (final e in answers.entries)
            e.key: {
              'question_id': e.key,
              'choice_id': e.value['choice_id'] ?? '',
              'answer_text': e.value['answer_text'] ?? '',
            },
        },
      },
      'counters/responses': next,
    });
  }
}
