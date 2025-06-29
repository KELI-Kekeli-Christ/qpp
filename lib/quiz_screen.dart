import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../theme.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/recommendation_service.dart';

class QuizScreen extends StatefulWidget {
  final UserModel user;
  final String subject;
  
  const QuizScreen({
    super.key,
    required this.user,
    required this.subject,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();
  final RecommendationService _recommendationService = RecommendationService();
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  
  // Quiz state
  List<Exercise> _exercises = [];
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _isLoading = true;
  bool _isAnswerSubmitted = false;
  bool _isQuizCompleted = false;
  Timer? _timer;
  int _timeRemaining = 60;
  int _score = 0;
  int _correctAnswers = 0;
  
  // Results
  List<ExerciseAttempt> _attempts = [];
  late QuizSession _currentSession;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeQuiz();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initializeQuiz() async {
    try {
      // Get user's recent attempts for recommendation
      List<ExerciseAttempt> recentAttempts = await _storageService.getExerciseAttempts(widget.user.id);
      
      // Get recommended difficulty
      DifficultyLevel difficulty = _recommendationService.recommendDifficulty(
        user: widget.user,
        subject: widget.subject,
        recentAttempts: recentAttempts,
      );
      
      // Try to get cached exercises first
      List<Exercise> cachedExercises = await _storageService.getCachedExercises(widget.subject);
      
      if (cachedExercises.isNotEmpty) {
        _exercises = cachedExercises.take(10).toList();
      } else {
        // Generate new exercises with AI
        _exercises = await _aiService.generateExercises(
          subject: widget.subject,
          topic: 'General',
          difficulty: difficulty,
          count: 10,
          user: widget.user,
        );
        
        // Cache the exercises for offline use
        await _storageService.cacheExercises(_exercises, widget.subject);
      }
      
      // Initialize quiz session
      _currentSession = QuizSession(
        id: _generateSessionId(),
        userId: widget.user.id,
        subject: widget.subject,
        exerciseIds: _exercises.map((e) => e.id).toList(),
        attempts: {},
        startedAt: DateTime.now(),
        overallScore: 0.0,
        isCompleted: false,
      );
      
      _startTimer();
      _slideController.forward();
      _progressController.forward();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to sample questions if AI fails
      _exercises = _generateSampleExercises();
      setState(() {
        _isLoading = false;
      });
      _startTimer();
      _slideController.forward();
      _progressController.forward();
    }
  }

  List<Exercise> _generateSampleExercises() {
    return [
      Exercise(
        id: '1',
        question: 'En quelle année a eu lieu le débarquement allié en Normandie ?',
        options: ['A. 1942', 'B. 1943', 'C. 1944', 'D. 1945'],
        correctAnswer: 'C. 1944',
        explanation: 'Le débarquement de Normandie a eu lieu le 6 juin 1944.',
        subject: widget.subject,
        topic: 'Histoire',
        type: ExerciseType.multipleChoice,
        difficulty: DifficultyLevel.intermediate,
        timeLimit: 60,
        keywords: ['histoire', 'guerre', 'normandie'],
        isAiGenerated: false,
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: '2',
        question: 'Soit la fonction f(x) = x² - 4x + 3. Quel est le minimum de la fonction sur ℝ ?',
        options: ['A. 0', 'B. 1', 'C. -1', 'D. 3'],
        correctAnswer: 'C. -1',
        explanation: 'Le minimum de la fonction quadratique f(x) = x² - 4x + 3 est -1, atteint en x = 2.',
        subject: widget.subject,
        topic: 'Mathématiques',
        type: ExerciseType.multipleChoice,
        difficulty: DifficultyLevel.intermediate,
        timeLimit: 90,
        keywords: ['mathématiques', 'fonction', 'minimum'],
        isAiGenerated: false,
        createdAt: DateTime.now(),
      ),
    ];
  }

  void _startTimer() {
    if (_exercises.isNotEmpty) {
      _timeRemaining = _exercises[_currentQuestionIndex].timeLimit;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeRemaining > 0 && !_isAnswerSubmitted) {
          setState(() {
            _timeRemaining--;
          });
        } else {
          _handleTimeUp();
        }
      });
    }
  }

  void _handleTimeUp() {
    if (!_isAnswerSubmitted) {
      _submitAnswer();
    }
  }

  void _submitAnswer() {
    if (_isAnswerSubmitted) return;
    
    setState(() {
      _isAnswerSubmitted = true;
    });
    
    _timer?.cancel();
    
    // Calculate score
    Exercise currentExercise = _exercises[_currentQuestionIndex];
    bool isCorrect = _selectedAnswer == currentExercise.correctAnswer;
    double questionScore = 0.0;
    
    if (isCorrect) {
      _correctAnswers++;
      // Score based on time remaining (max 100 points)
      questionScore = ((_timeRemaining / currentExercise.timeLimit) * 0.5 + 0.5) * 100;
      _score += questionScore.round();
    }
    
    // Create attempt
    ExerciseAttempt attempt = ExerciseAttempt(
      id: _generateAttemptId(),
      exerciseId: currentExercise.id,
      userId: widget.user.id,
      userAnswer: _selectedAnswer ?? '',
      isCorrect: isCorrect,
      timeSpent: currentExercise.timeLimit - _timeRemaining,
      score: questionScore / 100,
      attemptedAt: DateTime.now(),
    );
    
    _attempts.add(attempt);
    _currentSession = QuizSession(
      id: _currentSession.id,
      userId: _currentSession.userId,
      subject: _currentSession.subject,
      exerciseIds: _currentSession.exerciseIds,
      attempts: {..._currentSession.attempts, currentExercise.id: attempt},
      startedAt: _currentSession.startedAt,
      overallScore: _score / (_exercises.length * 100),
      isCompleted: false,
    );
    
    // Save attempt
    _storageService.saveExerciseAttempt(attempt);
    
    // Show result for 2 seconds then move to next question
    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _exercises.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _isAnswerSubmitted = false;
      });
      
      _slideController.reset();
      _slideController.forward();
      _startTimer();
    } else {
      _completeQuiz();
    }
  }

  void _completeQuiz() {
    _timer?.cancel();
    
    // Update session as completed
    _currentSession = QuizSession(
      id: _currentSession.id,
      userId: _currentSession.userId,
      subject: _currentSession.subject,
      exerciseIds: _currentSession.exerciseIds,
      attempts: _currentSession.attempts,
      startedAt: _currentSession.startedAt,
      completedAt: DateTime.now(),
      overallScore: _score / (_exercises.length * 100),
      isCompleted: true,
    );
    
    _storageService.saveQuizSession(_currentSession);
    
    setState(() {
      _isQuizCompleted = true;
    });
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateAttemptId() {
    return 'attempt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    
    if (_isQuizCompleted) {
      return _buildResultsScreen();
    }
    
    return _buildQuizScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB3D9FF),
              Color(0xFF87CEEB),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Génération des exercices...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    Exercise currentExercise = _exercises[_currentQuestionIndex];
    double progress = (_currentQuestionIndex + 1) / _exercises.length;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB3D9FF),
              Color(0xFF87CEEB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                    Text(
                      'Quiz',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_currentQuestionIndex + 1}/${_exercises.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: progress * _progressAnimation.value,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Main content
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Timer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _timeRemaining <= 10 ? Colors.red.shade100 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_timeRemaining}s',
                              style: TextStyle(
                                color: _timeRemaining <= 10 ? Colors.red : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Question
                          Text(
                            currentExercise.question,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Options
                          Expanded(
                            child: Column(
                              children: currentExercise.options.map((option) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildOptionButton(option, currentExercise),
                                );
                              }).toList(),
                            ),
                          ),
                          
                          // Bottom character
                          if (!_isAnswerSubmitted)
                            Container(
                              height: 60,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 25,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 30,
                                          height: 2,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          width: 20,
                                          height: 2,
                                          color: Colors.grey[300],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, Exercise exercise) {
    bool isSelected = _selectedAnswer == option;
    bool isCorrect = option == exercise.correctAnswer;
    bool isWrong = _isAnswerSubmitted && isSelected && !isCorrect;
    bool showCorrect = _isAnswerSubmitted && isCorrect;
    
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black87;
    
    if (_isAnswerSubmitted) {
      if (showCorrect) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
      } else if (isWrong) {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
      }
    } else if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
      borderColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.primary;
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isAnswerSubmitted ? null : () {
          setState(() {
            _selectedAnswer = option;
          });
          
          // Auto-submit after selection
          Future.delayed(const Duration(milliseconds: 500), () {
            _submitAnswer();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          side: BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            if (_isAnswerSubmitted && showCorrect)
              Icon(Icons.check_circle, color: Colors.green, size: 20)
            else if (_isAnswerSubmitted && isWrong)
              Icon(Icons.cancel, color: Colors.red, size: 20)
            else if (isSelected && !_isAnswerSubmitted)
              Icon(Icons.radio_button_checked, color: Theme.of(context).colorScheme.primary, size: 20)
            else
              Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    double percentage = (_correctAnswers / _exercises.length) * 100;
    String message = percentage >= 80 ? 'Félicitation' : 
                     percentage >= 60 ? 'Bien joué' : 'Continuez vos efforts';
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB3D9FF),
              Color(0xFF87CEEB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                    Text(
                      'Quiz',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Results content
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Success message
                        Text(
                          message,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Score display
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_correctAnswers/${_exercises.length} correct',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Results button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to detailed results
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: Text(
                              'Voir mes resultats',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Bottom character
                        Container(
                          height: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 35,
                                      height: 3,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      width: 25,
                                      height: 3,
                                      color: Colors.grey[300],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}