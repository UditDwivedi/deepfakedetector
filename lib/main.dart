import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deepfake Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DeepfakeDetector(),
    );
  }
}

class DeepfakeDetector extends StatefulWidget {
  @override
  _DeepfakeDetectorState createState() => _DeepfakeDetectorState();
}

class _DeepfakeDetectorState extends State<DeepfakeDetector> {
  File? _videoFile;
  String _result = '';
  bool _isLoading = false;
  VideoPlayerController? _controller;
  String _confidenceLabel = '';
  String _resultLabel = '';

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      // The permission is granted, you can proceed with accessing storage
    } else {
      // The permission is denied, you can handle the denial here
      // For example, you might want to show a dialog to the user
    }
  }

  Future<void> _pickVideo() async {
    setState(() {
      _result = "";
    });
    await requestStoragePermission();
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _controller = VideoPlayerController.file(_videoFile!)
          ..initialize().then((_) {
            setState(() {}); // Ensure the first frame is shown.
          });
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.179.169:3000/api'));
      request.files
          .add(await http.MultipartFile.fromPath('video', _videoFile!.path));
      var res = await request.send();

      if (res.statusCode == 200) {
        var responseData = await res.stream.bytesToString();
        var result = jsonDecode(responseData);

        setState(() {
          _result =
              'Video is: ${result['output']} (Confidence: ${result['confidence']}%)';
          _isLoading = false;
          _resultLabel = result['output'];
          _confidenceLabel = result['confidence'].toString();
          print(_resultLabel);
          print(_confidenceLabel);
        });
      } else {
        throw Exception('Failed to get result. Status code: ${res.statusCode}');
      }
    } catch (e) {
      setState(() {
        // _result = 'Failed to get result. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade100,
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Deepfake Detector',
              style: TextStyle(fontSize: 20, color: Colors.red.shade300),
            ),
            SizedBox(height: 2),
            Text(
              'designed_by_Sinister 6',
              style: TextStyle(fontSize: 12, color: Colors.red.shade300),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: (_isLoading == false)
            ? Column(
                children: [
                  Spacer(),
                  (_videoFile == null)
                      ? Center(
                          child: InkWell(
                            onTap: _pickVideo,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(12)),
                              height: MediaQuery.of(context).size.height / 4.5,
                              width: MediaQuery.of(context).size.width / 2.5,
                              padding: EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.video_call_outlined,
                                    size: 100,
                                    color: Colors.purple.shade300,
                                  ),
                                  Text(
                                    "Pick Video",
                                    style: TextStyle(
                                        color: Colors.purple.shade300,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      : _controller != null && _controller!.value.isInitialized
                          ? Center(
                              child: Column(
                                children: [
                                  Container(
                                    height:
                                        MediaQuery.sizeOf(context).height / 2,
                                    width: MediaQuery.sizeOf(context).width / 2,
                                    child: AspectRatio(
                                      aspectRatio:
                                          _controller!.value.aspectRatio,
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: VideoPlayer(_controller!)),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        style: ButtonStyle(
                                            elevation:
                                                WidgetStatePropertyAll(0),
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.blue.shade50)),
                                        onPressed: _uploadVideo,
                                        child: Icon(
                                          Icons.search,
                                          color: Colors.blue.shade300,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      ElevatedButton(
                                        style: ButtonStyle(
                                            elevation:
                                                WidgetStatePropertyAll(0),
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    Colors.blue.shade50)),
                                        onPressed: () {
                                          setState(() {
                                            _controller!.value.isPlaying
                                                ? _controller!.pause()
                                                : _controller!.play();
                                          });
                                        },
                                        child: Icon(
                                          color: Colors.blue.shade400,
                                          _controller!.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      ElevatedButton(
                                          style: ButtonStyle(
                                              elevation:
                                                  WidgetStatePropertyAll(0),
                                              backgroundColor:
                                                  WidgetStatePropertyAll(
                                                      Colors.blue.shade50)),
                                          onPressed: _pickVideo,
                                          child: Icon(
                                            Icons.replay,
                                            color: Colors.blue.shade300,
                                          )),
                                    ],
                                  )
                                ],
                              ),
                            )
                          : Center(child: CircularProgressIndicator()),
                  (_result.isNotEmpty)
                      ? Column(
                          children: [
                            Text(
                              _resultLabel,
                              style: TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: (_resultLabel == 'REAL')
                                      ? Colors.green.shade300
                                      : Colors.red.shade300),
                            ),
                            Text(
                              "${double.parse(_confidenceLabel).toStringAsFixed(2)}% confident",
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: (_resultLabel == 'REAL')
                                      ? Colors.green.shade300
                                      : Colors.red.shade300),
                            ),
                          ],
                        )
                      : Container(),
                  Spacer()
                ],
              )
            : Center(
                child: CircularProgressIndicator(
                  color: Colors.red.shade300,
                ),
              ),
      ),
    );
  }
}
