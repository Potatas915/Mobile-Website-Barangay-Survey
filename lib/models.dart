/// Signed-in resident: [id] is the database key (residents/<id>),
/// [number] is the resident number the person types (e.g. 2026-0001).
class Session {
  const Session({required this.id, required this.number});
  final String id;
  final String number;
}

class Resident {
  Resident(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;

  String s(String key) {
    final v = data[key];
    return v == null ? '' : v.toString();
  }

  String get number => s('resident_number');
  String get fullName => '${s('first_name')} ${s('last_name')}'.trim();
}

class Choice {
  const Choice(this.id, this.text);
  final String id;
  final String text;
}

class Question {
  const Question({
    required this.id,
    required this.text,
    required this.type,
    required this.required,
    required this.choices,
  });
  final String id;
  final String text;
  final String type;
  final bool required;
  final List<Choice> choices;
  bool get isText => type == 'short_answer';
}

class SurveySummary {
  const SurveySummary(this.key, this.title, {this.completed = false});
  final String key;
  final String title;

  /// true once this resident has submitted an answer for the survey.
  final bool completed;
}

class SurveyDetail {
  const SurveyDetail({
    required this.key,
    required this.title,
    required this.description,
    required this.questions,
  });
  final String key;
  final String title;
  final String description;
  final List<Question> questions;
}

class Fmt {
  static String two(int n) => n.toString().padLeft(2, '0');
  static String date(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
  static String dateTime(DateTime d) =>
      '${date(d)} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// "2026-09-28 16:45:00" -> "Sep 28, 2026". Anything else is returned as is.
  static String pretty(String raw) {
    final d = DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
    if (d == null) return raw;
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
