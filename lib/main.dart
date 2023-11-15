import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  onPressCreateSDPBtn() {}

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'WebRTC-APP',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _offer = false;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;
  // 비디오 정의
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  final sdpController = TextEditingController();

  @override
  dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    sdpController.dispose();
    super.dispose();
  }

  @override
  // 생성할 각 렌더러에서 메서드 호출을 할 수 있음
  void initState() {
    initRenderers();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });
    super.initState();
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {
          "url": "stun:stun.l.google.com:19302"
        },
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandaory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };
    _localStream = await _getUserMedia();

    RTCPeerConnection pc = await createPeerConnection(configuration, offerSdpConstraints);

    pc.addStream(_localStream);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(
          json.encode(
            {
              'candidate': e.candidate.toString(),
              'sdpMid': e.sdpMid.toString(),
              'sdpMlineIndex': e.sdpMLineIndex.toString(),
            },
          ),
        );
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ${stream.id}');
      _remoteRenderer.srcObject = stream;
    };

    return pc;
  }

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'facingMode': 'user',
      }
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localRenderer.srcObject = stream;

    return stream;
  }

  void _createOffer() async {
    RTCSessionDescription description = await _peerConnection.createOffer({
      'offerToReceiveVideo': 1
    });
    var session = parse(description.sdp!);
    print(json.encode(session));
    _offer = true;

    _peerConnection.setLocalDescription(description);
  }

  SizedBox VideoRenderers() => SizedBox(
        height: 210,
        child: Row(
          children: [
            Flexible(
              child: Container(
                key: const Key('local'),
                margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                decoration: const BoxDecoration(color: Colors.black),
                child: RTCVideoView(_localRenderer),
              ),
            ),
            Flexible(
              child: Container(
                key: const Key('remote'),
                margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                decoration: const BoxDecoration(color: Colors.black),
                child: RTCVideoView(_remoteRenderer),
              ),
            ),
          ],
        ),
      );

  Row offerAndAnswerButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: _createOffer,
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.amber)),
            child: const Text('Offer'),
          ),
          ElevatedButton(
            onPressed: null, // createAnswer
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.amber)),
            child: const Text('Answer'),
          ),
        ],
      );

  Padding sdpCandidateTF() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: sdpController,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          maxLength: TextField.noMaxLength,
        ),
      );

  Row sdpCandidateButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: null, // _setRemoteDescription,
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.amber)),
            child: const Text('Set Remote Desc'),
          ),
          ElevatedButton(
            onPressed: null, // _setCandidate,
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.amber)),
            child: const Text('Set Candidate'),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('title'),
        ),
        body: Container(
          child: Column(
            children: [
              VideoRenderers(),
              offerAndAnswerButtons(),
              sdpCandidateTF(),
              sdpCandidateButtons(),
            ],
          ),
        ));
  }
}
