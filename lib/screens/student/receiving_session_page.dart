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
import 'package:peer_to_peer_learning_network/screens/student/quiz_page.dart';


class ReceivingSessionPage extends StatefulWidget {
  const ReceivingSessionPage({super.key});

  @override
  State<ReceivingSessionPage> createState() => _ReceivingSessionPageState();
}

class _ReceivingSessionPageState extends State<ReceivingSessionPage> {
  String _studentName = '';
  bool _isDataLoaded = false;
  final String _serviceId = 'com.project.p2pln.p2p';

  final Map<String, String> _foundTeachers = {};
  bool _isSearching = false;
  String? _connectedTeacherId;
  String _connectedTeacherName = '';

  String? _receivingFileName;
  String? _receivingSubject;
  double _transferProgress = 0.0;
  final Map<int, String> _incomingFilePayloads = {};


  @override
  void initState() {
    super.initState();
    _loadDeviceAndUserData();
  }

  @override
  void dispose() {
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    super.dispose();
  }

  Future<void> _loadDeviceAndUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentName = prefs.getString('student_userName') ?? 'Student';
      _isDataLoaded = true;
    });
    _startDiscovery();
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
      Permission.location, Permission.bluetooth, Permission.bluetoothScan,
      Permission.bluetoothAdvertise, Permission.bluetoothConnect, Permission.nearbyWifiDevices,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All permissions must be granted to proceed.')));
    }
    return allGranted;
  }

  Future<void> _startDiscovery() async {
    if (await _checkAndRequestPermissions()) {
      try {
        setState(() => _isSearching = true);
        await Nearby().startDiscovery(
          _studentName, Strategy.P2P_STAR,
          onEndpointFound: (id, name, serviceId) => setState(() => _foundTeachers[id] = name),
          onEndpointLost: (id) => setState(() => _foundTeachers.remove(id)),
          serviceId: _serviceId,
        );
      } catch (e) {
        print("Error starting discovery: $e");
      }
    }
  }

  void _connectToTeacher(String teacherId, String teacherName) {
    try {
      Nearby().requestConnection(
        _studentName,
        teacherId,
        onConnectionInitiated: (id, info) {
          setState(() => _connectedTeacherName = info.endpointName);
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            setState(() {
              _connectedTeacherId = id;
              _isSearching = false;
              _foundTeachers.clear();
              Nearby().stopDiscovery();
            });
          } else {
            setState(() { _connectedTeacherId = null; _connectedTeacherName = ''; });
          }
        },
        onDisconnected: (id) {
          setState(() { _connectedTeacherId = null; _connectedTeacherName = ''; });
          _startDiscovery();
        },
      );
    } catch (e) {
      print("Error requesting connection: $e");
    }
  }

  void _acceptConnection(String id) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) async {
        if (payload.type == PayloadType.BYTES) {
          final str = String.fromCharCodes(payload.bytes!);
          try {
            final metadata = jsonDecode(str);
            if (metadata['type'] == 'metadata') {
              setState(() {
                _receivingFileName = metadata['filename'];
                _receivingSubject = metadata['subject'];
                _transferProgress = 0.0;
              });
            } else {
              await _saveFileFromBytes(payload.bytes!);
            }
          } catch (e) {
            await _saveFileFromBytes(payload.bytes!);
          }
        } else if (payload.type == PayloadType.FILE) {
          if (payload.uri != null) {
            _incomingFilePayloads[payload.id] = payload.uri!;
          }
        }
      },
      onPayloadTransferUpdate: (endpointId, payloadInfo) async {
        setState(() {
          if (payloadInfo.totalBytes > 0) {
            _transferProgress = payloadInfo.bytesTransferred / payloadInfo.totalBytes;
          }
        });

        if (payloadInfo.status == PayloadStatus.SUCCESS) {
          final contentUri = _incomingFilePayloads.remove(payloadInfo.id);
          if (contentUri != null) {
            await _saveFileFromPath(contentUri);
          }
        } else if (payloadInfo.status == PayloadStatus.FAILURE || payloadInfo.status == PayloadStatus.CANCELED) {
          setState(() {
            _receivingFileName = null;
            _receivingSubject = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File transfer failed.')));
        }
      },
    );
  }

  // THIS IS THE CORRECTED FUNCTION
  Future<void> _saveFileFromPath(String contentUri) async {
    if (_receivingFileName != null && _receivingSubject != null) {
      final directory = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${directory.path}/notes/$_receivingSubject');
      if (!await notesDir.exists()) {
        await notesDir.create(recursive: true);
      }

      final destinationFilepath = '${notesDir.path}/$_receivingFileName';

      // Use the correct helper method from the package
      bool success = await Nearby().copyFileAndDeleteOriginal(contentUri, destinationFilepath);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Received $_receivingFileName successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save the received file.')),
        );
      }

      setState(() { _receivingFileName = null; _receivingSubject = null; });
    }
  }

  Future<void> _saveFileFromBytes(Uint8List bytes) async {
    if (_receivingFileName != null && _receivingSubject != null) {
      final directory = await getApplicationDocumentsDirectory();
      final quizzesDir = Directory('${directory.path}/quizzes/$_receivingSubject');
      if (!await quizzesDir.exists()) {
        await quizzesDir.create(recursive: true);
      }
      final file = File('${quizzesDir.path}/$_receivingFileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Received $_receivingFileName successfully!')),
        );
        if (_receivingFileName!.toLowerCase().endsWith('.json') && _connectedTeacherId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuizPage(
                    quizFile: file,
                    teacherEndpointId: _connectedTeacherId!,
                  ),
            ),
          );
        }
    }
      setState(() { _receivingFileName = null; _receivingSubject = null; });
    }
  }

  // --- The build methods remain the same ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Find a Teacher'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
      ),
      body: _isDataLoaded
          ? (_connectedTeacherId != null ? _buildConnectedView() : _buildDiscoveryView())
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDiscoveryView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSearching) const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()),
              const SizedBox(width: 12),
              Text(
                _isSearching ? 'Searching for teachers...' : 'Initializing...',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: _foundTeachers.isEmpty
              ? const Center(child: Text('No teachers found yet.'))
              : ListView.builder(
            itemCount: _foundTeachers.length,
            itemBuilder: (context, index) {
              final teacherId = _foundTeachers.keys.elementAt(index);
              final teacherName = _foundTeachers[teacherId]!;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.school_rounded)),
                title: Text(teacherName),
                subtitle: const Text('Available to connect'),
                onTap: () => _connectToTeacher(teacherId, teacherName),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              'Connected to $_connectedTeacherName!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_receivingFileName == null)
              const Text(
                'Waiting to receive files...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              )
            else
              Column(
                children: [
                  Text(
                    'Receiving: $_receivingFileName',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _transferProgress,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 4),
                  Text('${(_transferProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}