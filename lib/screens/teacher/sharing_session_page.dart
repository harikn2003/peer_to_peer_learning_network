import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharingSessionPage extends StatefulWidget {
  const SharingSessionPage({super.key});

  @override
  State<SharingSessionPage> createState() => _SharingSessionPageState();
}

class _SharingSessionPageState extends State<SharingSessionPage> {
  bool _isSharing = false;
  String _teacherName = 'Teacher';
  final String _serviceId = 'com.project.p2pln'; // Must be the same for student app

  // Placeholder data for selected content
  final List<String> _selectedContent = [
    "Water Cycle Quiz.json",
    "Chapter 5 Notes.pdf",
  ];

  // Real data for connected students: Map<endpointId, userName>
  final Map<String, String> _connectedStudents = {};

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherName = prefs.getString('teacher_userName') ?? 'Teacher';
    });
  }

  Future<bool> _requestPermissions() async {
    if (!await Permission.location.request().isGranted ||
        !await Permission.bluetooth.request().isGranted ||
        !await Permission.bluetoothAdvertise.request().isGranted ||
        !await Permission.bluetoothConnect.request().isGranted ||
        !await Permission.nearbyWifiDevices.request().isGranted) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permissions must be granted to share content.')));
      }
      return false;
    }
    return true;
  }

  Future<void> _toggleSharing() async {
    if (_isSharing) {
      // Logic to STOP sharing
      await Nearby().stopAdvertising();
      await Nearby().stopAllEndpoints();
      setState(() {
        _connectedStudents.clear();
        _isSharing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stopped sharing session.')));
      }
    } else {
      // Logic to START sharing
      if (await _requestPermissions()) {
        try {
          bool started = await Nearby().startAdvertising(
            _teacherName,
            Strategy.P2P_STAR,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Connected to: ${_connectedStudents[id]}')));
                }
              }
            },
            onDisconnected: (id) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Disconnected from: ${_connectedStudents[id]}')));
              }
              setState(() {
                _connectedStudents.remove(id);
              });
            },
            serviceId: _serviceId,
          );

          if (started) {
            setState(() {
              _isSharing = true;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Started sharing session!')));
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting session: $e')));
          }
        }
      }
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    // Automatically accept all incoming connections
    setState(() {
      // THIS IS THE FIX: Use info.endpointName
      _connectedStudents[id] = info.endpointName;
    });
    Nearby().acceptConnection(id, onPayLoadRecieved: (endpointId, payload) {
      // Teacher can receive data back here if needed
    });
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            Text('Content to be Shared', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildSelectedContentList(),
            const SizedBox(height: 24),
            Text('Connected Students (${_connectedStudents.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildConnectedStudentsList(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleSharing,
        backgroundColor: _isSharing ? Colors.red.shade700 : Colors.green.shade200,
        icon: Icon(_isSharing ? Icons.stop_rounded : Icons.wifi_tethering_rounded),
        label: Text(
          _isSharing ? 'Stop Sharing' : 'Start Sharing Session',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _isSharing ? Colors.green.shade100 : Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _isSharing ? Icons.check_circle_rounded : Icons.info_rounded,
              color: _isSharing ? Colors.green.shade800 : Colors.grey.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isSharing ? 'Session is active. Students can now connect.' : 'Session is offline. Tap below to start.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isSharing ? Colors.green.shade900 : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContentList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _selectedContent.length,
        itemBuilder: (context, index) {
          final contentName = _selectedContent[index];
          return ListTile(
            leading: const Icon(Icons.description_rounded, color: Colors.blueGrey),
            title: Text(contentName),
          );
        },
      ),
    );
  }

  Widget _buildConnectedStudentsList() {
    final studentEntries = _connectedStudents.entries.toList();
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: studentEntries.isEmpty
            ? const Center(child: Text('No students connected yet.'))
            : ListView.builder(
          itemCount: studentEntries.length,
          itemBuilder: (context, index) {
            final studentName = studentEntries[index].value;
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
    );
  }
}