import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'question_generator.dart';

class CreateQuestionAI extends StatefulWidget {
  const CreateQuestionAI({super.key});

  @override
  CreateQuestionAIState createState() => CreateQuestionAIState();
}

class CreateQuestionAIState extends State<CreateQuestionAI> {
 final TextEditingController _textController = TextEditingController();
  final TextEditingController _quizNameController = TextEditingController();
  final QuestionGenerator _questionGenerator = QuestionGenerator();
  final TextEditingController _subjectController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;
  String? _fileName;
  bool _isPDFMode = true;

@override
void dispose() {
  _textController.dispose();
  _quizNameController.dispose();
  _subjectController.dispose();
  super.dispose();
}


Future<void> _saveQuiz() async {
  if (_questions.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please generate questions before saving.')),
    );
    return;
  }

  // Show a dialog to enter the quiz name and subject
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Save Quiz'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextField(
              controller: _quizNameController,
              decoration: const InputDecoration(hintText: "Enter quiz name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(hintText: "Enter quiz subject"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () async {
            if (_quizNameController.text.isNotEmpty && _subjectController.text.isNotEmpty) {
              Navigator.of(context).pop();
              await _saveQuizToFirebase();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter both quiz name and subject')),
              );
            }
          },
        ),
      ],
    ),
  );
}


 Future<void> _saveQuizToFirebase() async {
  setState(() {
    FocusScope.of(context).unfocus();
    _isLoading = true;
  });

  try {
    final User? user = _auth.currentUser;
    if (user != null) {
      final newQuizRef = _database.child('lecturers').child(user.uid).child('quizzes').push();
      await newQuizRef.set({
        'name': _quizNameController.text,
        'subject': _subjectController.text,
        'questions': _questions,
        'createdAt': ServerValue.timestamp,
      });
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz saved successfully')),
        );
      }
    } else {
      throw Exception('User not logged in');
    }
  } catch (e) {
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quiz: ${e.toString()}')),
      );
    }
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Future<void> _pickPDFAndExtractText() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
        _fileName = result.files.single.name;
      });

      try {
        final File file = File(result.files.single.path!);
        final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        String docText = extractor.extractText();
        
        // Truncate the text if it's too long
        if (docText.length > 4000) {
          docText = docText.substring(0, 4000);
        }

        setState(() {
          _textController.text = docText;
          _isLoading = false;
        });

        document.dispose();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if(mounted){
   ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error extracting text from PDF: ${e.toString()}')),
        );
        }
     
      }
    }
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final questions = await _questionGenerator.generateQuestions(_textController.text);
      setState(() {
        _questions = questions;
        FocusScope.of(context).unfocus();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[800]!, Colors.blue[400]!],
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildModeSelection(),
                        const SizedBox(height: 20),
                        _buildContentInput(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                        const SizedBox(height: 20),
                        _buildQuestionsList(),
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
          'Create Questions with AI',
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

Widget _buildModeSelection() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeChip('PDF', _isPDFMode, (selected) {
          setState(() => _isPDFMode = selected);
        }),
        _buildModeChip('Text', !_isPDFMode, (selected) {
          setState(() => _isPDFMode = !selected);
        }),
      ],
    ),
  );
}

Widget _buildModeChip(String label, bool isSelected, Function(bool) onSelected) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Colors.blue[800],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.blue[800],
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildContentInput() {
  return _isPDFMode
      ? Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_fileName ?? 'Upload PDF'),
              onPressed: _isLoading ? null : _pickPDFAndExtractText,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _textController,
              hintText: 'PDF text will appear here...',
              readOnly: true,
            ),
          ],
        )
      : _buildTextField(
          controller: _textController,
          hintText: 'Enter your text here...',
        );
}

Widget _buildTextField({
  required TextEditingController controller,
  required String hintText,
  bool readOnly = false,
}) {
  return TextField(
    controller: controller,
    maxLines: 5,
    readOnly: readOnly,
    decoration: InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.blue[800]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
      ),
    ),
  );
}

Widget _buildActionButtons() {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          icon: Icon(_isLoading ? null : Icons.create),
          label: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text('Generate Questions'),
          onPressed: _isLoading ? null : _generateQuestions,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.blue[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Quiz'),
          onPressed: _isLoading ? null : _saveQuiz,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ],
  );
}

Widget _buildQuestionsList() {
  return _questions.isEmpty
      ? Center(
          child: Text(
            'No questions generated yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        )
      : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questions.length,
          itemBuilder: (context, index) {
            final question = _questions[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}: ${question['question'] ?? 'No question text'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (question['options'] != null)
                      ...List.generate(
                        (question['options'] as List).length,
                        (optionIndex) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                '${String.fromCharCode(65 + optionIndex)}. ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  '${question['options'][optionIndex]}',
                                  style: TextStyle(
                                    color: question['options'][optionIndex] == question['answer']
                                        ? Colors.green
                                        : null,
                                    fontWeight: question['options'][optionIndex] == question['answer']
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (question['options'][optionIndex] == question['answer'])
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            ],
                          ),
                        ),
                      )
                    else
                      const Text(
                        'No options available',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            );
          },
        );
}


}