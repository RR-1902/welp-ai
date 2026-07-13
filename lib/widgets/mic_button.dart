import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isListening ? 1 : 0.72,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isListening ? 1.04 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isListening
                    ? const [Color(0xFFFF7B72), Color(0xFFFF4D6D)]
                    : const [Color(0xFF6EA8FE), Color(0xFF6CE5B1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isListening
                          ? const Color(0xFFFF4D6D)
                          : const Color(0xFF6EA8FE))
                      .withOpacity(isListening ? 0.5 : 0.35),
                  blurRadius: isListening ? 34 : 26,
                  spreadRadius: isListening ? 4 : 2,
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: Colors.black,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
