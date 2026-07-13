class MessageModel {
  const MessageModel({
    required this.role,
    required this.content,
    required this.timestamp,
    this.score,
    this.feedback,
    this.questionNumber,
    this.isQuestion = false,
  });

  final String role;
  final String content;
  final DateTime timestamp;
  final int? score;
  final String? feedback;
  final int? questionNumber;
  final bool isQuestion;

  bool get isUser => role == 'user';

  MessageModel copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    int? score,
    String? feedback,
    int? questionNumber,
    bool? isQuestion,
  }) {
    return MessageModel(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      questionNumber: questionNumber ?? this.questionNumber,
      isQuestion: isQuestion ?? this.isQuestion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'score': score,
      'feedback': feedback,
      'questionNumber': questionNumber,
      'isQuestion': isQuestion,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      score: json['score'] as int?,
      feedback: json['feedback'] as String?,
      questionNumber: json['questionNumber'] as int?,
      isQuestion: json['isQuestion'] as bool? ?? false,
    );
  }
}
