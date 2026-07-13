import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/interview_turn.dart';

class Helpers {
  static String buildInterviewSystemPrompt({
    required String role,
    required String mode,
    required String difficulty,
    required String persona,
    required int questionCount,
    String? topic,
    bool hasResume = false,
  }) {
    final effectiveTopic = (topic?.trim().isNotEmpty ?? false) ? topic : role;
    return '''
You are a professional job interviewer running a realistic mobile interview session.
Interview mode: $mode
Primary role/topic: $effectiveTopic
Difficulty: $difficulty
Interviewer persona: $persona
Total questions: $questionCount
Resume uploaded: ${hasResume ? 'yes' : 'no'}

Rules:
- The first question is already fixed by the app as: "Tell me about yourself."
- Ask one question at a time.
- After the user answers:
  1. Give feedback covering strengths and improvements.
  2. Ask the next question.
- If a resume has been uploaded, ask resume-based follow-up questions whenever relevant.
- Make follow-up questions dynamic based on the user's previous answers.
- Keep feedback specific, concise, and actionable.
- Maintain a professional tone.
- Return strict JSON only, with no markdown.
- Use this schema:
{
  "question": "string",
  "feedback": "string",
  "score": 0,
  "shouldEnd": false,
  "summary": "string"
}
- For the first response, give the first interview question and set feedback to an empty string, score to 0, shouldEnd to false.
- After the final answer, set shouldEnd to true, provide a final score out of 10 within summary, and question can be empty.
''';
  }

  static Map<String, dynamic> parseAiPayload(String rawReply) {
    try {
      return jsonDecode(rawReply) as Map<String, dynamic>;
    } catch (_) {
      final firstBrace = rawReply.indexOf('{');
      final lastBrace = rawReply.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        final sliced = rawReply.substring(firstBrace, lastBrace + 1);
        try {
          return jsonDecode(sliced) as Map<String, dynamic>;
        } catch (_) {
          return _fallbackPayload(rawReply);
        }
      }
      return _fallbackPayload(rawReply);
    }
  }

  static Map<String, dynamic> _fallbackPayload(String rawReply) {
    final scoreMatch = RegExp(r'(\b\d{1,3}\b)').firstMatch(rawReply);
    final parsedScore = int.tryParse(scoreMatch?.group(1) ?? '');
    return {
      'question': rawReply,
      'feedback': rawReply,
      'score': min(max(parsedScore ?? 80, 0), 100),
      'shouldEnd': false,
      'summary': '',
    };
  }

  static Map<String, dynamic> buildMockInterviewPayload({
    required int questionNumber,
    required int maxQuestions,
    required String role,
    required String latestAnswer,
    bool hasResume = false,
  }) {
    final prompts = [
      'Tell me about yourself.',
      'Describe a project where you solved a difficult problem under pressure.',
      if (hasResume)
        'Walk me through one achievement from your resume that best prepared you for this role.'
      else
        'How does your past experience prepare you for this role?',
      'How do you prioritize when multiple deadlines compete for your attention?',
      'Tell me about a time you handled critical feedback and improved your work.',
      'What makes you a strong fit for this role, and where are you still growing?',
      'If you joined tomorrow, what impact would you want to make in your first 90 days?',
    ];

    final safeIndex = questionNumber.clamp(0, prompts.length - 1);
    final fallbackQuestion = prompts[safeIndex].replaceAll('this role', role);
    final shouldEnd = questionNumber >= maxQuestions;

    return {
      'question': shouldEnd ? '' : fallbackQuestion,
      'feedback': latestAnswer.trim().isEmpty
          ? 'Give a structured answer using situation, action, and result.'
          : 'You communicated clearly. Strengths: solid intent and relevant context. Improvements: add sharper metrics, name your decisions, and close with measurable impact.',
      'score': latestAnswer.trim().isEmpty ? 68 : 78,
      'shouldEnd': shouldEnd,
      'summary': shouldEnd
          ? 'Final score: 8/10. Strengths: clear communication, composure, and relevant examples. Weaknesses: answers can use more metrics and stronger outcomes. Suggestions: structure each response with context, action, and measurable impact.'
          : '',
    };
  }

  static double averageScore(List<InterviewTurn> turns) {
    if (turns.isEmpty) {
      return 0;
    }
    final total = turns.fold<int>(0, (sum, turn) => sum + turn.score);
    return total / turns.length;
  }

  static String formatAverage(List<InterviewTurn> turns) {
    return averageScore(turns).toStringAsFixed(turns.isEmpty ? 0 : 1);
  }

  static Color scoreColor(int score) {
    if (score >= 85) {
      return const Color(0xFF6CE5B1);
    }
    if (score >= 70) {
      return const Color(0xFFFFD166);
    }
    return const Color(0xFFFF6B6B);
  }
}
