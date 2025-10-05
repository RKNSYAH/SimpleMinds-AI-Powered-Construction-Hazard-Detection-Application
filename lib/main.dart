import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      home: MainApp(
        // Pass the appropriate camera to the MainApp widget.
        camera: firstCamera,
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  final CameraDescription camera;
  const MainApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _buildTheme(),
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 90, bottom: 20),
                child: Image(
                  image: AssetImage('assets/images/helmet_ic.png'),
                  color: null,
                  width: 80,
                  height: 80,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 0, bottom: 20),
                child: Text(
                  'Helmet Camera',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 0, bottom: 20),
                child: Text(
                  'Sign in to access your safety monitoring system',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        fillColor: Color.fromARGB(255, 238, 238, 238),
                        filled: true,
                        labelText: 'Enter your full name',
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 45,
                width: 350,
                child: ElevatedButton(
                  onPressed: () {
                    // When the user taps the button, navigate to the TakePictureScreen.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TakePictureScreen(
                          camera: camera,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  child: const Text('Sign In',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

ThemeData _buildTheme() {
  final baseTheme = ThemeData.light();
  return baseTheme.copyWith(
    textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: const Color.fromARGB(255, 37, 99, 235),
      secondary: const Color.fromARGB(255, 37, 99, 235),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color.fromARGB(255, 37, 99, 235),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 37, 99, 235),
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 37, 99, 235),
        ),
      ),
      labelStyle: const TextStyle(
        color: Color.fromARGB(255, 37, 99, 235),
      ),
    ),
  );
}
