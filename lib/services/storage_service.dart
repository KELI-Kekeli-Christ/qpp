import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _exercisesKey = 'cached_exercises';
  static const String _attemptsKey = 'exercise_attempts';
  static const String _sessionsKey = 'quiz_sessions';
  static const String _userProgressKey = 'user_progress';
  static const String _offlineDataKey = 'offline_data';

  // Save exercises for offline use
  Future<void> cacheExercises(List<Exercise> exercises, String subject) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing cached exercises
      Map<String, List<Exercise>> cachedExercises = await getAllCachedExercises();
      
      // Add or update exercises for this subject
      cachedExercises[subject] = exercises;
      
      // Convert to JSON and save
      Map<String, dynamic> exercisesJson = {};
      cachedExercises.forEach((subjectKey, exerciseList) {
        exercisesJson[subjectKey] = exerciseList.map((e) => e.toJson()).toList();
      });
      
      await prefs.setString(_exercisesKey, jsonEncode(exercisesJson));
    } catch (e) {
      throw Exception('Failed to cache exercises: $e');
    }
  }

  // Get cached exercises for offline use
  Future<List<Exercise>> getCachedExercises(String subject) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? exercisesStr = prefs.getString(_exercisesKey);
      
      if (exercisesStr == null) return [];
      
      Map<String, dynamic> exercisesJson = jsonDecode(exercisesStr);
      
      if (!exercisesJson.containsKey(subject)) return [];
      
      List<dynamic> subjectExercises = exercisesJson[subject];
      return subjectExercises.map((e) => Exercise.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all cached exercises
  Future<Map<String, List<Exercise>>> getAllCachedExercises() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? exercisesStr = prefs.getString(_exercisesKey);
      
      if (exercisesStr == null) return {};
      
      Map<String, dynamic> exercisesJson = jsonDecode(exercisesStr);
      Map<String, List<Exercise>> result = {};
      
      exercisesJson.forEach((subject, exerciseList) {
        result[subject] = (exerciseList as List)
            .map((e) => Exercise.fromJson(e))
            .toList();
      });
      
      return result;
    } catch (e) {
      return {};
    }
  }

  // Save exercise attempt
  Future<void> saveExerciseAttempt(ExerciseAttempt attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing attempts
      List<ExerciseAttempt> attempts = await getExerciseAttempts(attempt.userId);
      
      // Add new attempt
      attempts.add(attempt);
      
      // Keep only last 100 attempts per user
      if (attempts.length > 100) {
        attempts = attempts.sublist(attempts.length - 100);
      }
      
      // Save attempts grouped by user
      Map<String, List<ExerciseAttempt>> allAttempts = await getAllExerciseAttempts();
      allAttempts[attempt.userId] = attempts;
      
      // Convert to JSON and save
      Map<String, dynamic> attemptsJson = {};
      allAttempts.forEach((userId, userAttempts) {
        attemptsJson[userId] = userAttempts.map((a) => a.toJson()).toList();
      });
      
      await prefs.setString(_attemptsKey, jsonEncode(attemptsJson));
    } catch (e) {
      throw Exception('Failed to save exercise attempt: $e');
    }
  }

  // Get exercise attempts for a user
  Future<List<ExerciseAttempt>> getExerciseAttempts(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? attemptsStr = prefs.getString(_attemptsKey);
      
      if (attemptsStr == null) return [];
      
      Map<String, dynamic> attemptsJson = jsonDecode(attemptsStr);
      
      if (!attemptsJson.containsKey(userId)) return [];
      
      List<dynamic> userAttempts = attemptsJson[userId];
      return userAttempts.map((a) => ExerciseAttempt.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all exercise attempts
  Future<Map<String, List<ExerciseAttempt>>> getAllExerciseAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? attemptsStr = prefs.getString(_attemptsKey);
      
      if (attemptsStr == null) return {};
      
      Map<String, dynamic> attemptsJson = jsonDecode(attemptsStr);
      Map<String, List<ExerciseAttempt>> result = {};
      
      attemptsJson.forEach((userId, userAttempts) {
        result[userId] = (userAttempts as List)
            .map((a) => ExerciseAttempt.fromJson(a))
            .toList();
      });
      
      return result;
    } catch (e) {
      return {};
    }
  }

  // Save quiz session
  Future<void> saveQuizSession(QuizSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing sessions
      List<QuizSession> sessions = await getQuizSessions(session.userId);
      
      // Update or add session
      int existingIndex = sessions.indexWhere((s) => s.id == session.id);
      if (existingIndex != -1) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }
      
      // Keep only last 50 sessions per user
      if (sessions.length > 50) {
        sessions = sessions.sublist(sessions.length - 50);
      }
      
      // Save sessions grouped by user
      Map<String, List<QuizSession>> allSessions = await getAllQuizSessions();
      allSessions[session.userId] = sessions;
      
      // Convert to JSON and save
      Map<String, dynamic> sessionsJson = {};
      allSessions.forEach((userId, userSessions) {
        sessionsJson[userId] = userSessions.map((s) => s.toJson()).toList();
      });
      
      await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
    } catch (e) {
      throw Exception('Failed to save quiz session: $e');
    }
  }

  // Get quiz sessions for a user
  Future<List<QuizSession>> getQuizSessions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionsStr = prefs.getString(_sessionsKey);
      
      if (sessionsStr == null) return [];
      
      Map<String, dynamic> sessionsJson = jsonDecode(sessionsStr);
      
      if (!sessionsJson.containsKey(userId)) return [];
      
      List<dynamic> userSessions = sessionsJson[userId];
      return userSessions.map((s) => QuizSession.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all quiz sessions
  Future<Map<String, List<QuizSession>>> getAllQuizSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionsStr = prefs.getString(_sessionsKey);
      
      if (sessionsStr == null) return {};
      
      Map<String, dynamic> sessionsJson = jsonDecode(sessionsStr);
      Map<String, List<QuizSession>> result = {};
      
      sessionsJson.forEach((userId, userSessions) {
        result[userId] = (userSessions as List)
            .map((s) => QuizSession.fromJson(s))
            .toList();
      });
      
      return result;
    } catch (e) {
      return {};
    }
  }

  // Save user progress data
  Future<void> saveUserProgress(String userId, Map<String, dynamic> progressData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing progress data
      Map<String, Map<String, dynamic>> allProgress = await getAllUserProgress();
      
      // Update progress for this user
      allProgress[userId] = progressData;
      
      // Save all progress data
      Map<String, dynamic> progressJson = {};
      allProgress.forEach((uid, progress) {
        progressJson[uid] = progress;
      });
      
      await prefs.setString(_userProgressKey, jsonEncode(progressJson));
    } catch (e) {
      throw Exception('Failed to save user progress: $e');
    }
  }

  // Get user progress data
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? progressStr = prefs.getString(_userProgressKey);
      
      if (progressStr == null) return {};
      
      Map<String, dynamic> progressJson = jsonDecode(progressStr);
      
      if (!progressJson.containsKey(userId)) return {};
      
      return Map<String, dynamic>.from(progressJson[userId]);
    } catch (e) {
      return {};
    }
  }

  // Get all user progress data
  Future<Map<String, Map<String, dynamic>>> getAllUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? progressStr = prefs.getString(_userProgressKey);
      
      if (progressStr == null) return {};
      
      Map<String, dynamic> progressJson = jsonDecode(progressStr);
      Map<String, Map<String, dynamic>> result = {};
      
      progressJson.forEach((userId, progress) {
        result[userId] = Map<String, dynamic>.from(progress);
      });
      
      return result;
    } catch (e) {
      return {};
    }
  }

  // Check if data is available offline
  Future<bool> hasOfflineData(String subject) async {
    try {
      List<Exercise> exercises = await getCachedExercises(subject);
      return exercises.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get offline statistics
  Future<Map<String, dynamic>> getOfflineStats(String userId) async {
    try {
      List<ExerciseAttempt> attempts = await getExerciseAttempts(userId);
      List<QuizSession> sessions = await getQuizSessions(userId);
      Map<String, List<Exercise>> cachedExercises = await getAllCachedExercises();
      
      int totalAttempts = attempts.length;
      int correctAttempts = attempts.where((a) => a.isCorrect).length;
      int totalSessions = sessions.length;
      int completedSessions = sessions.where((s) => s.isCompleted).length;
      int totalCachedExercises = cachedExercises.values
          .fold(0, (sum, exercises) => sum + exercises.length);
      
      double averageScore = totalAttempts > 0 
          ? attempts.map((a) => a.score).reduce((a, b) => a + b) / totalAttempts
          : 0.0;
      
      return {
        'totalAttempts': totalAttempts,
        'correctAttempts': correctAttempts,
        'totalSessions': totalSessions,
        'completedSessions': completedSessions,
        'totalCachedExercises': totalCachedExercises,
        'averageScore': averageScore,
        'accuracyRate': totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0,
        'completionRate': totalSessions > 0 ? completedSessions / totalSessions : 0.0,
      };
    } catch (e) {
      return {};
    }
  }

  // Clear old offline data
  Future<void> clearOldOfflineData({int daysOld = 30}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      // Clear old exercises
      Map<String, List<Exercise>> cachedExercises = await getAllCachedExercises();
      Map<String, List<Exercise>> filteredExercises = {};
      
      cachedExercises.forEach((subject, exercises) {
        List<Exercise> recentExercises = exercises
            .where((e) => e.createdAt.isAfter(cutoffDate))
            .toList();
        if (recentExercises.isNotEmpty) {
          filteredExercises[subject] = recentExercises;
        }
      });
      
      // Save filtered exercises
      Map<String, dynamic> exercisesJson = {};
      filteredExercises.forEach((subject, exercises) {
        exercisesJson[subject] = exercises.map((e) => e.toJson()).toList();
      });
      await prefs.setString(_exercisesKey, jsonEncode(exercisesJson));
      
      // Clear old attempts
      Map<String, List<ExerciseAttempt>> allAttempts = await getAllExerciseAttempts();
      Map<String, List<ExerciseAttempt>> filteredAttempts = {};
      
      allAttempts.forEach((userId, attempts) {
        List<ExerciseAttempt> recentAttempts = attempts
            .where((a) => a.attemptedAt.isAfter(cutoffDate))
            .toList();
        if (recentAttempts.isNotEmpty) {
          filteredAttempts[userId] = recentAttempts;
        }
      });
      
      // Save filtered attempts
      Map<String, dynamic> attemptsJson = {};
      filteredAttempts.forEach((userId, attempts) {
        attemptsJson[userId] = attempts.map((a) => a.toJson()).toList();
      });
      await prefs.setString(_attemptsKey, jsonEncode(attemptsJson));
      
    } catch (e) {
      throw Exception('Failed to clear old offline data: $e');
    }
  }

  // Export user data
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      List<ExerciseAttempt> attempts = await getExerciseAttempts(userId);
      List<QuizSession> sessions = await getQuizSessions(userId);
      Map<String, dynamic> progress = await getUserProgress(userId);
      Map<String, dynamic> stats = await getOfflineStats(userId);
      
      return {
        'userId': userId,
        'exportDate': DateTime.now().toIso8601String(),
        'attempts': attempts.map((a) => a.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'progress': progress,
        'statistics': stats,
      };
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_exercisesKey);
      await prefs.remove(_attemptsKey);
      await prefs.remove(_sessionsKey);
      await prefs.remove(_userProgressKey);
      await prefs.remove(_offlineDataKey);
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }

  // Save user data
  Future<void> saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(user.toJson()));
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }
}