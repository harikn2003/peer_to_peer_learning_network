import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:location/location.dart' hide PermissionStatus;

class SharingSessionPage extends StatefulWidget {
  const SharingSessionPage({super.key});

  @override
  State<SharingSessionPage> createState() => _SharingSessionPageState();
}

class _SharingSessionPageState extends State<SharingSessionPage> {
  bool _isSharing = false;
  String _teacherName = '';
  String _deviceId = '';
  bool _isDataLoaded = false;
  final String _serviceId = 'com.project.p2pln.p2p';

  final Map<String, String> _connectedStudents = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceAndUserData();
  }

  @override
  void dispose() {
    Nearby().stopAdvertising();
    Nearby().stopAllEndpoints();
    super.dispose();
  }

  Future<void> _loadDeviceAndUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _teacherName = prefs.getString('teacher_userName') ?? 'Teacher';
      _deviceId = androidInfo.id;
      _isDataLoaded = true;
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

          // ADDED: A print statement to verify the name before advertising
          print("--- Broadcasting with name: $_teacherName ---");

          bool started = await Nearby().startAdvertising(
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
          if(!started) {
            setState(() => _isSharing = false);
          }
        } catch (e) {
          print("Error starting advertising: $e");
          setState(() => _isSharing = false);
        }
      }
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {},
    );
    setState(() {
      _connectedStudents[id] = info.endpointName;
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
                    final studentName = _connectedStudents.values.elementAt(index);
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
            ? (_isSharing ? Colors.red.shade700 : Colors.indigo)
            : Colors.grey,
        icon: _isDataLoaded
            ? Icon(_isSharing ? Icons.stop_rounded : Icons.wifi_tethering_rounded)
            : const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
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