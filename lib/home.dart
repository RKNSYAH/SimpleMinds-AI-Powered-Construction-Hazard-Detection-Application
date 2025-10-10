import 'package:camera/camera.dart';
import 'package:ericsson/theme.dart';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:intl/intl.dart';

class IncidentList extends StatelessWidget {
  final String warnName;
  final int timeStamp;

  const IncidentList({Key? key, required this.warnName, required this.timeStamp})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert timestamp to DateTime
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
    // Format date and time
    final formatted = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 243, 244, 246),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(74, 199, 210, 255),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(warnName),
                  Text(formatted), // Show formatted date and time
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
        );
        _initializeControllerFuture = _controller!.initialize();
        setState(() {});
      }
    } catch (e) {
      // Handle camera error
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 243, 244, 246),
        body: Padding(
          padding: const EdgeInsets.only(top: 65),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    double targetWidth = constraints.maxWidth;
                    double targetHeight = 60.0;
                    return Column(
                      children: [
                        Container(
                          width: targetWidth,
                          height: targetHeight,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromARGB(74, 199, 210, 255),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Image(
                                  image:
                                      AssetImage('assets/images/camera_ic.png'),
                                  color: null,
                                  width: 35,
                                  height: 35,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '1234',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Tunnel A - Level B',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: targetWidth / 2.5,
                              height: targetHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(74, 199, 210, 255),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image(
                                          image: AssetImage(
                                              'assets/images/vcam_ic.png'),
                                          width: 16,
                                          height: 16,
                                        ),
                                        SizedBox(height: 4),
                                        Image(
                                          image: AssetImage(
                                              'assets/images/green_circ.png'),
                                          width: 14,
                                          height: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Camera',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        'Connected',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: targetWidth / 2.5,
                              height: targetHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(74, 199, 210, 255),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: Icon(Icons
                                          .battery_charging_full_outlined)),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Battery',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      FutureBuilder<int>(
                                        future: Battery().batteryLevel,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Text(
                                              'Loading...',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            );
                                          } else if (snapshot.hasError) {
                                            return Text(
                                              'Error',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            );
                                          } else {
                                            return Text(
                                              '${snapshot.data}%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Container(
                            width: targetWidth - 20,
                            height: 280,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(74, 199, 210, 255),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16.0, top: 16.0, bottom: 16.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Live Camera Feed',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          Text(
                                            'Real-Time View',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 16.0, top: 16.0, bottom: 16.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'LIVE',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: Center(
                                      child: (_controller != null &&
                                              _initializeControllerFuture !=
                                                  null)
                                          ? FutureBuilder<void>(
                                              future:
                                                  _initializeControllerFuture,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.done) {
                                                  return AspectRatio(
                                                    aspectRatio: _controller!
                                                        .value.aspectRatio,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              13),
                                                      child: CameraPreview(
                                                          _controller!),
                                                    ),
                                                  );
                                                } else {
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                }
                                              },
                                            )
                                          : Center(
                                              child: Text(
                                                'Camera not available',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                        const SizedBox(height: 25),
                        Container(
                            width: targetWidth - 20,
                            height: 280,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(74, 199, 210, 255),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16.0, top: 16.0, bottom: 16.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Recent Alerts',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        Text(
                                          'Latest Safety Incidents Detected',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        right: 16.0, top: 16.0, bottom: 16.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              minimumSize: const Size(50, 18),
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 243, 244, 246),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            onPressed: () {
                                              // TODO: Add your navigation or action here
                                            },
                                            child: Text(
                                              'View All',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Column(children: [
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Column(
                                    children: [
                                      IncidentList(
                                          warnName: 'Corrosion Detected ',
                                          timeStamp: 1760033682),
                                      SizedBox(height: 10),
                                      IncidentList(
                                          warnName:
                                              'Crack (Wall) Detected ',
                                          timeStamp: 1760023682),
                                      SizedBox(height: 10),
                                      IncidentList(
                                          warnName: 'Crack (Floor) Detected ',
                                          timeStamp: 1760011682),
                                    ],
                                  ),
                                )
                              ])
                            ])),
                      ],
                    );
                  },
                )
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
            elevation: 0,
            backgroundColor: const Color.fromARGB(255, 243, 244, 246),
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                label: 'Menu',
              ),
            ],
            onTap: (value) => {if (value == 0) {}}),
      ),
    );
  }
}
