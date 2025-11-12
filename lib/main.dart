import 'dart:collection';
import 'package:ericsson/camacc.dart';
import 'package:ericsson/home.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  final firstCamera = cameras.first;

  runApp(
    MainApp(
      camera: firstCamera,
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

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController empIdController = TextEditingController();
  final TextEditingController supervisorController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    empIdController.dispose();
    supervisorController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    final fullName = fullNameController.text.trim();
    final employeeId = empIdController.text.trim();
    final supervisorId = supervisorController.text.trim();
    final role = selectedRole.label;
    final remember = rememberMe;

    if (fullName.isEmpty || employeeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and employee ID')),
      );
      return;
    }

    final payload = {
      'fullName': fullName,
      'employeeId': employeeId,
      'supervisorId': supervisorId,
      'role': role,
      'remember': remember,
    };

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('https://safemine-backend.netlify.app/api/');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // success - proceed to app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Menu()),
          (route) => false,
        );
      } else {
        final msg = resp.body.isNotEmpty ? resp.body : 'Server error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $msg')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 12),
                  child: Image(
                    image: AssetImage('assets/images/helmet_ic.png'),
                    color: null,
                    width: 80,
                    height: 80,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Helmet Camera',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Sign in to access your safety monitoring system',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
                // main form
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  child: LayoutBuilder(
                    builder: (context, innerConstraints) {
                      double fieldWidth = innerConstraints.maxWidth;
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: fieldWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color.fromARGB(
                                          74, 199, 210, 255), // Shadow color
                                      blurRadius: 4,
                                      offset: Offset(0, 4)),
                                ],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField( // removed const and added controller
                                controller: fullNameController,
                                decoration: const InputDecoration(
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
                          const SizedBox(height: 28),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Employee ID',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: fieldWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color.fromARGB(
                                          74, 199, 210, 255),
                                      blurRadius: 4,
                                      offset: Offset(0, 4)),
                                ],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField( // removed const and added controller
                                controller: empIdController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide.none),
                                  fillColor: Color.fromARGB(255, 243, 244, 246),
                                  filled: true,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                  hintText:
                                      'Enter your employee ID',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: fieldWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color.fromARGB(
                                          74, 199, 210, 255),
                                      blurRadius: 4,
                                      offset: Offset(0, 4)),
                                ],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField( // removed const and added controller
                                controller: supervisorController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide.none),
                                  fillColor: Color.fromARGB(255, 243, 244, 246),
                                  filled: true,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                  hintText:
                                      'Enter Supervisor ID',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Role',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: fieldWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(74, 199, 210, 255),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownMenu<RoleLabel>(
                                width: fieldWidth,
                                dropdownMenuEntries:
                                    RoleLabel.entries.map((role) {
                                  return DropdownMenuEntry<RoleLabel>(
                                    value: role.value,
                                    label: role.label,
                                    style: ButtonStyle(
                                      minimumSize: MaterialStatePropertyAll(
                                          Size(fieldWidth, 40)),
                                    ),
                                  );
                                }).toList(),
                                menuStyle: const MenuStyle(
                                  backgroundColor:
                                      MaterialStatePropertyAll(Colors.white),
                                  surfaceTintColor:
                                      MaterialStatePropertyAll(Colors.white),
                                  padding:
                                      MaterialStatePropertyAll(EdgeInsets.zero),
                                  elevation: MaterialStatePropertyAll(2),
                                  shadowColor: MaterialStatePropertyAll(
                                      Color.fromARGB(74, 199, 210, 255)),
                                ),
                                initialSelection: selectedRole,
                                onSelected: (RoleLabel? value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedRole = value;
                                    });
                                  }
                                },
                                inputDecorationTheme:
                                    const InputDecorationTheme(
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide.none),
                                  fillColor:
                                      Color.fromARGB(255, 243, 244, 246),
                                  filled: true,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: Transform.scale(
                                  scale: 1.5,
                                  child: Checkbox(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    value: rememberMe,
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
                          const SizedBox(height: 28),
                          SizedBox(
                            width: fieldWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color.fromARGB(74, 199, 210, 255),
                                      blurRadius: 4,
                                      offset: Offset(0, 4)),
                                ],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : () async {
                                  // keep camera permission check, then call backend submit
                                  var status = await Permission.camera.status;
                                  if (!mounted) return;
                                  if (status.isDenied) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) => const CamAcc()),
                                    );
                                    return;
                                  }
                                  // permission granted -> submit to backend
                                  await _submitSignIn();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Sign In',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20), // small bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}
