import 'dart:math';
import '../../models/exercise_model.dart';
import '../../models/user_model.dart';

// Decision tree node
class DecisionNode {
  final String feature;
  final double threshold;
  final DecisionNode? leftChild;
  final DecisionNode? rightChild;
  final DifficultyLevel? prediction;

  DecisionNode({
    required this.feature,
    required this.threshold,
    this.leftChild,
    this.rightChild,
    this.prediction,
  });
}

// User performance features
class UserFeatures {
  final double averageScore;
  final double averageTimeSpent;
  final int streakDays;
  final double subjectScore;
  final int exercisesCompleted;
  final double recentPerformance;

  UserFeatures({
    required this.averageScore,
    required this.averageTimeSpent,
    required this.streakDays,
    required this.subjectScore,
    required this.exercisesCompleted,
    required this.recentPerformance,
  });

  double getFeatureValue(String feature) {
    switch (feature) {
      case 'averageScore':
        return averageScore;
      case 'averageTimeSpent':
        return averageTimeSpent;
      case 'streakDays':
        return streakDays.toDouble();
      case 'subjectScore':
        return subjectScore;
      case 'exercisesCompleted':
        return exercisesCompleted.toDouble();
      case 'recentPerformance':
        return recentPerformance;
      default:
        return 0.0;
    }
  }
}

// Simplified Random Forest-like recommendation system
class RecommendationService {

  // Create decision trees (simplified Random Forest)
  List<DecisionNode> _createForest() {
    return [
      // Tree 1: Based on average score and streak
      DecisionNode(
        feature: 'averageScore',
        threshold: 0.8,
        leftChild: DecisionNode(
          feature: 'streakDays',
          threshold: 5,
          leftChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.6,
            prediction: DifficultyLevel.intermediate,
          ),
          rightChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.6,
            prediction: DifficultyLevel.advanced,
          ),
        ),
        rightChild: DecisionNode(
          feature: 'recentPerformance',
          threshold: 0.9,
          leftChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.6,
            prediction: DifficultyLevel.advanced,
          ),
          rightChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.6,
            prediction: DifficultyLevel.expert,
          ),
        ),
      ),

      // Tree 2: Based on time spent and exercises completed
      DecisionNode(
        feature: 'averageTimeSpent',
        threshold: 45,
        leftChild: DecisionNode(
          feature: 'exercisesCompleted',
          threshold: 10,
          leftChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.5,
            prediction: DifficultyLevel.beginner,
          ),
          rightChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.7,
            prediction: DifficultyLevel.intermediate,
          ),
        ),
        rightChild: DecisionNode(
          feature: 'subjectScore',
          threshold: 0.6,
          leftChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.5,
            prediction: DifficultyLevel.beginner,
          ),
          rightChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.7,
            prediction: DifficultyLevel.intermediate,
          ),
        ),
      ),

      // Tree 3: Based on recent performance and subject expertise
      DecisionNode(
        feature: 'recentPerformance',
        threshold: 0.7,
        leftChild: DecisionNode(
          feature: 'subjectScore',
          threshold: 0.5,
          leftChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.4,
            prediction: DifficultyLevel.beginner,
          ),
          rightChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.6,
            prediction: DifficultyLevel.intermediate,
          ),
        ),
        rightChild: DecisionNode(
          feature: 'streakDays',
          threshold: 3,
          leftChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.8,
            prediction: DifficultyLevel.intermediate,
          ),
          rightChild: DecisionNode(
            feature: 'averageScore',
            threshold: 0.8,
            prediction: DifficultyLevel.advanced,
          ),
        ),
      ),
    ];
  }

  // Predict difficulty using a single tree
  DifficultyLevel _predictWithTree(DecisionNode tree, UserFeatures features) {
    DecisionNode currentNode = tree;
    
    while (currentNode.prediction == null) {
      double featureValue = features.getFeatureValue(currentNode.feature);
      
      if (featureValue <= currentNode.threshold) {
        currentNode = currentNode.leftChild!;
      } else {
        currentNode = currentNode.rightChild!;
      }
    }
    
    return currentNode.prediction!;
  }

  // Get recommended difficulty using Random Forest approach
  DifficultyLevel recommendDifficulty({
    required UserModel user,
    required String subject,
    required List<ExerciseAttempt> recentAttempts,
  }) {
    try {
      UserFeatures features = _extractUserFeatures(user, subject, recentAttempts);
      List<DecisionNode> forest = _createForest();
      
      // Get predictions from all trees
      Map<DifficultyLevel, int> votes = {};
      for (DecisionNode tree in forest) {
        DifficultyLevel prediction = _predictWithTree(tree, features);
        votes[prediction] = (votes[prediction] ?? 0) + 1;
      }
      
      // Return the difficulty with most votes
      DifficultyLevel recommendedDifficulty = votes.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      return recommendedDifficulty;
    } catch (e) {
      // Fallback to intermediate difficulty
      return DifficultyLevel.intermediate;
    }
  }

  // Extract user features for the algorithm
  UserFeatures _extractUserFeatures(
    UserModel user,
    String subject,
    List<ExerciseAttempt> recentAttempts,
  ) {
    double averageScore = 0.0;
    double averageTimeSpent = 0.0;
    double recentPerformance = 0.0;
    
    if (recentAttempts.isNotEmpty) {
      averageScore = recentAttempts.map((a) => a.score).reduce((a, b) => a + b) / recentAttempts.length;
      averageTimeSpent = recentAttempts.map((a) => a.timeSpent.toDouble()).reduce((a, b) => a + b) / recentAttempts.length;
      
      // Recent performance (last 5 attempts)
      List<ExerciseAttempt> lastFive = recentAttempts.take(5).toList();
      recentPerformance = lastFive.map((a) => a.score).reduce((a, b) => a + b) / lastFive.length;
    }
    
    double subjectScore = user.subjectScores[subject] ?? 0.0;
    int exercisesCompleted = recentAttempts.length;
    
    return UserFeatures(
      averageScore: averageScore,
      averageTimeSpent: averageTimeSpent,
      streakDays: user.streakDays,
      subjectScore: subjectScore,
      exercisesCompleted: exercisesCompleted,
      recentPerformance: recentPerformance,
    );
  }

  // Get personalized exercise recommendations
  List<String> getExerciseRecommendations({
    required UserModel user,
    required List<ExerciseAttempt> recentAttempts,
  }) {
    List<String> recommendations = [];
    
    try {
      // Analyze performance by subject
      Map<String, double> subjectPerformance = {};
      Map<String, int> subjectCounts = {};
      
      for (ExerciseAttempt attempt in recentAttempts) {
        // Note: In a real implementation, you would need to get the exercise subject
        // For now, we'll use the user's selected subjects
        for (String subject in user.selectedSubjects) {
          subjectPerformance[subject] = (subjectPerformance[subject] ?? 0.0) + attempt.score;
          subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
        }
      }
      
      // Calculate average performance per subject
      Map<String, double> averagePerformance = {};
      subjectPerformance.forEach((subject, totalScore) {
        int count = subjectCounts[subject] ?? 1;
        averagePerformance[subject] = totalScore / count;
      });
      
      // Find weakest subjects
      List<MapEntry<String, double>> sortedSubjects = averagePerformance.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      // Generate recommendations based on performance
      for (int i = 0; i < min(3, sortedSubjects.length); i++) {
        String subject = sortedSubjects[i].key;
        double performance = sortedSubjects[i].value;
        
        if (performance < 0.6) {
          recommendations.add('Pratiquez davantage en $subject - Score actuel: ${(performance * 100).toStringAsFixed(1)}%');
        } else if (performance < 0.8) {
          recommendations.add('Approfondissez vos connaissances en $subject');
        } else {
          recommendations.add('Excellente maîtrise en $subject - Essayez des exercices plus avancés');
        }
      }
      
      // Add general recommendations
      if (user.streakDays < 3) {
        recommendations.add('Maintenez une pratique régulière pour améliorer vos résultats');
      }
      
      if (recentAttempts.length < 5) {
        recommendations.add('Complétez plus d\'exercices pour une évaluation précise');
      }
      
      // Add time-based recommendations
      if (recentAttempts.isNotEmpty) {
        double avgTime = recentAttempts.map((a) => a.timeSpent.toDouble()).reduce((a, b) => a + b) / recentAttempts.length;
        if (avgTime > 90) {
          recommendations.add('Travaillez sur la rapidité de résolution des exercices');
        }
      }
      
    } catch (e) {
      recommendations.add('Continuez à pratiquer régulièrement pour améliorer vos compétences');
    }
    
    // Ensure we have at least some recommendations
    if (recommendations.isEmpty) {
      recommendations.addAll([
        'Continuez vos efforts, vous progressez bien!',
        'Essayez de nouveaux exercices pour diversifier vos compétences',
        'Maintenez une pratique régulière pour de meilleurs résultats',
      ]);
    }
    
    return recommendations;
  }

  // Get focus areas based on performance analysis
  List<String> getFocusAreas({
    required UserModel user,
    required List<ExerciseAttempt> recentAttempts,
  }) {
    List<String> focusAreas = [];
    
    try {
      // Analyze error patterns
      int totalAttempts = recentAttempts.length;
      int incorrectAttempts = recentAttempts.where((a) => !a.isCorrect).length;
      
      if (totalAttempts > 0) {
        double errorRate = incorrectAttempts / totalAttempts;
        
        if (errorRate > 0.5) {
          focusAreas.add('Révision des concepts fondamentaux');
        } else if (errorRate > 0.3) {
          focusAreas.add('Amélioration de la précision');
        }
      }
      
      // Time management analysis
      if (recentAttempts.isNotEmpty) {
        double avgTime = recentAttempts.map((a) => a.timeSpent.toDouble()).reduce((a, b) => a + b) / recentAttempts.length;
        if (avgTime > 80) {
          focusAreas.add('Gestion du temps');
        }
      }
      
      // Subject-specific focus areas
      for (String subject in user.selectedSubjects) {
        double score = user.subjectScores[subject] ?? 0.0;
        if (score < 0.6) {
          focusAreas.add('Renforcement en $subject');
        }
      }
      
      // Consistency focus
      if (user.streakDays < 5) {
        focusAreas.add('Régularité dans la pratique');
      }
      
    } catch (e) {
      focusAreas.add('Pratique générale');
    }
    
    // Default focus areas if none identified
    if (focusAreas.isEmpty) {
      focusAreas.addAll([
        'Diversification des sujets d\'étude',
        'Amélioration continue',
      ]);
    }
    
    return focusAreas.take(4).toList(); // Limit to 4 focus areas
  }

  // Generate study plan based on user performance
  List<String> generateStudyPlan({
    required UserModel user,
    required List<ExerciseAttempt> recentAttempts,
  }) {
    List<String> studyPlan = [];
    
    try {
      // Base plan on current performance
      DifficultyLevel recommendedDifficulty = recommendDifficulty(
        user: user,
        subject: user.selectedSubjects.isNotEmpty ? user.selectedSubjects.first : 'Mathématique',
        recentAttempts: recentAttempts,
      );
      
      // Create progressive study plan
      switch (recommendedDifficulty) {
        case DifficultyLevel.beginner:
          studyPlan.addAll([
            '1. Réviser les concepts de base (15 min/jour)',
            '2. Pratiquer 5 exercices faciles par jour',
            '3. Revoir les erreurs après chaque session',
            '4. Augmenter progressivement la difficulté',
          ]);
          break;
        case DifficultyLevel.intermediate:
          studyPlan.addAll([
            '1. Consolider les acquis (20 min/jour)',
            '2. Mélanger exercices faciles et moyens',
            '3. Analyser les erreurs récurrentes',
            '4. Introduire de nouveaux concepts',
          ]);
          break;
        case DifficultyLevel.advanced:
          studyPlan.addAll([
            '1. Approfondir les concepts complexes (25 min/jour)',
            '2. Résoudre des exercices variés',
            '3. Travailler sur la rapidité d\'exécution',
            '4. Explorer des sujets connexes',
          ]);
          break;
        case DifficultyLevel.expert:
          studyPlan.addAll([
            '1. Maîtriser les concepts avancés (30 min/jour)',
            '2. Résoudre des problèmes complexes',
            '3. Optimiser les méthodes de résolution',
            '4. Aider d\'autres utilisateurs',
          ]);
          break;
      }
      
      // Add general recommendations
      studyPlan.add('5. Maintenir une pratique quotidienne régulière');
      
    } catch (e) {
      // Fallback study plan
      studyPlan.addAll([
        '1. Pratiquer régulièrement (20 min/jour)',
        '2. Réviser les concepts difficiles',
        '3. Suivre vos progrès quotidiennement',
        '4. Demander de l\'aide si nécessaire',
      ]);
    }
    
    return studyPlan;
  }
}