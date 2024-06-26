import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test - Spyware Detector App', //title of app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            //color scheme of entire app
            seedColor: const Color.fromARGB(255, 84, 109, 191)),
        useMaterial3: true,
      ),
      // Title Displayed on App
      home: const MainPage(title: 'Trial - Spyware App'),
    );
  }
}

// NEW HOME PAGE
class MainPage extends StatefulWidget {
  // Main Home Page
  const MainPage({super.key, required this.title});

  // Main Home Page

  final String title; //possibly change this

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Main Home Page State
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.start, // Adjust vertical alignment
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40), // Increase space at the top
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Text(
                'Spyware Detection Software',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Text(
                'Choose an option below to begin:',
                style: TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 20.0), // Increased vertical padding
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MyHomePage(title: 'Scan Device')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 60), // Adjust size as needed
                ),
                child: const Text('Scan Device'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PrivacyScanPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60), // Adjust size as needed
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0), // Increase padding
              ),
              child: const Text('Privacy Scan'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // App Scan Home Page
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class PrivacyScanPage extends StatelessWidget {
  // Privacy Scan Home Page
  const PrivacyScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Scan'),
      ),
      body: const Center(
        child: Text('Privacy Scan Functionality Coming Soon!'),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  // App Scan Home Page State
  bool _searchPerformed = false;
  bool _isLoading = false; // Indicator to track loading state
  static const platform = MethodChannel('samples.flutter.dev/spyware');

  // initialize method channel to correspond with native languages
  List<Map<String, dynamic>> _spywareApps = []; //to store all detected spyware

  Future<void> _getSpywareApps() async {
    setState(() {
      _isLoading = true; // Start loading phase
    });

    List<dynamic> spywareApps;
    try {
      final List<dynamic> result =
          await platform.invokeMethod('getSpywareApps'); //access method channel
      spywareApps = result.map((app) {
        return Map<String, String>.from(app.map((key, value) {
          return MapEntry(key.toString(), value.toString());
        }));
      }).toList(); //store result (since result is final)
      spywareApps.sort((a, b) => _getSortWeight(a['type'], a['installer'])
          .compareTo(_getSortWeight(b['type'], b['installer'])));
    } on PlatformException catch (e) {
      spywareApps = [
        {
          "id": "Error",
          "name": "Failed to get spyware apps: '${e.message}'.",
          "icon": null
        }
      ];
    }
    setState(() {
      _spywareApps = spywareApps.cast<Map<String, dynamic>>();
      _isLoading = false; // Stop loading once scan is complete
      _searchPerformed = true;
      // cast list from dynamic to string type.
    });
  }

  static const settingsPlatform = MethodChannel('com.example.spyware/settings');
  Future<void> _openAppSettings(String package) async {
    try {
      await settingsPlatform
          .invokeMethod('openAppSettings', {'package': package});
    } catch (e) {
      //print('Failed to open app settings: $e');
    }
  }

  Color lightColor(
    Map<String, dynamic> app,
    String installer,
    String type,
  ) {
    if (app['installer'] != 'com.android.vending') {
      return const Color.fromARGB(255, 255, 177, 177); //unsecure
    } else {
      if (app['type'] == 'offstore') {
        return const Color.fromARGB(255, 255, 177, 177);
      } else if (app['type'] == 'spyware' || app['type'] == 'Unknown') {
        return const Color.fromARGB(255, 255, 255, 173);
      } else if (app['type'] == 'dual-use') {
        return const Color.fromARGB(255, 175, 230, 255);
      } else {
        return Colors.grey;
      }
    }
  }

  // WIDGET FOR SCAN PAGE ////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    const List<String> secureInstallers = [
      'com.android.vending',
      'com.amazon.venezia',
      // other secure installer package names
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _spywareApps.clear(); // Only clear the current list on screen
                _searchPerformed = false;
                _isLoading = false; // Ensures loading is reset on refresh
              });
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(" Color Key: ",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Dual-use  ",
                    style: TextStyle(
                        backgroundColor: Color.fromARGB(255, 175, 230, 255),
                        fontWeight: FontWeight.bold)),
                Text("Spyware  ",
                    style: TextStyle(
                        backgroundColor: Color.fromARGB(255, 255, 255, 173),
                        fontWeight: FontWeight.bold)),
                Text("Unsecure Download ",
                    style: TextStyle(
                        backgroundColor: Color.fromARGB(255, 255, 177, 177),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator()) // Show loading indicator
                : _spywareApps.isEmpty &&
                        _searchPerformed //if list is empty, no spyware apps detected,
                    ? const Center(
                        child: Text("No spyware apps detected on your device"))
                    : ListView.builder(
                        //otherwise, build the list view and display it.
                        itemCount: _spywareApps.length,
                        itemBuilder: (context, index) {
                          var app = _spywareApps[index];
                          Color baseColor = lightColor(app, app['installer'],
                              app['type']); //Default no background

                          return TextButton(
                              onPressed: () {
                                _openAppSettings(app['id']);
                              },
                              child: Container(
                                margin: const EdgeInsets.all(.1),
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(10.0),

                                  // makes rounded borders
                                ),
                                child: ListTile(
                                  tileColor: Colors.transparent,
                                  leading: app['icon'] != null
                                      ? Image.memory(base64Decode(
                                          app['icon']?.trim() ?? ''))
                                      : null, // Displays the icon for the app if it's not null
                                  title: RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: <TextSpan>[
                                        TextSpan(
                                          text:
                                              '${app['name'] ?? 'Unknown Name'}  ',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text:
                                              '(${app['id'] ?? 'Unknown ID'})',
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: secureInstallers
                                          .contains(app['installer'])
                                      ? IconButton(
                                          icon: const Icon(Icons.open_in_new),
                                          onPressed: () =>
                                              _launchURL(app['storeLink']),
                                        )
                                      : null,
                                  //onTap: () => _openAppSettings(app['id'])),
                                ),
                              ));
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _getSpywareApps,
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Theme.of(context)
                .colorScheme
                .primary, // Use the onPrimary color for text/icon color
          ), // This button continues to initiate the scan
          child: const Text('List Detected Spyware Applications'),
        ),
      ),
    );
  }
}

void _launchURL(String? urlString) async {
  if (urlString != null) {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      //Handle error
    }
  }
}

int _getSortWeight(String type, String installer) {
  if (installer != 'com.android.vending' && installer != 'com.amazon.venezia') {
    return 1;
  } else {
    if (type == 'offstore') {
      return 2;
    } else if (type == 'spyware' || type == 'Unknown') {
      return 3;
    } else if (type == 'dual-use') {
      return 4;
    } else {
      return 5;
    }
  }
}
