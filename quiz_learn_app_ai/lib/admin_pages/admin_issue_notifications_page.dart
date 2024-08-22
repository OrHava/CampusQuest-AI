import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quiz_learn_app_ai/auth_pages/loading_page.dart';
import 'package:quiz_learn_app_ai/notifications/issue_report_message.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class AdminIssueNotificationReport extends StatefulWidget {
  const AdminIssueNotificationReport({super.key});

  @override
  AdminIssueNotificationReportState createState() =>
      AdminIssueNotificationReportState();
}

class AdminIssueNotificationReportState
    extends State<AdminIssueNotificationReport> {
  List<IssueReportNotifications> issueReports = [];
  Set<int> expandedIssueMessages = {};
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIssueReports();
  }

  Future<void> _loadIssueReports() async {
    setState(() {
      _isLoading = true;
    });
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      // Load existing messages
      final DataSnapshot snapshot =
          await _database.child('issue_reports').child('general_reports').get();

      final data = snapshot.value;
      if (data != null) {
        final messagesMap =
            Map<dynamic, dynamic>.from(data as Map<dynamic, dynamic>);
        setState(() {
          issueReports = messagesMap.values
              .map((messageData) => IssueReportNotifications.fromMap(
                  Map<dynamic, dynamic>.from(messageData)))
              .toList();
        });
      }

      // Start listening for changes
      _database
          .child('issue_reports')
          .child('general_reports')
          .onValue
          .listen((event) {
        final data = event.snapshot.value;
        if (data != null) {
          final messagesMap =
              Map<dynamic, dynamic>.from(data as Map<dynamic, dynamic>);
          setState(() {
            issueReports = messagesMap.values
                .map((messageData) => IssueReportNotifications.fromMap(
                    Map<dynamic, dynamic>.from(messageData)))
                .toList();
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading report notifications: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> removeIssueReportMessage(
      IssueReportNotifications message) async {
    User? user = _auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      await _database
          .child('issue_reports')
          .child('general_reports')
          .child(message.notificationId)
          .remove();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing message: $e');
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: LoadingPage())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFf2b39b),
                    Color(0xFFf19b86),
                    Color(0xFFf3a292),
                    Color(0xFFf8c18e),
                    Color(0xFFfcd797),
                    Color(0xFFcdd7a7),
                    Color(0xFF8fb8aa),
                    Color(0xFF73adbb),
                    Color(0xFFcc7699),
                    Color(0xFF84d9db),
                    Color(0xFF85a8cf),
                    Color(0xFF8487ac),
                    Color(0xFFb7879c),
                    Color(0xFF86cfd6),
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
                        child: Column(
                          children: [
                            issueReports.isEmpty
                                ? const Center(child: Text('No issue reports'))
                                : Text(
                                    'Issue Reports',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo[800],
                                    ),
                                  ),
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _buildIssueReportsList(),
                          ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Issue Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadIssueReports,
          ),
        ],
      ),
    );
  }

  Widget _buildIssueReportsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: issueReports.length,
        itemBuilder: (context, index) {
          final message = issueReports[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    child: Text(
                      message.senderEmail[0].toUpperCase(),
                      style: TextStyle(
                          color: Colors.indigo[800],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    message.title.capitalize(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    message.date.toLocal().toString(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () {
                    setState(() {
                      if (expandedIssueMessages.contains(index)) {
                        expandedIssueMessages.remove(index);
                      } else {
                        expandedIssueMessages.add(index);
                      }
                    });
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[400]),
                    onPressed: () {
                      setState(() {
                        issueReports.removeAt(index);
                        removeIssueReportMessage(message);
                      });
                    },
                  ),
                ),
                if (expandedIssueMessages.contains(index))
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject: ${message.subject}',
                          style: TextStyle(
                              color: Colors.indigo[800],
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Issue: ${message.data}',
                          style: TextStyle(
                              color: Colors.indigo[800],
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Sender ID: ${message.sender}',
                          style: TextStyle(
                              color: Colors.indigo[800],
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Sender Email: ${message.senderEmail}',
                          style: TextStyle(
                              color: Colors.indigo[800],
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Informed Admins: ${message.informedAdmins}',
                          style: TextStyle(
                              color: Colors.indigo[800],
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
