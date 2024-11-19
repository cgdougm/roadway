import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:provider/provider.dart';
import 'package:roadway/app_state.dart';
import 'package:roadway/core/db.dart';
import 'package:roadway/core/theme.dart';
import 'package:roadway/app_actions.dart';
import 'package:roadway/component/filebrowser.dart';

// toggle diagnostic view
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database; // warm up DB, cache

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(
            create: (context) => ThemeProvider(isDarkMode: true)),
      ],
      child: const MyApp(),
    ),
  );

  doWhenWindowReady(() {
    // BitsDojo Window Settings
    const initialSize = Size(1280, 720);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Roadway',
          theme: themeProvider.themeData,
          home: const AppPage(title: 'roadway'),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AppPage extends StatefulWidget {
  const AppPage({super.key, required this.title});

  final String title;

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String windowTitle = widget.title;
    return Scaffold(
      drawer: const Drawer(
        width: 400,
        shadowColor: Colors.black,
        elevation: 10,
        child: FileBrowser(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 42, 36, 48),
                Color.fromARGB(255, 87, 115, 121)
              ],
              stops: [
                0.1,
                1.0
              ]),
        ),
        child: Column(children: [
          WindowTitleBarBox(
            child: Container(
              color: const Color.fromARGB(30, 0, 0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: MoveWindow(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(3, 0, 3, 2),
                        child: Row(children: [
                          MenuAnchor(
                            builder: (context, controller, child) {
                              return IconButton(
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: Color.fromARGB(180, 157, 140, 217),
                                  size: 18,
                                ),
                                onPressed: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                },
                              );
                            },
                            menuChildren: [
                              MenuItemButton(
                                child: const Text('New file browser...'),
                                onPressed: () {
                                  createNewFileBrowser(context);
                                },
                              ),
                            ],
                          ),
                          Baseline(
                            baseline: 22,
                            baselineType: TextBaseline.alphabetic,
                            child: Text(windowTitle,
                                style: const TextStyle(
                                    fontFamily: 'HeptaSlab',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color.fromARGB(180, 157, 140, 217),
                                    letterSpacing: -1)),
                          ),
                          const Spacer(),
                          const IconButton(
                            icon: Icon(
                              Icons.sunny,
                              color: Color.fromARGB(255, 88, 44, 209),
                              size: 15,
                            ),
                            onPressed: null,
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const WindowButtons(),
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }
}

final buttonColors = WindowButtonColors(
    mouseOver: const Color.fromARGB(255, 117, 13, 245),
    mouseDown: const Color.fromARGB(255, 157, 140, 217),
    iconNormal: const Color.fromARGB(255, 88, 44, 209),
    iconMouseOver: Colors.white);

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: buttonColors),
      ],
    );
  }
}
