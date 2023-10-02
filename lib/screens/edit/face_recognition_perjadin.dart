import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imp_approval/data/data.dart';
import 'package:imp_approval/layout/mainlayout.dart';
import 'package:imp_approval/screens/home.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';
import 'package:imp_approval/faceModule/model.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:imp_approval/screens/standup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quiver/collection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:imp_approval/faceModule/detector.dart';
import '/faceModule/utils.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:ntp/ntp.dart';

class FacePagePerjadin extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const FacePagePerjadin({Key? key, required this.arguments}) : super(key: key);

  @override
  State<FacePagePerjadin> createState() => _FacePagePerjadinState();
}

class _FacePagePerjadinState extends State<FacePagePerjadin>
    with WidgetsBindingObserver {
  List<int>? imageBytes;
  List<dynamic>? userFP;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    initializePage();
  }

  Future<void> initializePage() async {
    try {
      await getUserData();
      await fetchName();
      await fetchId();
      print('file guach : ${widget.arguments['file'].toString()}');
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _updateLocationAndAddress();
      });
      await _updateLocationAndAddress();
      _start(); // then start the camera
    } catch (e) {
      print("Error in initializePage: $e");
    }
  }

  SharedPreferences? preferences;

  Future<void> fetchName() async {
    nama_lengkap = preferences?.getString('nama_lengkap') ?? 'Mahesa';
    print(nama_lengkap);
    setState(() {});
  }

  Future<void> fetchId() async {
    user_id = preferences?.getInt('user_id') ?? 2;
    print(user_id);
    setState(() {});
  }

  Future<DateTime> getNtpTime() async {
    DateTime ntpDateTime = await NTP.now();
    return ntpDateTime;
  }

  Future<void> _updateLocationAndAddress() async {
    _position = await _getCurrentLocation();
    if (_position != null) {
      await _getAddressCoordinates();
      print("Latitude: ${_position!.latitude}");
      print("Longitude: ${_position!.longitude}");
      print("Address: $_currentAddress");
    }
  }

  Future<Position> _getCurrentLocation() async {
    servicePermission = await Geolocator.isLocationServiceEnabled();
    if (!servicePermission) {
      print('Service disabled');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getAddressCoordinates() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _position!.latitude, _position!.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _currentAddress =
            "${place.street},${place.postalCode},${place.locality},${place.subLocality},${place.administrativeArea},${place.subAdministrativeArea}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  bool isLoading = false;
  Future<void> getUserData() async {
    setState(() {
      isLoading = true;
    });
    preferences = await SharedPreferences.getInstance();
    setState(() {
      isLoading = false;
    });
  }

  void _start() async {
    interpreter = await loadModel();
    initialCamera();
  }

  @override
  void dispose() async {
    WidgetsBinding.instance!.removeObserver(this);
    if (_camera != null && _camera!.value.isInitialized) {
      await _camera!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 400));
      await _camera!.dispose();
      await Future.delayed(const Duration(milliseconds: 400));
      _camera = null;
      _timer?.cancel();
      recognitionTimer?.cancel();
    }
    super.dispose();
  }

  late File jsonFile;
  var interpreter;
  CameraController? _camera;
  dynamic data = {};
  bool _isDetecting = false;
  double threshold = 1.0;
  dynamic _scanResults;
  String _predRes = '';
  bool isStream = true;
  CameraImage? _cameraimage;
  Directory? tempDir;
  bool _faceFound = false;
  bool _verify = false;
  List? e1;
  bool loading = true;
  late String nama_lengkap;
  late String face;
  late int user_id;

  bool faceRecognized = false;

  Position? _position;
  late bool servicePermission = false;
  late LocationPermission permission;
  String _currentAddress = "";
  late Timer _timer;

  final TextEditingController _name = TextEditingController(text: '');

  Future<void> fetchData() async {
    Map<String, dynamic> userData = await fetchUserFacePoint();
    data = userData['facePoint'];
    nama_lengkap = userData['name'];
  }

  Future<Map<String, dynamic>> fetchUserFacePoint() async {
    final response = await http.get(
      Uri.parse(
          'https://testing.impstudio.id/approvall/api/fetchPoint?id=$user_id'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load face point.');
    }
  }

  Timer? recognitionTimer;

  void onFaceDetected(String recognizedName) {
    if (recognizedName.isNotEmpty) {
      if (recognitionTimer == null) {
        faceRecognized = true;
        recognitionTimer = Timer(const Duration(seconds: 5), () async {
          if (faceRecognized) {
            storeAbsen();
            if (_camera != null) {
              await _camera!.stopImageStream();
              await Future.delayed(const Duration(milliseconds: 400));
              await _camera!.dispose();
              await Future.delayed(const Duration(milliseconds: 400));
              _camera = null;
              _timer.cancel();
            }
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => MainLayout()),
              );
            }
          }
          recognitionTimer = null;
        });
      }
    } else {
      faceRecognized = false;
      recognitionTimer?.cancel();
      recognitionTimer = null;
    }
  }

  void initialCamera() async {
    CameraDescription description =
        await getCamera(CameraLensDirection.front); //camera depan;

    _camera = CameraController(
      description,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _camera!.initialize();
    await Future.delayed(const Duration(milliseconds: 500));
    loading = false;
    tempDir = await getApplicationDocumentsDirectory();
    String _embPath = tempDir!.path + '/emb.json';
    jsonFile = File(_embPath);
    if (jsonFile.existsSync()) {
      data = json.decode(jsonFile.readAsStringSync());
    }

    await Future.delayed(const Duration(milliseconds: 500));

    _camera!.startImageStream((CameraImage image) async {
      if (_camera != null) {
        if (_isDetecting) return;
        _isDetecting = true;
        dynamic finalResult = Multimap<String, Face>();

        detect(image, getDetectionMethod()).then((dynamic result) async {
          if (result.length == 0 || result == null) {
            _faceFound = false;
            _predRes = 'Tidak dikenali';
          } else {
            _faceFound = true;
          }

          String res;
          Face _face;

          imglib.Image convertedImage =
              convertCameraImage(image, CameraLensDirection.front);

          for (_face in result) {
            double x, y, w, h;
            x = (_face.boundingBox.left - 10);
            y = (_face.boundingBox.top - 10);
            w = (_face.boundingBox.width + 10);
            h = (_face.boundingBox.height + 10);
            imglib.Image croppedImage = imglib.copyCrop(
                convertedImage, x.round(), y.round(), w.round(), h.round());
            croppedImage = imglib.copyResizeCropSquare(croppedImage, 112);
            res = recog(croppedImage);
            finalResult.add(res, _face);

            if (_faceFound) {
              String recognizedName = recog(croppedImage);
              if (recognizedName != "TIDAK DIKENALI") {
                // Assuming it returns the name in upper case
                onFaceDetected(recognizedName); // Pass the recognized name
              } else {
                if (recognitionTimer != null) {
                  recognitionTimer?.cancel();
                  recognitionTimer = null;
                }
              }
            }
          }

          _scanResults = finalResult;
          _isDetecting = false;
          setState(() {});
        }).catchError(
          (_) async {
            print({'error': _.toString()});
            _isDetecting = false;
            if (_camera != null) {
              await _camera!.stopImageStream();
              await Future.delayed(const Duration(milliseconds: 400));
              await _camera!.dispose();
              await Future.delayed(const Duration(milliseconds: 400));
              _camera = null;
              _timer.cancel();
            }
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MainLayout()),
            );
          },
        );
      }
    });
  }

  String recog(imglib.Image img) {
    List input = imageToByteListFloat32(img, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);
    List output = List.filled(1 * 192, null, growable: false).reshape([1, 192]);
    interpreter.run(input, output);
    output = output.reshape([192]);
    e1 = List.from(output);
    // Convert the imglib image to bytes
    List<int> bytes = Uint8List.fromList(img.getBytes());

    this.imageBytes = bytes;
    return compare(e1!).toUpperCase();
  }

  String compare(List currEmb) {
    //mengembalikan nama pemilik akun
    double minDist = 999;
    double currDist = 0.0;
    _predRes = "Tidak dikenali";
    for (String label in data.keys) {
      currDist = euclideanDistance(data[label], currEmb);
      if (currDist <= threshold && currDist < minDist) {
        minDist = currDist;
        _predRes = label;
        if (_verify == false) {
          _verify = true;
        }
      }
    }
    return _predRes;
  }

  // FUNCTION STORE

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  String formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat('hh:mm'); //"6:00"
    return format.format(dt);
  }

  Future storeAbsen() async {
    DateTime combinedDateTime =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    String jsonData = json.encode(data);
    DateTime currentTime = await getNtpTime();
    String date = currentTime.toIso8601String();

    var uri =
        Uri.parse('https://testing.impstudio.id/approvall/api/presence/store');
    var request = http.MultipartRequest('POST', uri);

    Map<String, String> fields = {
      "user_id": user_id.toString(),
      "category": widget.arguments['category'].toString(),
      "exit_time": '00:00:00',
      "latitude": _position!.latitude.toString(),
      "longitude": _position!.longitude.toString(),
      "date": date,
      "face_point": jsonData ?? 'sawarasenaii',
      "status": 'pending',
    };

    request.fields.addAll(fields);

    // Conditional fields based on category
    switch (widget.arguments['category']) {
      case 'telework':
        request.fields.addAll({
          "telework_category": widget.arguments['keteranganWfa'].toString(),
          "category_description": widget.arguments['description'].toString(),
        });
        break;
      case 'work_trip':
        request.fields.addAll({
          "start_date":
              DateFormat('yyyy-MM-dd').format(widget.arguments['start_date']),
          "end_date":
              DateFormat('yyyy-MM-dd').format(widget.arguments['end_date']),
          "entry_date":
              DateFormat('yyyy-MM-dd').format(widget.arguments['entry_date']),
        });

        // Check if the 'file' argument contains a valid file path.
        if (widget.arguments.containsKey('file')) {
          String filePath = widget.arguments['file'].toString();
          request.files.add(await http.MultipartFile.fromPath(
              'file', // This 'file' should match the key on the server
              filePath));
        }

        break;
      default:
        break;
    }

    var response = await request.send();

    // Handling the response from the server
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      print(responseData);
      return json.decode(responseData);
    } else {
      print('Error occurred. Code: ${response.statusCode}.');
      throw Exception('Failed to store data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    var profile = widget.arguments['profile'];
    var selectedOption = widget.arguments['selectedOption'];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white, // Menghilangkan background color
        leading: IconButton(
          color: Colors.black,
          onPressed: () async {
            if (_camera != null) {
              await _camera!.stopImageStream();
              await Future.delayed(const Duration(milliseconds: 400));
              await _camera!.dispose();
              await Future.delayed(const Duration(milliseconds: 400));
              _camera = null;
              _timer.cancel();
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => new MainLayout()));
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'Verify your face',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.width * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Builder(builder: (context) {
        if ((_camera == null || !_camera!.value.isInitialized) || loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final double customAspectRatio =
            3 / 3; // Change this to your desired aspect ratio
        final double circleSize = 250.0;

        return Center(
          child: Container(
            constraints: const BoxConstraints.expand(),
            padding: const EdgeInsets.only(
              top: 0,
            ),
            child: _camera == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Container(
                        color: Colors.white, // Red background color
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Text at the top
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              'Verify to back to work',
                              style: GoogleFonts.poppins(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.05,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ClipOval(
                            child: Container(
                              width: circleSize,
                              height: circleSize,
                              child: AspectRatio(
                                aspectRatio: customAspectRatio,
                                child: CameraPreview(_camera!),
                              ),
                            ),
                          ),
                          // Text at the bottom
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 30),
                            child: Text(
                              'Lets Chek In, ${preferences?.getString('nama_lengkap').toString()}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.035,
                                color: blueText,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, top: 10),
                            child: Text(
                              'Make sure your head is in the circle while we scan your face.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.04,
                                color: const Color.fromRGBO(182, 182, 182, 1),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildResults(),
                    ],
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildResults() {
    Center noResultsText = const Center(
        child: Text('Mohon Tunggu ..',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white)));
    if (_scanResults == null ||
        _camera == null ||
        !_camera!.value.isInitialized) {
      return noResultsText;
    }
    CustomPainter painter;

    final Size imageSize = Size(
      _camera!.value.previewSize!.height,
      _camera!.value.previewSize!.width,
    );
    painter = FaceDetectorPainter(imageSize, _scanResults);
    return CustomPaint(
      painter: painter,
    );
  }
}
