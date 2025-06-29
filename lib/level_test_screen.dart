import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class LevelTestScreen extends StatefulWidget {
  final UserModel user;
  
  const LevelTestScreen({super.key, required this.user});

  @override
  State<LevelTestScreen> createState() => _LevelTestScreenState();
}

class _LevelTestScreenState extends State<LevelTestScreen> with TickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _testCompleted = false;
  String _userLevel = 'Débutant';
  
  final List<LevelTestQuestion> _questions = [
    // Questions de mathématiques
    LevelTestQuestion(
      subject: 'Mathématiques',
      question: 'Combien font 7 × 8 ?',
      options: ['54', '56', '58', '64'],
      correctAnswer: 1,
      difficulty: 1,
    ),
    LevelTestQuestion(
      subject: 'Mathématiques',
      question: 'Quelle est la racine carrée de 144 ?',
      options: ['11', '12', '13', '14'],
      correctAnswer: 1,
      difficulty: 2,
    ),
    LevelTestQuestion(
      subject: 'Mathématiques',
      question: 'Résolvez : 2x + 5 = 15',
      options: ['x = 4', 'x = 5', 'x = 6', 'x = 7'],
      correctAnswer: 1,
      difficulty: 3,
    ),
    
    // Questions de français
    LevelTestQuestion(
      subject: 'Français',
      question: 'Quel est le pluriel de "cheval" ?',
      options: ['chevals', 'chevaux', 'chevaus', 'chevalx'],
      correctAnswer: 1,
      difficulty: 1,
    ),
    LevelTestQuestion(
      subject: 'Français',
      question: 'Quelle est la nature du mot "rapidement" ?',
      options: ['Adjectif', 'Adverbe', 'Nom', 'Verbe'],
      correctAnswer: 1,
      difficulty: 2,
    ),
    
    // Questions de sciences
    LevelTestQuestion(
      subject: 'Sciences',
      question: 'Combien y a-t-il de planètes dans le système solaire ?',
      options: ['7', '8', '9', '10'],
      correctAnswer: 1,
      difficulty: 1,
    ),
    LevelTestQuestion(
      subject: 'Sciences',
      question: 'Quelle est la formule chimique de l\'eau ?',
      options: ['H2O', 'CO2', 'O2', 'H2SO4'],
      correctAnswer: 0,
      difficulty: 2,
    ),
    
    // Questions d'histoire
    LevelTestQuestion(
      subject: 'Histoire',
      question: 'En quelle année a eu lieu la Révolution française ?',
      options: ['1789', '1799', '1804', '1815'],
      correctAnswer: 0,
      difficulty: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _answerQuestion(int selectedAnswer) {
    if (selectedAnswer == _questions[_currentQuestionIndex].correctAnswer) {
      _correctAnswers++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _completeTest();
    }
  }

  void _completeTest() {
    // Déterminer le niveau basé sur le score
    double percentage = (_correctAnswers / _questions.length) * 100;
    
    if (percentage >= 80) {
      _userLevel = 'Avancé';
    } else if (percentage >= 60) {
      _userLevel = 'Intermédiaire';
    } else {
      _userLevel = 'Débutant';
    }

    // Mettre à jour le profil utilisateur
    widget.user.level = _userLevel;
    widget.user.initialTestCompleted = true;
    _storageService.saveUser(widget.user);

    setState(() {
      _testCompleted = true;
    });
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A5AE0),
              Color(0xFF9C27B0),
              Color(0xFFE91E63),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _testCompleted ? _buildResultsScreen() : _buildTestScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildTestScreen() {
    final question = _questions[_currentQuestionIndex];
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  '${_currentQuestionIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test de niveau initial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_currentQuestionIndex + 1} sur ${_questions.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Progress bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          
          const SizedBox(height: 48),
          
          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A5AE0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    question.subject,
                    style: const TextStyle(
                      color: Color(0xFF6A5AE0),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 24),
                ...question.options.asMap().entries.map((entry) {
                  int index = entry.key;
                  String option = entry.value;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _answerQuestion(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF6A5AE0),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: const TextStyle(
                                    color: Color(0xFF6A5AE0),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    double percentage = (_correctAnswers / _questions.length) * 100;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Test terminé !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre niveau : $_userLevel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6A5AE0),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score : $_correctAnswers/${_questions.length} (${percentage.toInt()}%)',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A5AE0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Commencer l\'apprentissage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LevelTestQuestion {
  final String subject;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final int difficulty;

  LevelTestQuestion({
    required this.subject,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
  });
}