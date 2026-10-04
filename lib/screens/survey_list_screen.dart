import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db.dart';
import '../services/survey_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'survey_form_screen.dart';

class SurveyListScreen extends StatefulWidget {
  const SurveyListScreen({super.key, required this.session});
  final Session session;
  @override
  State<SurveyListScreen> createState() => _State();
}

class _State extends State<SurveyListScreen> {
  final _service = SurveyService();
  String _status = 'Loading surveys...';
  List<SurveySummary> _surveys = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = 'Loading surveys...');
    try {
      final list = await _service.available(widget.session.id);
      if (!mounted) return;
      setState(() {
        _surveys = list;
        _status = list.isEmpty
            ? 'No surveys available right now.'
            : list.every((s) => s.completed)
                ? "You're all caught up!"
                : 'Tap an open survey to start.';
      });
    } on DbException {
      if (!mounted) return;
      setState(() => _status =
          'Could not load surveys. Please check your connection and try again.');
    }
  }

  Future<void> _open(SurveySummary s) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            SurveyFormScreen(session: widget.session, surveyKey: s.key)));
    _load(); // an answered survey flips from Open to Completed
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.page,
        body: SafeArea(
          child: Col350(
            child: Column(children: [
              const Gap(12),
              Row(children: [
                const BackLink(label: '← Back', size: 15),
                Expanded(
                    child: Text('Available Surveys', style: ts(20, bold: true))),
              ]),
              const Gap(8),
              Container(
                width: double.infinity,
                color: C.white,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Help us improve our health services. Choose a survey to answer.',
                        style: ts(14, color: C.muted)),
                    const Gap(6),
                    Text(_status, style: ts(14, bold: true)),
                  ],
                ),
              ),
              const Gap(8),
              Expanded(
                child: Container(
                  color: C.white,
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _surveys.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: C.mint),
                      itemBuilder: (_, i) {
                        final s = _surveys[i];
                        return ListTile(
                          title: Text(s.title, style: ts(18)),
                          subtitle: Align(
                            alignment: Alignment.centerLeft,
                            child: _StatusPill(completed: s.completed),
                          ),
                          trailing: s.completed
                              ? null
                              : const Icon(Icons.chevron_right, color: C.green),
                          onTap: s.completed ? null : () => _open(s),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// Small "Open" / "Completed" badge shown under each survey title.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.completed});
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: completed ? C.mint : const Color(0xFFE7F1FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          completed ? 'Completed' : 'Open',
          style: ts(12,
              bold: true,
              color: completed ? C.deepGreen : const Color(0xFF1D5FD1)),
        ),
      );
}
