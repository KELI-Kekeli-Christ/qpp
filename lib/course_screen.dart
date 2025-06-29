import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import 'quiz_screen.dart';

class CourseScreen extends StatefulWidget {
  final String subject;
  final UserModel user;
  
  const CourseScreen({
    super.key, 
    required this.subject,
    required this.user,
  });

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Cours par matière
  final Map<String, List<Course>> _coursesBySubject = {
    'Mathématiques': [
      Course(
        title: 'Arithmétique de base',
        description: 'Additions, soustractions, multiplications et divisions',
        duration: '30 min',
        difficulty: 'Débutant',
        chapters: [
          'Addition et soustraction',
          'Multiplication',
          'Division',
          'Exercices pratiques',
        ],
      ),
      Course(
        title: 'Algèbre',
        description: 'Introduction aux équations et variables',
        duration: '45 min',
        difficulty: 'Intermédiaire',
        chapters: [
          'Variables et expressions',
          'Équations du premier degré',
          'Systèmes d\'équations',
          'Applications pratiques',
        ],
      ),
      Course(
        title: 'Géométrie',
        description: 'Formes, aires et volumes',
        duration: '40 min',
        difficulty: 'Intermédiaire',
        chapters: [
          'Figures géométriques',
          'Calcul d\'aires',
          'Volumes et solides',
          'Théorème de Pythagore',
        ],
      ),
    ],
    'Français': [
      Course(
        title: 'Grammaire française',
        description: 'Les bases de la grammaire',
        duration: '35 min',
        difficulty: 'Débutant',
        chapters: [
          'Classes grammaticales',
          'Accord des adjectifs',
          'Conjugaison des verbes',
          'La phrase complexe',
        ],
      ),
      Course(
        title: 'Orthographe',
        description: 'Règles d\'orthographe et exceptions',
        duration: '30 min',
        difficulty: 'Intermédiaire',
        chapters: [
          'Homophones',
          'Accords particuliers',
          'Mots invariables',
          'Dictée préparée',
        ],
      ),
      Course(
        title: 'Littérature',
        description: 'Analyse de textes et œuvres',
        duration: '50 min',
        difficulty: 'Avancé',
        chapters: [
          'Genres littéraires',
          'Figures de style',
          'Analyse de poèmes',
          'Commentaire de texte',
        ],
      ),
    ],
    'Sciences': [
      Course(
        title: 'Biologie cellulaire',
        description: 'Structure et fonction des cellules',
        duration: '40 min',
        difficulty: 'Intermédiaire',
        chapters: [
          'La cellule eucaryote',
          'Membrane plasmique',
          'Organites cellulaires',
          'Division cellulaire',
        ],
      ),
      Course(
        title: 'Physique mécanique',
        description: 'Forces et mouvements',
        duration: '45 min',
        difficulty: 'Intermédiaire',
        chapters: [
          'Cinématique',
          'Forces et interactions',
          'Énergie mécanique',
          'Applications pratiques',
        ],
      ),
    ],
    'Chimie': [
      Course(
        title: 'Chimie générale',
        description: 'Atomes, molécules et réactions',
        duration: '40 min',
        difficulty: 'Intermédiaire',
        chapters: [
          'Structure atomique',
          'Tableau périodique',
          'Liaisons chimiques',
          'Réactions chimiques',
        ],
      ),
      Course(
        title: 'Chimie organique',
        description: 'Composés carbonés et leurs propriétés',
        duration: '50 min',
        difficulty: 'Avancé',
        chapters: [
          'Hydrocarbures',
          'Fonctions organiques',
          'Isomérisme',
          'Réactions organiques',
        ],
      ),
    ],
    'Histoire': [
      Course(
        title: 'Histoire de France',
        description: 'Des origines à nos jours',
        duration: '60 min',
        difficulty: 'Intermédiaire',
        chapters: [
          'Antiquité et Moyen Âge',
          'Renaissance et Monarchie',
          'Révolution française',
          'Époque contemporaine',
        ],
      ),
      Course(
        title: 'Histoire mondiale',
        description: 'Grandes civilisations et événements',
        duration: '55 min',
        difficulty: 'Avancé',
        chapters: [
          'Civilisations antiques',
          'Grandes découvertes',
          'Guerres mondiales',
          'Monde contemporain',
        ],
      ),
    ],
    'Géographie': [
      Course(
        title: 'Géographie physique',
        description: 'Relief, climat et environnement',
        duration: '45 min',
        difficulty: 'Intermédiaire',
        chapters: [
          'Formation du relief',
          'Climats et météorologie',
          'Hydrographie',
          'Écosystèmes',
        ],
      ),
      Course(
        title: 'Géographie humaine',
        description: 'Population et développement',
        duration: '50 min',
        difficulty: 'Avancé',
        chapters: [
          'Démographie mondiale',
          'Urbanisation',
          'Développement économique',
          'Mondialisation',
        ],
      ),
    ],
    'Anglais': [
      Course(
        title: 'Anglais débutant',
        description: 'Bases de la langue anglaise',
        duration: '35 min',
        difficulty: 'Débutant',
        chapters: [
          'Alphabet et phonétique',
          'Grammaire de base',
          'Vocabulaire essentiel',
          'Conversations simples',
        ],
      ),
      Course(
        title: 'Anglais intermédiaire',
        description: 'Perfectionnement linguistique',
        duration: '45 min',
        difficulty: 'Intermédiaire',
        chapters: [
          'Temps et aspects',
          'Vocabulaire avancé',
          'Expression écrite',
          'Compréhension orale',
        ],
      ),
    ],
  };

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

  Color _getSubjectColor() {
    switch (widget.subject) {
      case 'Mathématiques':
        return const Color(0xFF3B82F6);
      case 'Français':
        return const Color(0xFF10B981);
      case 'Sciences':
        return const Color(0xFF8B5CF6);
      case 'Chimie':
        return const Color(0xFFEC4899);
      case 'Histoire':
        return const Color(0xFFF59E0B);
      case 'Géographie':
        return const Color(0xFF06B6D4);
      case 'Anglais':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6A5AE0);
    }
  }

  IconData _getSubjectIcon() {
    switch (widget.subject) {
      case 'Mathématiques':
        return Icons.calculate;
      case 'Français':
        return Icons.translate;
      case 'Sciences':
        return Icons.science;
      case 'Chimie':
        return Icons.biotech;
      case 'Histoire':
        return Icons.history_edu;
      case 'Géographie':
        return Icons.public;
      case 'Anglais':
        return Icons.language;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = _coursesBySubject[widget.subject] ?? [];
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getSubjectColor(),
              _getSubjectColor().withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        _getSubjectIcon(),
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subject,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${courses.length} cours disponibles',
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
                ),
                
                // Course list
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return _buildCourseCard(course, index);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCourseDetails(course),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getSubjectColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: _getSubjectColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFCBD5E0),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(course.duration, Icons.access_time),
                  const SizedBox(width: 12),
                  _buildInfoChip(course.difficulty, Icons.speed),
                  const SizedBox(width: 12),
                  _buildInfoChip('${course.chapters.length} chapitres', Icons.list),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF718096),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  void _showCourseDetails(Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Course title
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 24),
              
              // Course info
              Row(
                children: [
                  _buildInfoChip(course.duration, Icons.access_time),
                  const SizedBox(width: 12),
                  _buildInfoChip(course.difficulty, Icons.speed),
                ],
              ),
              const SizedBox(height: 32),
              
              // Chapters
              const Text(
                'Chapitres du cours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  itemCount: course.chapters.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getSubjectColor(),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              course.chapters[index],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: _getSubjectColor()),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: _getSubjectColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizScreen(
                              subject: widget.subject,
                              user: widget.user,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getSubjectColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Commencer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Course {
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final List<String> chapters;

  Course({
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.chapters,
  });
