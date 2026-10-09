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

/// Which slice of the survey list is showing.
enum _Tab { open, completed, all }

class _State extends State<SurveyListScreen> {
  final _service = SurveyService();
  bool _loading = true;
  String _error = '';
  List<SurveySummary> _surveys = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<SurveySummary> get _openList =>
      _surveys.where((s) => !s.completed).toList();

  List<SurveySummary> get _doneList =>
      _surveys.where((s) => s.completed).toList();

  /// SurveyService.available already returns active surveys only, sorted open
  /// first, so the tabs filter in memory instead of re-querying.
  List<SurveySummary> _for(_Tab tab) => switch (tab) {
        _Tab.open => _openList,
        _Tab.completed => _doneList,
        _Tab.all => _surveys,
      };

  String _emptyFor(_Tab tab) => switch (tab) {
        _Tab.open => _openList.isEmpty && _doneList.isEmpty
            ? 'No surveys available right now.'
            : "You're all caught up!",
        _Tab.completed => 'No completed surveys yet.',
        _Tab.all => 'No surveys available right now.',
      };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final list = await _service.available(widget.session.id);
      if (!mounted) return;
      setState(() {
        _surveys = list;
        _loading = false;
      });
    } on DbException {
      if (!mounted) return;
      setState(() {
        _surveys = [];
        _loading = false;
        _error =
            'Could not load surveys. Please check your connection and try again.';
      });
    }
  }

  Future<void> _open(SurveySummary s) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            SurveyFormScreen(session: widget.session, surveyKey: s.key)));
    _load(); // an answered survey flips from Open to Completed
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: C.page,
          body: SafeArea(
            child: Col350(
              child: Column(children: [
                const Gap(12),
                Row(children: [
                  const BackLink(label: '← Back', size: 15),
                  Expanded(
                      child: Text('Available Surveys',
                          style: ts(20, bold: true))),
                ]),
                const Gap(8),
                Container(
                  width: double.infinity,
                  color: C.white,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Help us improve our health services. Choose a survey to answer.',
                          style: ts(14, color: C.muted)),
                      const Gap(6),
                      TabBar(
                        isScrollable: false,
                        labelColor: C.deepGreen,
                        unselectedLabelColor: C.muted,
                        indicatorColor: C.green,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: C.mint,
                        labelStyle: ts(12, bold: true),
                        unselectedLabelStyle: ts(12),
                        tabs: [
                          Tab(text: 'Open (${_openList.length})'),
                          Tab(text: 'Completed (${_doneList.length})'),
                          Tab(text: 'All (${_surveys.length})'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: Container(
                    color: C.white,
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: TabBarView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          for (final tab in _Tab.values) _table(tab),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );

  /// One tab's page: the status table, or an empty-state message.
  Widget _table(_Tab tab) {
    if (_loading) return _message('Loading surveys...');
    if (_error.isNotEmpty) return _message(_error);
    final rows = _for(tab);
    if (rows.isEmpty) return _message(_emptyFor(tab));

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length + 1, // header row + surveys
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: C.mint),
      itemBuilder: (_, i) {
        if (i == 0) return const _TableHeader();
        final s = rows[i - 1];
        return InkWell(
          onTap: s.completed ? null : () => _open(s),
          child: Container(
            color: C.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(children: [
              Expanded(
                child: Text(s.title,
                    style: ts(15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              _StatusPill(completed: s.completed),
            ]),
          ),
        );
      },
    );
  }

  Widget _message(String text) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Gap(40),
          Text(text,
              textAlign: TextAlign.center, style: ts(14, bold: true)),
        ],
      );
}

/// Column headings for the survey table.
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Container(
        color: C.field,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(children: [
          Expanded(
              child: Text('SURVEY',
                  style: ts(12, bold: true, color: C.deepGreen))),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Text('STATUS',
                textAlign: TextAlign.center,
                style: ts(12, bold: true, color: C.deepGreen)),
          ),
        ]),
      );
}

/// Small "Open" / "Completed" badge shown in the status column.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.completed});
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
      width: 92,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed ? C.mint : const Color(0xFFE7F1FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        completed ? 'Completed' : 'Open',
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        style: ts(12,
            bold: true,
            color: completed ? C.deepGreen : const Color(0xFF1D5FD1)),
      ),
    );
}