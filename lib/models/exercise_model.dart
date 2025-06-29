enum ExerciseType {
  multipleChoice,
  trueFalse,
  fillInBlank,
  essay
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert
}

class Exercise {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String subject;
  final String topic;
  final ExerciseType type;
  final DifficultyLevel difficulty;
  final int timeLimit; // in seconds
  final List<String> keywords;
  final bool isAiGenerated;
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.subject,
    required this.topic,
    required this.type,
    required this.difficulty,
    required this.timeLimit,
    required this.keywords,
    required this.isAiGenerated,
    required this.createdAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      explanation: json['explanation'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      type: ExerciseType.values.firstWhere(
        (e) => e.toString() == 'ExerciseType.${json['type']}',
        orElse: () => ExerciseType.multipleChoice,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == 'DifficultyLevel.${json['difficulty']}',
        orElse: () => DifficultyLevel.intermediate,
      ),
      timeLimit: json['timeLimit'] ?? 60,
      keywords: List<String>.from(json['keywords'] ?? []),
      isAiGenerated: json['isAiGenerated'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'subject': subject,
      'topic': topic,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'timeLimit': timeLimit,
      'keywords': keywords,
      'isAiGenerated': isAiGenerated,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ExerciseAttempt {
  final String id;
  final String exerciseId;
  final String userId;
  final String userAnswer;
  final bool isCorrect;
  final int timeSpent; // in seconds
  final double score; // 0.0 to 1.0
  final DateTime attemptedAt;
  final String? feedback;

  ExerciseAttempt({
    required this.id,
    required this.exerciseId,
    required this.userId,
    required this.userAnswer,
    required this.isCorrect,
    required this.timeSpent,
    required this.score,
    required this.attemptedAt,
    this.feedback,
  });

  factory ExerciseAttempt.fromJson(Map<String, dynamic> json) {
    return ExerciseAttempt(
      id: json['id'] ?? '',
      exerciseId: json['exerciseId'] ?? '',
      userId: json['userId'] ?? '',
      userAnswer: json['userAnswer'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      timeSpent: json['timeSpent'] ?? 0,
      score: (json['score'] ?? 0.0).toDouble(),
      attemptedAt: DateTime.parse(json['attemptedAt'] ?? DateTime.now().toIso8601String()),
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'userId': userId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
      'score': score,
      'attemptedAt': attemptedAt.toIso8601String(),
      'feedback': feedback,
    };
  }
}

class QuizSession {
  final String id;
  final String userId;
  final String subject;
  final List<String> exerciseIds;
  final Map<String, ExerciseAttempt> attempts;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double overallScore;
  final bool isCompleted;

  QuizSession({
    required this.id,
    required this.userId,
    required this.subject,
    required this.exerciseIds,
    required this.attempts,
    required this.startedAt,
    this.completedAt,
    required this.overallScore,
    required this.isCompleted,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    Map<String, ExerciseAttempt> attempts = {};
    if (json['attempts'] != null) {
      (json['attempts'] as Map<String, dynamic>).forEach((key, value) {
        attempts[key] = ExerciseAttempt.fromJson(value);
      });
    }

    return QuizSession(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      subject: json['subject'] ?? '',
      exerciseIds: List<String>.from(json['exerciseIds'] ?? []),
      attempts: attempts,
      startedAt: DateTime.parse(json['startedAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      overallScore: (json['overallScore'] ?? 0.0).toDouble(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> attemptsJson = {};
    attempts.forEach((key, value) {
      attemptsJson[key] = value.toJson();
    });

    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'exerciseIds': exerciseIds,
      'attempts': attemptsJson,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'overallScore': overallScore,
      'isCompleted': isCompleted,
    };
  }
}