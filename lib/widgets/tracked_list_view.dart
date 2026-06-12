import 'package:flutter/material.dart';

import '../app/app_controller.dart';

class TrackedListView extends StatefulWidget {
  const TrackedListView({
    super.key,
    required this.children,
    required this.controller,
    required this.screenName,
  });

  final List<Widget> children;
  final AppController controller;
  final String screenName;

  @override
  State<TrackedListView> createState() => _TrackedListViewState();
}

class _TrackedListViewState extends State<TrackedListView> {
  int _maxDepth = 0;
  int _lastReportedDepth = 0;

  @override
  void dispose() {
    _reportDepth();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView(children: widget.children),
    );
  }

  bool _onScroll(ScrollNotification notification) {
    final maxScrollExtent = notification.metrics.maxScrollExtent;
    if (maxScrollExtent <= 0) {
      return false;
    }

    final depth = ((notification.metrics.pixels / maxScrollExtent) * 100)
        .clamp(0, 100)
        .round();
    if (depth > _maxDepth) {
      _maxDepth = depth;
    }

    if (notification is ScrollEndNotification) {
      _reportDepth();
    }

    return false;
  }

  void _reportDepth() {
    if (_maxDepth < _lastReportedDepth + 10 && _maxDepth < 100) {
      return;
    }

    _lastReportedDepth = _maxDepth;
    widget.controller.trackScrollDepth(widget.screenName, _maxDepth);
  }
}
