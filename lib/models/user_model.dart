class UserModel {
  final String id;
  final String name;
  final String email;
  final List<String> selectedSubjects;
  final Map<String, double> subjectScores;
  final Map<String, int> subjectProgress;
  final int totalScore;
  final int streakDays;
  final int classRanking;
  final DateTime createdAt;
  final DateTime lastActive;
  String level;
  bool initialTestCompleted;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.selectedSubjects,
    required this.subjectScores,
    required this.subjectProgress,
    required this.totalScore,
    required this.streakDays,
    required this.classRanking,
    required this.createdAt,
    required this.lastActive,
    this.level = 'Débutant',
    this.initialTestCompleted = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      selectedSubjects: List<String>.from(json['selectedSubjects'] ?? []),
      subjectScores: Map<String, double>.from(json['subjectScores'] ?? {}),
      subjectProgress: Map<String, int>.from(json['subjectProgress'] ?? {}),
      totalScore: json['totalScore'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      classRanking: json['classRanking'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActive: DateTime.parse(json['lastActive'] ?? DateTime.now().toIso8601String()),
      level: json['level'] ?? 'Débutant',
      initialTestCompleted: json['initialTestCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'selectedSubjects': selectedSubjects,
      'subjectScores': subjectScores,
      'subjectProgress': subjectProgress,
      'totalScore': totalScore,
      'streakDays': streakDays,
      'classRanking': classRanking,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'level': level,
      'initialTestCompleted': initialTestCompleted,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? selectedSubjects,
    Map<String, double>? subjectScores,
    Map<String, int>? subjectProgress,
    int? totalScore,
    int? streakDays,
    int? classRanking,
    DateTime? createdAt,
    DateTime? lastActive,
    String? level,
    bool? initialTestCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      selectedSubjects: selectedSubjects ?? this.selectedSubjects,
      subjectScores: subjectScores ?? this.subjectScores,
      subjectProgress: subjectProgress ?? this.subjectProgress,
      totalScore: totalScore ?? this.totalScore,
      streakDays: streakDays ?? this.streakDays,
      classRanking: classRanking ?? this.classRanking,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      level: level ?? this.level,
      initialTestCompleted: initialTestCompleted ?? this.initialTestCompleted,
    );
  }

  static UserModel empty() {
    return UserModel(
      id: '',
      name: '',
      email: '',
      selectedSubjects: [],
      subjectScores: {},
      subjectProgress: {},
      totalScore: 0,
      streakDays: 0,
      classRanking: 0,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }
}