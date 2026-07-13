import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/interview_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_glow_button.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  static const routeName = '/results';

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final PdfService _pdfService = PdfService();

  List<String> _strengths(InterviewProvider provider) {
    final strongTurns = provider.turns.where((turn) => turn.score >= 75).toList();
    if (strongTurns.isEmpty) {
      return const [
        'Stayed engaged throughout the interview.',
        'Answered each question with relevant intent.',
      ];
    }
    return strongTurns
        .map((turn) => 'Strong answer on: ${turn.question}')
        .take(3)
        .toList();
  }

  List<String> _weaknesses(InterviewProvider provider) {
    final weakTurns = provider.turns.where((turn) => turn.score < 75).toList();
    if (weakTurns.isEmpty) {
      return const ['No major weaknesses stood out in this session.'];
    }
    return weakTurns
        .map((turn) => 'Needs more depth or metrics on: ${turn.question}')
        .take(3)
        .toList();
  }

  List<String> _suggestions(InterviewProvider provider) {
    final suggestions = provider.turns
        .map((turn) => turn.feedback)
        .where((feedback) => feedback.trim().isNotEmpty)
        .take(3)
        .toList();
    if (suggestions.isEmpty) {
      return const [
        'Use situation, action, and result to structure each answer.',
        'Add metrics and measurable outcomes where possible.',
      ];
    }
    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();
    final theme = Theme.of(context);
    final scoreOutOfTen =
        (provider.averageScore / 10).clamp(0, 10).toStringAsFixed(1);
    final strengths = _strengths(provider);
    final weaknesses = _weaknesses(provider);
    final suggestions = _suggestions(provider);

    return Scaffold(
      appBar: AppBar(title: const BrandAppBarTitle()),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF04161D), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 48),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interview Complete',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 118,
                            height: 118,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF00B8FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.35),
                                  blurRadius: 30,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                scoreOutOfTen,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: Colors.black,
                                  fontSize: 34,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall Score',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Out of 10',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF00E5FF),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  provider.finalSummary,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _InsightCard(
                  title: 'Strengths',
                  items: strengths,
                  icon: Icons.trending_up_rounded,
                ),
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'Weaknesses',
                  items: weaknesses,
                  icon: Icons.insights_rounded,
                ),
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'Suggestions',
                  items: suggestions,
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryGlowButton(
                    label: 'Export as PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    onPressed: () async {
                      await _pdfService.generateInterviewPdf(
                        messages: provider.messages,
                        score: scoreOutOfTen,
                        summary: provider.finalSummary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryGlowButton(
                    label: 'Start Another Session',
                    icon: Icons.refresh_rounded,
                    onPressed: () async {
                      await context.read<InterviewProvider>().resetSession();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        HomeScreen.routeName,
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.items,
    required this.icon,
  });

  final String title;
  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF00E5FF).withOpacity(0.14),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withOpacity(0.28),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      icon,
                      size: 16,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
