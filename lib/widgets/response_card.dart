import 'package:flutter/material.dart';

import 'glass_card.dart';

class ResponseCard extends StatelessWidget {
  const ResponseCard({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Response',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Speak or type your answer here...',
            ),
          ),
        ],
      ),
    );
  }
}
