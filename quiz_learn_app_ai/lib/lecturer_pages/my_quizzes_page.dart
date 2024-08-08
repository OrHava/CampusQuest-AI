import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:quiz_learn_app_ai/lecturer_pages/create_quiz_page.dart';
import 'package:quiz_learn_app_ai/lecturer_pages/lecturer_quiz_overview.dart';
import 'package:quiz_learn_app_ai/lecturer_pages/quiz_details_page.dart';
import 'package:intl/intl.dart';
import 'package:quiz_learn_app_ai/services/firebase_service.dart'; // Add this import for date formatting

class MyQuizzesPage extends StatefulWidget {
  const MyQuizzesPage({super.key});

  @override
  MyQuizzesPageState createState() => MyQuizzesPageState();
}

class MyQuizzesPageState extends State<MyQuizzesPage> {
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;
     final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _quizzes = await _firebaseService.loadQuizzes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quizzes: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
//Delete quiz there are no longer needed
 Future<void> _deleteQuiz(String quizId) async {
    try {
      await _firebaseService.deleteQuiz(quizId);
      
      setState(() {
        _quizzes.removeWhere((quiz) => quiz['id'] == quizId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting quiz: ${e.toString()}')),
        );
      }
    }
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
Color(0xFFf2b39b), // Lighter #eb8671
Color(0xFFf19b86), // Lighter #ea7059
Color(0xFFf3a292), // Lighter #ef7d5d
Color(0xFFf8c18e), // Lighter #f8a567
Color(0xFFfcd797), // Lighter #fecc63
Color(0xFFcdd7a7), // Lighter #a7c484
Color(0xFF8fb8aa), // Lighter #5b9f8d
Color(0xFF73adbb), // Lighter #257b8c
Color(0xFFcc7699), // Lighter #ad3d75
Color(0xFF84d9db), // Lighter #1fd1d5
Color(0xFF85a8cf), // Lighter #2e7cbc
Color(0xFF8487ac), // Lighter #3d5488
Color(0xFFb7879c), // Lighter #99497f
Color(0xFF86cfd6), // Lighter #23b7c1
        ],
      ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildQuizList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'My Quizzes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizList() {
    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No quizzes found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        itemCount: _quizzes.length,
        itemBuilder: (BuildContext context, int index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildQuizCard(_quizzes[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _navigateToQuizDetails(quiz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      quiz['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(quiz['id']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_events_rounded, color: Colors.green),
                    onPressed: () => _navigateToQuizOverview(quiz['id']),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoChip(Icons.subject, quiz['subject'] ?? 'Not specified'),
              const SizedBox(height: 4),
              _buildInfoChip(Icons.question_answer, '${quiz['questionCount'] - 1} questions'),
              const SizedBox(height: 4),
              _buildInfoChip(
                Icons.calendar_today,
                'Created on ${DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(quiz['createdAt']))}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue[800]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.blue[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToCreateQuiz(),
      icon: const Icon(Icons.add),
      label: const Text('Create Quiz'),
      backgroundColor: Colors.blue[800],
    );
  }

  void _navigateToQuizDetails(Map<String, dynamic> quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailsPage(
          quizId: quiz['id'],
          initialQuizName: quiz['name'],
        ),
      ),
    ).then((_) => _loadQuizzes());
  }

  void _navigateToCreateQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateQuizPage()),
    ).then((_) => _loadQuizzes());
  }


  void _navigateToQuizOverview(String quizId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LecturerQuizOverview(quizId: quizId)),
    ).then((_) => _loadQuizzes());
  }
//Delete quiz there are no longer needed
  void _showDeleteConfirmation(String quizId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Quiz'),
          content: const Text('Are you sure you want to delete this quiz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteQuiz(quizId);
              },
            ),
          ],
        );
      },
    );
  }
}
