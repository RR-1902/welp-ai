import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'glass_card.dart';

class QuestionCard extends StatefulWidget {
  const QuestionCard({
    super.key,
    required this.question,
  });

  final String question;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  Timer? _timer;
  String _visibleText = '';

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();
    _visibleText = '';
    final chars = widget.question.runes.map(String.fromCharCode).toList();
    var index = 0;
    _timer = Timer.periodic(AppConstants.typingDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index >= chars.length) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleText += chars[index];
        index += 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Interviewer',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            _visibleText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
