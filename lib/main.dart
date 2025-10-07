import 'dart:collection';
import 'package:ericsson/camacc.dart';

import 'home.dart';
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
  engineer('Engineer'),
  supervisor('Supervisor'),
  safetyOfficer('Safety Officer');

  const RoleLabel(this.label);
  final String label;

  static List<RoleEntry> get entries => UnmodifiableListView<RoleEntry>(
        values.map<RoleEntry>(
          (RoleLabel role) => RoleEntry(
            value: role,
            label: role.label,
          ),
        ),
      );
}

class MainApp extends StatefulWidget {
  final CameraDescription camera;
  const MainApp({super.key, required this.camera});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  RoleLabel selectedRole = RoleLabel.engineer;
  bool rememberMe = false;

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
                        const SizedBox(height: 20),
                        SizedBox(
                          width: fieldWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: const [
                                BoxShadow(
                                    color: Color.fromARGB(
                                        74, 199, 210, 255), // Shadow color
                                    blurRadius: 4, // Softness of the shadow
                                    offset:
                                        Offset(0, 4) // Position of the shadow
                                    ),
                              ],
                              borderRadius: BorderRadius.circular(
                                  10), // Match your input border
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                fillColor: Color.fromARGB(255, 243, 244, 246),
                                filled: true,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                hintText: 'Enter your full name',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 45),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Phone Number / Employee ID',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: fieldWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: const [
                                BoxShadow(
                                    color: Color.fromARGB(
                                        74, 199, 210, 255), // Shadow color
                                    blurRadius: 4, // Softness of the shadow
                                    offset:
                                        Offset(0, 4) // Position of the shadow
                                    ),
                              ],
                              borderRadius: BorderRadius.circular(
                                  10), // Match your input border
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                fillColor: Color.fromARGB(255, 243, 244, 246),
                                filled: true,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                hintText:
                                    'Enter your phone number or employee ID',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 45),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Role',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: fieldWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(74, 199, 210, 255), // Shadow color
                                  blurRadius: 4, // Softness of the shadow
                                  offset: Offset(0, 4), // Position of the shadow
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10), // Match your input border
                            ),
                            child: DropdownMenu<RoleLabel>(
                              width: fieldWidth,
                              dropdownMenuEntries:
                                  RoleLabel.entries.map((role) {
                                return DropdownMenuEntry<RoleLabel>(
                                  value: role.value,
                                  label: role.label,
                                  style: ButtonStyle(
                                    minimumSize: WidgetStatePropertyAll(Size(fieldWidth, 40)),
                                  ),
                                );
                              }).toList(),
                              menuStyle: const MenuStyle(
                                backgroundColor: WidgetStatePropertyAll(Colors.white),
                                surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                elevation: WidgetStatePropertyAll(2),
                                shadowColor: WidgetStatePropertyAll(Color.fromARGB(74, 199, 210, 255)),
                              ),
                              initialSelection: selectedRole,
                              onSelected: (RoleLabel? value) {
                                if (value != null) {
                                  setState(() {
                                    selectedRole = value;
                                  });
                                }
                              },
                              inputDecorationTheme: const InputDecorationTheme(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                fillColor: Color.fromARGB(255, 243, 244, 246),
                                filled: true,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Transform.translate(
                              offset: const Offset(-10, 0),
                              child: Transform.scale(
                                scale: 1.5,
                                child: Checkbox(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  value: rememberMe, // Use the state variable
                                  onChanged: (value) {
                                    setState(() {
                                      rememberMe = value!;
                                    });
                                  },
                                  activeColor:
                                      const Color.fromARGB(255, 11, 11, 11),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  rememberMe = !rememberMe;
                                });
                              },
                              child: const Text(
                              'Remember me for quick login',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: fieldWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: const [
                                BoxShadow(
                                    color: Color.fromARGB( 74, 199, 210, 255), // Shadow color
                                    blurRadius: 4, // Softness of the shadow
                                    offset: Offset(0, 4) // Position of the shadow
                                    ),
                              ],
                              borderRadius: BorderRadius.circular(
                                  5), // Match your button border
                            ),
                            child: ElevatedButton(
                            onPressed: () {
                              // When the user taps the button, navigate to the TakePictureScreen.
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CamAcc()
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
    scaffoldBackgroundColor: Colors.white,
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
    shadowColor: const Color.fromARGB(74, 199, 210, 255),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(
        color: Color.fromARGB(255, 190, 190, 190),
      ),
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
