import 'package:ericsson/home.dart';
import 'package:ericsson/theme.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CamAcc extends StatelessWidget {
  const CamAcc({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
        theme: buildTheme(),
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
                  width: 370, 
                  child: Text(
                    "This app requires your camera access to stream live video.",
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 40,),
                LayoutBuilder(builder: (context, constraints) {
                  double fieldWidth = constraints.maxWidth * 0.6;
                  if (fieldWidth > 400) {
                    fieldWidth = 400; 
                  }
                  return Column(
                    children: [
                      SizedBox(
                          width: fieldWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: const [
                                BoxShadow(
                                    color: Color.fromARGB( 74, 199, 210, 255),
                                    blurRadius: 4,
                                    offset: Offset(0, 4) 
                                    ),
                              ],
                              borderRadius: BorderRadius.circular(
                                  5), 
                            ),
                            child: ElevatedButton(
                            onPressed: () async {
                              if (await Permission.camera.request().isGranted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const Menu()
                                  ),
                                );
                              }
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
