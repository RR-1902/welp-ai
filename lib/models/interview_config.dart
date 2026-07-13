class InterviewConfig {
  const InterviewConfig({
    required this.mode,
    required this.role,
    required this.difficulty,
    required this.persona,
    required this.questionCount,
    this.customTopic,
    this.includeCamera = false,
    this.resumePath,
  });

  final String mode;
  final String role;
  final String difficulty;
  final String persona;
  final int questionCount;
  final String? customTopic;
  final bool includeCamera;
  final String? resumePath;

  InterviewConfig copyWith({
    String? mode,
    String? role,
    String? difficulty,
    String? persona,
    int? questionCount,
    String? customTopic,
    bool? includeCamera,
    String? resumePath,
  }) {
    return InterviewConfig(
      mode: mode ?? this.mode,
      role: role ?? this.role,
      difficulty: difficulty ?? this.difficulty,
      persona: persona ?? this.persona,
      questionCount: questionCount ?? this.questionCount,
      customTopic: customTopic ?? this.customTopic,
      includeCamera: includeCamera ?? this.includeCamera,
      resumePath: resumePath ?? this.resumePath,
    );
  }

  String get topicLabel {
    if (mode == 'Custom Topic' && (customTopic?.trim().isNotEmpty ?? false)) {
      return customTopic!.trim();
    }
    return role.trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'role': role,
      'difficulty': difficulty,
      'persona': persona,
      'questionCount': questionCount,
      'customTopic': customTopic,
      'includeCamera': includeCamera,
      'resumePath': resumePath,
    };
  }
}
