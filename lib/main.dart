import 'dart:collection';

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

typedef RoleEntry = DropdownMenuEntry<RoleLabel>;

// DropdownMenuEntry labels and values for the first dropdown menu.
enum RoleLabel {
  blue('Engineer'),
  pink('Supervisor'),
  grey('Safety Officer');

  const RoleLabel(this.label);
  final String label;

  static final List<RoleEntry> entries = UnmodifiableListView<RoleEntry>(
    values.map<RoleEntry>(
      (RoleLabel color) => RoleEntry(
        value: color,
        label: color.label,
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
              Padding(
                padding: const EdgeInsets.all(25),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double fieldWidth = constraints.maxWidth;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Full Name',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: const TextField(
                            decoration: InputDecoration(
                              fillColor: Color.fromARGB(255, 238, 238, 238),
                              filled: true,
                              labelText: 'Enter your full name',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Phone Number / Employee ID',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: const TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Enter your phone number or employee ID',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Role',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownMenu(
                            dropdownMenuEntries: RoleLabel.entries,
                            width: fieldWidth,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: fieldWidth,
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
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
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
