import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db.dart';
import '../services/resident_service.dart';
import '../services/survey_service.dart';
import '../theme.dart';
import '../widgets.dart';

class SurveyFormScreen extends StatefulWidget {
  const SurveyFormScreen(
      {super.key, required this.session, required this.surveyKey});
  final Session session;
  final String surveyKey;
  @override
  State<SurveyFormScreen> createState() => _State();
}

class _State extends State<SurveyFormScreen> {
  final _surveys = SurveyService();
  final _residents = ResidentService();
  final _text = TextEditingController();

  SurveyDetail? _survey;
  String _residentName = '';
  String? _error;
  int _index = 0;
  bool _busy = false;

  /// questionId -> {'choice_id': ..., 'answer_text': ...}
  final Map<String, Map<String, String>> _answers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      if (await _surveys.hasAnswered(widget.session.id, widget.surveyKey)) {
        _leave('You have already answered this survey.');
        return;
      }
      final results = await Future.wait([
        _surveys.load(widget.surveyKey),
        _residents.load(widget.session.id),
      ]);
      final survey = results[0] as SurveyDetail?;
      final resident = results[1] as Resident?;
      if (!mounted) return;
      if (survey == null) {
        _leave('Survey not found.');
        return;
      }
      if (survey.questions.isEmpty) {
        _leave('This survey has no questions yet.');
        return;
      }
      setState(() {
        _survey = survey;
        _residentName = resident?.fullName ?? '';
      });
      _syncText();
    } on DbException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _leave(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop();
  }

  Question get _q => _survey!.questions[_index];
  bool get _isLast => _index == _survey!.questions.length - 1;

  /// Loads the saved answer for the current question into the text box.
  void _syncText() => _text.text = _answers[_q.id]?['answer_text'] ?? '';

  bool get _answered {
    final a = _answers[_q.id];
    if (_q.isText) return _text.text.trim().isNotEmpty;
    return a != null && (a['choice_id'] ?? '').isNotEmpty;
  }

  void _store() {
    if (_q.isText) {
      _answers[_q.id] = {'choice_id': '', 'answer_text': _text.text.trim()};
    }
  }

  void _prev() {
    if (_index == 0) return;
    _store();
    setState(() => _index--);
    _syncText();
  }

  Future<void> _next() async {
    if (_busy) return;
    if (_q.required && !_answered) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please answer this question to continue.')));
      return;
    }
    _store();
    if (!_isLast) {
      setState(() => _index++);
      _syncText();
      return;
    }
    setState(() => _busy = true);
    try {
      // drop empty optional answers, like the web form
      final toSend = <String, Map<String, String>>{
        for (final e in _answers.entries)
          if ((e.value['choice_id'] ?? '').isNotEmpty ||
              (e.value['answer_text'] ?? '').isNotEmpty)
            e.key: e.value,
      };
      await _surveys.submit(
        residentId: widget.session.id,
        residentName: _residentName,
        surveyKey: widget.surveyKey,
        answers: toSend,
      );
      _leave('Thank you! Your response has been submitted.');
    } on AlreadyAnsweredException {
      _leave('You have already answered this survey.');
    } on DbException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _survey;
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Col350(
            child: Column(children: [
              const Gap(12),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: BackLink(label: '← Back to Surveys', size: 14)),
              Container(
                width: double.infinity,
                color: C.white,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s?.title ?? (_error ?? 'Loading...'),
                        style: ts(20, bold: true)),
                    if (s != null && s.description.isNotEmpty)
                      Text(s.description, style: ts(14, color: C.muted)),
                    if (s != null)
                      Text('Question ${_index + 1} of ${s.questions.length}',
                          style: ts(13, bold: true, color: C.green)),
                  ],
                ),
              ),
              const Gap(10),
              if (s != null) ..._question(),
            ]),
          ),
        ),
      ),
    );
  }

  List<Widget> _question() {
    final q = _q;
    final picked = _answers[q.id]?['choice_id'] ?? '';
    return [
      Container(
        width: double.infinity,
        color: C.white,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.required ? '${q.text} *' : q.text, style: ts(17, bold: true)),
            const Gap(8),
            if (q.isText)
              TextField(
                controller: _text,
                minLines: 5,
                maxLines: 5,
                style: ts(14),
                decoration: const InputDecoration(
                  hintText: 'Type your answer here',
                  filled: true,
                  fillColor: C.field,
                  border: InputBorder.none,
                ),
              )
            else
              for (final c in q.choices)
                Material(
                  color: picked == c.id ? C.mint : C.white,
                  child: InkWell(
                    onTap: () => setState(() => _answers[q.id] = {
                          'choice_id': c.id,
                          'answer_text': '',
                        }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Row(children: [
                        Expanded(child: Text(c.text, style: ts(17))),
                        if (picked == c.id)
                          const Icon(Icons.check_circle, color: C.green),
                      ]),
                    ),
                  ),
                ),
          ],
        ),
      ),
      const Gap(12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (_index > 0) ...[
          AppButton(
            label: 'Previous',
            onPressed: _prev,
            background: C.mint,
            foreground: C.green,
            width: 150,
            size: 14,
            radius: 15,
          ),
          const SizedBox(width: 12),
        ],
        AppButton(
          label: _busy ? 'Please wait...' : (_isLast ? 'Submit' : 'Next'),
          onPressed: _busy ? null : _next,
          width: 150,
          size: 14,
          radius: 15,
        ),
      ]),
      const Gap(25),
    ];
  }
}
