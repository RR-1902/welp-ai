import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/interview_provider.dart';
import '../utils/helpers.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_glow_button.dart';
import 'setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF07131A), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Start Interview',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to your AI-powered interview system. Practice real-world questions, improve your confidence, and receive intelligent feedback to grow.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Snapshot',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.turns.isEmpty
                            ? 'No completed interview yet. Start a session to see scoring insights.'
                            : 'Last average score: ${Helpers.formatAverage(provider.turns)}/100',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryGlowButton(
                    label: 'Start New Interview',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.pushNamed(context, SetupScreen.routeName);
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
