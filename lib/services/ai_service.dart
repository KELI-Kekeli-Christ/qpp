import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../models/exercise_model.dart';
import '../../models/user_model.dart';

class AIService {
  static const String _apiKey = 'OPENAI-API-KEY';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Generate exercises based on subject and user performance
  Future<List<Exercise>> generateExercises({
    required String subject,
    required String topic,
    required DifficultyLevel difficulty,
    required int count,
    UserModel? user,
  }) async {
    try {
      final prompt = _buildExercisePrompt(subject, topic, difficulty, count, user);
      
      final response = await _makeOpenAIRequest(
        prompt: prompt,
        model: 'gpt-4o',
        useJsonFormat: true,
      );

      if (response['success']) {
        final data = response['data'];
        final exercisesData = data['exercises'] as List;
        
        List<Exercise> exercises = [];
        for (int i = 0; i < exercisesData.length; i++) {
          final exerciseData = exercisesData[i];
          exercises.add(Exercise(
            id: _generateId(),
            question: exerciseData['question'] ?? '',
            options: List<String>.from(exerciseData['options'] ?? []),
            correctAnswer: exerciseData['correctAnswer'] ?? '',
            explanation: exerciseData['explanation'] ?? '',
            subject: subject,
            topic: topic,
            type: ExerciseType.multipleChoice,
            difficulty: difficulty,
            timeLimit: exerciseData['timeLimit'] ?? 60,
            keywords: List<String>.from(exerciseData['keywords'] ?? []),
            isAiGenerated: true,
            createdAt: DateTime.now(),
          ));
        }
        
        return exercises;
      } else {
        throw Exception('Failed to generate exercises: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error generating exercises: $e');
    }
  }

  // Analyze user performance and provide feedback
  Future<String> analyzePerformance({
    required UserModel user,
    required List<ExerciseAttempt> recentAttempts,
    required String subject,
  }) async {
    try {
      final prompt = _buildAnalysisPrompt(user, recentAttempts, subject);
      
      final response = await _makeOpenAIRequest(
        prompt: prompt,
        model: 'gpt-4o',
        useJsonFormat: true,
      );

      if (response['success']) {
        final data = response['data'];
        return data['analysis'] ?? 'Analyse non disponible';
      } else {
        throw Exception('Failed to analyze performance: ${response['error']}');
      }
    } catch (e) {
      return 'Erreur lors de l\'analyse: $e';
    }
  }

  // Get personalized recommendations
  Future<Map<String, dynamic>> getRecommendations({
    required UserModel user,
    required List<ExerciseAttempt> recentAttempts,
  }) async {
    try {
      final prompt = _buildRecommendationPrompt(user, recentAttempts);
      
      final response = await _makeOpenAIRequest(
        prompt: prompt,
        model: 'o3-mini',
        useJsonFormat: true,
      );

      if (response['success']) {
        final data = response['data'];
        return {
          'recommendations': data['recommendations'] ?? [],
          'focusAreas': data['focusAreas'] ?? [],
          'motivationalMessage': data['motivationalMessage'] ?? 'Continuez vos efforts!',
          'studyPlan': data['studyPlan'] ?? [],
        };
      } else {
        throw Exception('Failed to get recommendations: ${response['error']}');
      }
    } catch (e) {
      return {
        'recommendations': [],
        'focusAreas': [],
        'motivationalMessage': 'Erreur lors de la génération des recommandations',
        'studyPlan': [],
      };
    }
  }

  // Generate explanation for wrong answers
  Future<String> generateExplanation({
    required Exercise exercise,
    required String userAnswer,
  }) async {
    try {
      final prompt = '''
      Expliquez pourquoi la réponse "${exercise.correctAnswer}" est correcte et pourquoi la réponse "${userAnswer}" est incorrecte pour cette question:
      
      Question: ${exercise.question}
      Options: ${exercise.options.join(', ')}
      Réponse correcte: ${exercise.correctAnswer}
      Réponse de l'utilisateur: ${userAnswer}
      
      Fournissez une explication claire et pédagogique en français.
      ''';
      
      final response = await _makeOpenAIRequest(
        prompt: prompt,
        model: 'gpt-4o-mini',
        useJsonFormat: false,
      );

      if (response['success']) {
        return response['data'];
      } else {
        return 'Explication non disponible';
      }
    } catch (e) {
      return 'Erreur lors de la génération de l\'explication';
    }
  }

  // Build exercise generation prompt
  String _buildExercisePrompt(String subject, String topic, DifficultyLevel difficulty, int count, UserModel? user) {
    String difficultyText = '';
    switch (difficulty) {
      case DifficultyLevel.beginner:
        difficultyText = 'débutant';
        break;
      case DifficultyLevel.intermediate:
        difficultyText = 'intermédiaire';
        break;
      case DifficultyLevel.advanced:
        difficultyText = 'avancé';
        break;
      case DifficultyLevel.expert:
        difficultyText = 'expert';
        break;
    }

    String userContext = '';
    if (user != null) {
      userContext = '''
      Contexte de l'utilisateur:
      - Nom: ${user.name}
      - Matières sélectionnées: ${user.selectedSubjects.join(', ')}
      - Score total: ${user.totalScore}
      - Scores par matière: ${user.subjectScores.toString()}
      ''';
    }

    return '''
    Générez $count exercices de type QCM (questions à choix multiples) pour le sujet "$subject" sur le thème "$topic" avec un niveau de difficulté $difficultyText.

    $userContext

    Chaque exercice doit avoir:
    - Une question claire et précise en français
    - Exactement 4 options de réponse (A, B, C, D)
    - Une seule réponse correcte
    - Une explication détaillée de la réponse
    - Un temps limite approprié (30-120 secondes)
    - Des mots-clés pertinents

    Répondez en JSON avec le format suivant:
    {
      "exercises": [
        {
          "question": "Question ici",
          "options": ["A. Option 1", "B. Option 2", "C. Option 3", "D. Option 4"],
          "correctAnswer": "A. Option 1",
          "explanation": "Explication détaillée",
          "timeLimit": 60,
          "keywords": ["mot-clé1", "mot-clé2"]
        }
      ]
    }
    ''';
  }

  // Build performance analysis prompt
  String _buildAnalysisPrompt(UserModel user, List<ExerciseAttempt> attempts, String subject) {
    String attemptsText = attempts.map((attempt) => 
      'Exercice ${attempt.exerciseId}: ${attempt.isCorrect ? "Correct" : "Incorrect"} (Score: ${attempt.score}, Temps: ${attempt.timeSpent}s)'
    ).join('\n');

    return '''
    Analysez la performance de l'utilisateur ${user.name} en $subject:

    Profil utilisateur:
    - Score total: ${user.totalScore}
    - Jours de série: ${user.streakDays}
    - Classement: ${user.classRanking}

    Tentatives récentes:
    $attemptsText

    Fournissez une analyse détaillée en français couvrant:
    1. Points forts identifiés
    2. Domaines à améliorer
    3. Progression observée
    4. Conseils spécifiques

    Répondez en JSON:
    {
      "analysis": "Analyse détaillée ici"
    }
    ''';
  }

  // Build recommendation prompt
  String _buildRecommendationPrompt(UserModel user, List<ExerciseAttempt> attempts) {
    String performanceText = '';
    if (attempts.isNotEmpty) {
      double avgScore = attempts.map((a) => a.score).reduce((a, b) => a + b) / attempts.length;
      int correctCount = attempts.where((a) => a.isCorrect).length;
      performanceText = 'Score moyen: ${(avgScore * 100).toStringAsFixed(1)}%, Réponses correctes: $correctCount/${attempts.length}';
    }

    return '''
    Générez des recommandations personnalisées pour l'utilisateur ${user.name}:

    Profil:
    - Matières sélectionnées: ${user.selectedSubjects.join(', ')}
    - Score total: ${user.totalScore}
    - Performance récente: $performanceText

    Générez des recommandations incluant:
    1. Exercices recommandés par matière
    2. Domaines à travailler en priorité
    3. Message motivationnel personnalisé
    4. Plan d'étude suggéré

    Répondez en JSON:
    {
      "recommendations": ["Recommandation 1", "Recommandation 2"],
      "focusAreas": ["Domaine 1", "Domaine 2"],
      "motivationalMessage": "Message motivationnel",
      "studyPlan": ["Étape 1", "Étape 2", "Étape 3"]
    }
    ''';
  }

  // Make request to OpenAI API
  Future<Map<String, dynamic>> _makeOpenAIRequest({
    required String prompt,
    required String model,
    bool useJsonFormat = false,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      final body = <String, dynamic>{
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': useJsonFormat ? 'Vous êtes un expert en éducation. Répondez toujours en JSON valide.' : 'Vous êtes un expert en éducation.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'max_tokens': 2000,
        'temperature': 0.7,
      };

      if (useJsonFormat) {
        body['response_format'] = {'type': 'json_object'};
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        
        if (useJsonFormat) {
          final jsonContent = jsonDecode(content);
          return {'success': true, 'data': jsonContent};
        } else {
          return {'success': true, 'data': content};
        }
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
  }
}