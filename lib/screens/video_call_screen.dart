import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart'; // Import Agora SDK
import '../services/api_service.dart';

// IMPORTANT: Replace this with the App ID you obtained from Agora
const String appId = "YOUR_AGORA_APP_ID_HERE";

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String userId; // User's ID for token generation

  const VideoCallScreen({Key? key, required this.channelName, required this.userId}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final ApiService _apiService = ApiService();
  String? _token; // Secure token received from our backend
  int? _remoteUid; // UID of the remote user (the vet)
  bool _localUserJoined = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    _fetchTokenAndInitialize();
  }

  // --- 1. Fetch Token from Backend and Initialize Agora ---
  Future<void> _fetchTokenAndInitialize() async {
    // 1. Fetch token from our Node.js server
    final result = await _apiService.getToken(widget.channelName, widget.userId);
    final token = result['token'];

    if (token == null || !mounted) return;

    setState(() { _token = token; });

    // 2. Initialize Agora Engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
    ));

    // 3. Set up event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() { _localUserJoined = true; });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() { _remoteUid = remoteUid; }); // Vet joined
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() { _remoteUid = null; }); // Vet left
        },
        onTokenPrivilegeWillExpire: (connection, token) {
          // If token expires, you would fetch a new one here
        },
        onError: (err, msg) => print('Agora Error: $err, $msg'),
      ),
    );

    // 4. Enable Video and Join Channel
    await _engine.enableVideo();
    await _engine.startPreview();

    // Use a unique UID for each user (based on a hash of the user ID)
    final uid = int.tryParse(widget.userId.substring(0, 8), radix: 16) ?? 0;
    
    // Join the channel using the fetched token
    await _engine.joinChannel(
      token: _token!,
      channelId: widget.channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  // --- UI Builder Functions ---

  // Shows the local user's video view
  Widget _localVideoView() {
    if (_localUserJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return Center(child: Text('Joining Channel...', style: TextStyle(color: Colors.white)));
    }
  }

  // Shows the remote user's (vet's) video view
  Widget _remoteVideoView() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: 'channelName'),
        ),
      );
    } else {
      return Center(child: Text('Waiting for Vet...', style: TextStyle(color: Colors.white)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Background: Remote User Video (The Vet)
          Center(child: _remoteVideoView()),

          // Foreground: Local User Video and Controls
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 100,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _localVideoView(),
                ),
              ),
            ),
          ),
          // Call End Button
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: () => Navigator.pop(context),
                  label: Text('End Call'),
                  icon: Icon(Icons.call_end),
                  backgroundColor: Colors.red,
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}