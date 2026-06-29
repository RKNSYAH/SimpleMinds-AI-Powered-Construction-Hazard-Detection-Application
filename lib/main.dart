import 'dart:collection';
import 'package:ericsson/app_config.dart';
import 'package:ericsson/camacc.dart';
import 'package:ericsson/home.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const secureStorage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MainApp(),
  );
}



class MainApp extends StatefulWidget {
  const MainApp({super.key,});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

    @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      _callLogoutApi();
    }
  }

  Future<void> _callLogoutApi() async {
    try {
      if (!await AppConfig.isBackendEnabled()) {
        return;
      }

      final token = await secureStorage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) return;

      final payload = _parseJwtPayload(token);
      final workerId = (payload['workerID'] ?? '').toString();

      final uri = Uri.parse('https://zonal-presence-production.up.railway.app/worker/logout');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'workerID': workerId})
      );

      await secureStorage.delete(key: 'jwt_token');
    } catch (e) {
      debugPrint('Logout failed: $e');
    }
  }


  // parse JWT payload
  Map<String, dynamic> _parseJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return json.decode(payload) as Map<String, dynamic>;
  }

  // try to validate/refresh using workerID from saved JWT
  Future<Widget> _buildHome() async {
    try {
      if (!await AppConfig.isBackendEnabled()) {
        return LoginScreen();
      }

      final token = await secureStorage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) return LoginScreen();

      final payload = _parseJwtPayload(token);
      final workerId = (payload['workerID'] ?? '').toString();
      final rememberMe = (payload['remember'] ?? '').toString();

      if (workerId.isEmpty) return LoginScreen();
      if (!rememberMe.toLowerCase().contains('true')) {
        return LoginScreen();
      }

      final uri = Uri.parse('safemine-backend-production-24aa.up.railway.app/worker/login');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'workerID': workerId, 'remember': true}),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final responseData = jsonDecode(resp.body);
        final newJwt = responseData['token'] ?? responseData['jwt'] ?? '';
        if (newJwt != null && newJwt.isNotEmpty) {
          await secureStorage.write(key: 'jwt_token', value: newJwt);
        }
        return const Menu();
      } else {
        return LoginScreen();
      }
    } catch (_) {
      return LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: FutureBuilder<Widget>(
        future: _buildHome(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data ?? LoginScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool _useBackend = false;
  final TextEditingController empIdController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBackendMode();
  }

  Future<void> _loadBackendMode() async {
    final enabled = await AppConfig.isBackendEnabled();
    if (!mounted) return;
    setState(() {
      _useBackend = enabled;
    });
  }

  Future<void> _setBackendMode(bool enabled) async {
    setState(() {
      _useBackend = enabled;
    });
    await AppConfig.setBackendEnabled(enabled);
  }

  @override
  void dispose() {
    empIdController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    final employeeId = empIdController.text.trim();
    final remember = rememberMe;

    if (_useBackend && employeeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your employee ID')),
      );
      return;
    }

    if (!_useBackend) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Menu()),
        (route) => false,
      );
      return;
    }

    final payload = {
      'workerID': employeeId,
      'remember': remember,
    };

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('https://zonal-presence-production.up.railway.app/worker/login');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // parse response to extract JWT
        final responseData = jsonDecode(resp.body);
        final jwt = responseData['token'];

        if (jwt.isNotEmpty) {
          await secureStorage.write(key: 'jwt_token', value: jwt);
        }

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
    return ScaffoldMessenger(
      child: Scaffold(
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
                if (AppConfig.allowsBackendBypass)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Backend sync',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _useBackend
                            ? 'Use the API for login, logout, and uploads.'
                            : 'Bypass backend calls and stay fully local.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _useBackend,
                      onChanged: _setBackendMode,
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
                              child: TextField(
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
                                    : Text(
                                        _useBackend
                                            ? 'Sign In'
                                            : 'Continue Offline',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
