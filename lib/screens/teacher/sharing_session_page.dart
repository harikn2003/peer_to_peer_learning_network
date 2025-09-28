import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' hide PermissionStatus;
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/models/quiz_models.dart';

class SharingSessionPage extends StatefulWidget {
  const SharingSessionPage({super.key});

  @override
  State<SharingSessionPage> createState() => _SharingSessionPageState();
}

class _SharingSessionPageState extends State<SharingSessionPage> {
  bool _isSharing = false;
  String _teacherName = '';
  bool _isDataLoaded = false;
  final String _serviceId = 'com.project.p2pln.p2p';

  final Map<String, String> _connectedStudents = {};
  List<File> _contentFiles = []; // To store all shareable files
  List<String> _subjects = [];
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  // UPDATED: Combined initial loading
  Future<void> _loadInitialData() async {
    await _loadDeviceAndUserData();
    await _loadContentFiles();
    await _loadSubjects(); // Load saved subjects
  }

  // NEW: Function to load subjects from SharedPreferences
  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subjects = prefs.getStringList('teacher_subjects') ?? [];
    });
  }

  // NEW: Function to save subjects to SharedPreferences
  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('teacher_subjects', _subjects);
  }


  Future<void> _loadDeviceAndUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherName = prefs.getString('teacher_userName') ?? 'Teacher';
      _isDataLoaded = true;
    });
  }

  Future<void> _loadContentFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final quizzesDir = Directory('${directory.path}/quizzes');
    final notesDir = Directory('${directory.path}/notes');
    List<File> allFiles = [];
    if (await quizzesDir.exists()) {
      allFiles.addAll(quizzesDir.listSync().whereType<File>());
    }
    if (await notesDir.exists()) {
      allFiles.addAll(notesDir.listSync().whereType<File>());
    }
    setState(() {
      _contentFiles = allFiles;
    });
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (!await Permission.location.serviceStatus.isEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please turn on your Location/GPS service.')));
      return false;
    }
    if (!await Permission.bluetooth.serviceStatus.isEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please turn on your Bluetooth.')));
      return false;
    }
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All permissions must be granted to proceed.')));
    }
    return allGranted;
  }

  Future<void> _toggleSharing() async {
    if (_isSharing) {
      await Nearby().stopAdvertising();
      await Nearby().stopAllEndpoints();
      setState(() {
        _isSharing = false;
        _connectedStudents.clear();
      });
    } else {
      if (await _checkAndRequestPermissions()) {
        try {
          setState(() => _isSharing = true);
          await Nearby().startAdvertising(
            _teacherName,
            Strategy.P2P_STAR,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: (id, status) {
              if (status != Status.CONNECTED) {
                setState(() => _connectedStudents.remove(id));
              }
            },
            onDisconnected: (id) {
              setState(() => _connectedStudents.remove(id));
            },
            serviceId: _serviceId,
          );
        } catch (e) {
          setState(() => _isSharing = false);
        }
      }
    }
  }

  Future<void> _saveResult(Map<String, dynamic> resultData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/quiz_results.json');

      List<dynamic> allResults = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          allResults = jsonDecode(content);
        }
      }

      allResults.add(resultData);
      await file.writeAsString(jsonEncode(allResults));
      print("Result saved successfully.");

    } catch (e) {
      print("Error saving result: $e");
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES) {
          final str = String.fromCharCodes(payload.bytes!);
          try {
            final data = jsonDecode(str);
            if (data['type'] == 'quiz_result') {
              // A student sent their results!
              final studentName = data['studentName'];
              final score = data['score'];
              final total = data['total'];

              // 1. Save the result
              _saveResult(data);

              // 2. Show an immediate notification
              // 2. Show a SnackBar notification
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Result from $studentName: $score/$total on "${data['quizTitle']}"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            print("Received unknown byte payload: $e");
          }
        }
      },
    );
    setState(() {
      _connectedStudents[id] = info.endpointName;
    });
  }
  // UPDATED: Now sends subject information in the metadata
  // UPDATED: This function now uses the best method for each file type
  Future<void> _sendFileToAllStudents(File file, String subject) async {
    if (_connectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No students connected.')));
      return;
    }

    String fileName = file.path.split('/').last;
    bool isQuiz = fileName.endsWith('.json');

    Map<String, dynamic> metadata = {
      'type': 'metadata',
      'filename': fileName,
      'subject': subject,
    };
    Uint8List metadataBytes = Uint8List.fromList(jsonEncode(metadata).codeUnits);

    for(String studentId in _connectedStudents.keys) {
      try {
        // 1. Send metadata for all file types
        await Nearby().sendBytesPayload(studentId, metadataBytes);

        // 2. Send the file itself
        if (isQuiz) {
          // Send small quiz files as bytes
          Uint8List fileBytes = await file.readAsBytes();
          await Nearby().sendBytesPayload(studentId, fileBytes);
        } else {
          // Send large note files (PDF, video) as a file stream
          await Nearby().sendFilePayload(studentId, file.path);
        }

      } catch (e) {
        print("Error sending to $studentId: $e");
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent $fileName to all students')),
      );
    }
  }

  // UPDATED: Now handles asking for a subject if the file is not a quiz
  void _showFileSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a file to send'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _contentFiles.length,
              itemBuilder: (context, index) {
                final file = _contentFiles[index];
                final fileName = file.path.split('/').last;
                return ListTile(
                  title: Text(fileName),
                  onTap: () async {
                    Navigator.pop(context); // Close the selection dialog

                    if (fileName.endsWith('.json')) {
                      // It's a quiz, we can read the subject from the file
                      final jsonString = await file.readAsString();
                      final jsonMap = jsonDecode(jsonString);
                      final quiz = Quiz.fromJson(jsonMap);
                      _sendFileToAllStudents(file, quiz.subject);
                    } else {
                      // It's a note, we need to ask for the subject
                      _askForSubject(file);
                    }
                  },
                );
              },
            ),
          ),
          actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')) ],
        );
      },
    );
  }
  // NEW: A dialog to ask the teacher for a note's subject before sending
  Future<void> _askForSubject(File file) async {
    String? selectedSubject;
    final newSubjectController = TextEditingController();
    const addNewKey = '---ADD_NEW---';

    showDialog(
      context: context,
      builder: (context) {
        // Use a StatefulBuilder to manage the dialog's own state
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Subject for "${file.path.split('/').last}"'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // List existing subjects
                    ..._subjects.map((subject) => RadioListTile<String>(
                      title: Text(subject),
                      value: subject,
                      groupValue: selectedSubject,
                      onChanged: (value) => setDialogState(() => selectedSubject = value),
                    )),
                    // Option to add a new one
                    RadioListTile<String>(
                      title: const Text('Add new subject...'),
                      value: addNewKey,
                      groupValue: selectedSubject,
                      onChanged: (value) => setDialogState(() => selectedSubject = value),
                    ),
                    // Show TextField only if "Add new" is selected
                    if (selectedSubject == addNewKey)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: newSubjectController,
                          autofocus: true,
                          decoration: const InputDecoration(hintText: "Enter new subject name"),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    String? finalSubject;
                    if (selectedSubject == addNewKey) {
                      if (newSubjectController.text.isNotEmpty) {
                        finalSubject = newSubjectController.text;
                        // Add the new subject to our main list if it's not already there
                        if (!_subjects.contains(finalSubject)) {
                          setState(() {
                            _subjects.add(finalSubject!);
                          });
                          _saveSubjects(); // Save the updated list
                        }
                      }
                    } else {
                      finalSubject = selectedSubject;
                    }

                    if (finalSubject != null) {
                      Navigator.pop(context); // Close the dialog
                      _sendFileToAllStudents(file, finalSubject);
                    } else {
                      // Optionally show a small error if nothing is selected/entered
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select or add a subject.')),
                      );
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('Sharing Session'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
        actions: [
          // NEW: Send File button in AppBar
          if (_isSharing && _connectedStudents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.send_rounded),
              onPressed: _showFileSelectionDialog,
              tooltip: 'Send File to Students',
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Your status card can go here if you want)
            Text('Connected Students (${_connectedStudents.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: _connectedStudents.isEmpty
                    ? const Center(child: Text('No students connected yet.'))
                    : ListView.builder(
                  itemCount: _connectedStudents.length,
                  itemBuilder: (context, index) {
                    final studentId = _connectedStudents.keys.elementAt(index);
                    final studentName = _connectedStudents[studentId]!;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: Text(studentName.isNotEmpty ? studentName[0] : 'S', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      title: Text(studentName),
                      subtitle: const Text('Connected'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDataLoaded ? _toggleSharing : null,
        backgroundColor: _isDataLoaded
            ? (_isSharing ? Colors.red.shade700 : Colors.orange)
            : Colors.grey,
        icon: _isDataLoaded
            ? Icon(_isSharing ? Icons.stop_rounded : Icons.wifi_tethering_rounded)
            : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
        label: Text(
          _isDataLoaded
              ? (_isSharing ? 'Stop Sharing' : 'Start Sharing Session')
              : 'Loading...',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}