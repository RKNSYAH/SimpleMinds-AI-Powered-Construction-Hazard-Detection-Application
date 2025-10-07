import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CamAcc extends StatelessWidget {
  const CamAcc({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
        theme: _buildTheme(),
        home: Scaffold(
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 0, bottom: 20),
                  child: Image(
                    image: AssetImage('assets/images/helmet_ic.png'),
                    color: null,
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 30,),
                const Text('Allow Camera Access'),
                const SizedBox(height: 20,),
                const SizedBox(
                  width: 370, // or use MediaQuery for dynamic width
                  child: Text(
                    "This app requires your camera access to stream live video.",
                    softWrap: true,
                    textAlign: TextAlign.center, // optional: centers the text
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 40,),
                LayoutBuilder(builder: (context, constraints) {
                  double fieldWidth = constraints.maxWidth * 0.6;
                  if (fieldWidth > 400) {
                    fieldWidth = 400; // Cap the width at 400 pixels
                  }
                  return Column(
                    children: [
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
                            child: const Text('Allow Access',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        )
                      ),
                      const SizedBox(height: 20,),
                    ],
                  );
                })
                
              ]
          ),
        )   
      )
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
