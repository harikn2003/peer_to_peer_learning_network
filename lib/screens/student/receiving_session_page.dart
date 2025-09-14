import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' hide PermissionStatus; // Hides conflicting class
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceivingSessionPage extends StatefulWidget {
  const ReceivingSessionPage({super.key});

  @override
  State<ReceivingSessionPage> createState() => _ReceivingSessionPageState();
}

class _ReceivingSessionPageState extends State<ReceivingSessionPage> {
  String _studentName = '';
  String _deviceId = '';
  bool _isDataLoaded = false;
  final String _serviceId = 'com.project.p2pln.p2p';

  final Map<String, String> _foundTeachers = {};
  bool _isSearching = false;
  String? _connectedTeacherId;
  String _connectedTeacherName = '';

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
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _studentName = prefs.getString('student_userName') ?? 'Student';
      _deviceId = androidInfo.id;
      _isDataLoaded = true;
    });
    _startDiscovery();
  }

  // UPDATED PERMISSION LOGIC TO MATCH THE TEACHER'S
  Future<bool> _checkAndRequestPermissions() async {
    // 1. Check Location Service Status
    if (!await Permission.location.serviceStatus.isEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please turn on your Location/GPS service.')));
      return false;
    }

    // 2. Check Bluetooth Service Status
    if (!await Permission.bluetooth.serviceStatus.isEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please turn on your Bluetooth.')));
      return false;
    }

    // 3. Request App-Level Permissions
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

  Future<void> _startDiscovery() async {
    if (await _checkAndRequestPermissions()) { // Using the new function
      try {
        setState(() => _isSearching = true);
        await Nearby().startDiscovery(
          _studentName,
          Strategy.P2P_STAR,
          onEndpointFound: (id, name, serviceId) {
            setState(() {
              _foundTeachers[id] = name;
            });
          },
          onEndpointLost: (id) {
            setState(() {
              _foundTeachers.remove(id);
            });
          },
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
          setState(() {
            _connectedTeacherName = info.endpointName;
          });
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              print("STUDENT: Payload received from $endpointId!");
            },
            onPayloadTransferUpdate: (endpointId, payloadInfo) {},
          );
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
            // Handle connection failure
            setState(() {
              _connectedTeacherId = null;
              _connectedTeacherName = '';
            });
          }
        },
        onDisconnected: (id) {
          setState(() {
            _connectedTeacherId = null;
            _connectedTeacherName = '';
          });
          _startDiscovery(); // Restart discovery after disconnection
        },
      );
    } catch (e) {
      print("Error requesting connection: $e");
    }
  }

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
              ? const Center(child: Text('No teachers found yet. Make sure the teacher has started a session.'))
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
    // A small fix to prevent a crash if the teacher name is not found
    //final teacherName = _foundTeachers[_connectedTeacherId] ?? _connectedTeacherId ?? 'Teacher';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          Text(
            'Connected to $_connectedTeacherName!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Waiting to receive files...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}