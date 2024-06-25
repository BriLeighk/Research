import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

// App Name, Color Scheme
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test - Spyware Detector App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 84, 109, 191),
        ),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'SafeScan'),
    );
  }
}

// App Home Page (Title, Description, Spyware Scan Button, Privacy Checkup)
class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Text(
                'SafeScan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Text(
                'SafeScan is here to help ensure your digital privacy. This app '
                'gently checks for any potentially harmful apps on your device '
                'and guides you on how to best adjust your privacy settings.\n'
                '\nPlease select an option below to begin:',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 0, bottom: 50),
              child: Divider(
                height: 5,
                thickness: 2,
                indent: 20,
                endIndent: 20,
              ),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
                child: Text(
                  'Scanning your device will '
                  'alert you of any potentially harmful apps on your device, ranked '
                  'from most to least harmful.',
                  style: TextStyle(fontSize: 14),
                )),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MyHomePage(title: 'Scan Device'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 60),
                ),
                child: const Text('Scan Device'),
              ),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
                child: Text(
                  '\nConducting a privacy scan will '
                  'provide you with some popular social media apps on your device '
                  'that may need privacy setting adjustments, and give you the option '
                  'to clear browsing traces.',
                  style: TextStyle(fontSize: 14),
                )),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyScanPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60),
                padding: const EdgeInsets.symmetric(vertical: 5.0),
              ),
              child: const Text('Privacy Scan'),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
                child: Text(
                  '\nConducting an ADB Scan allows you to scan your device remotely'
                  ' from an alternate device.',
                  style: TextStyle(fontSize: 14),
                )),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ADBScanPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60),
                padding: const EdgeInsets.symmetric(vertical: 5.0),
              ),
              child: const Text('ADB Scan'),
            ),
          ],
        ),
      ),
    );
  }
}

// Privacy Scan Page
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class PrivacyScanPage extends StatefulWidget {
  const PrivacyScanPage({super.key});

  @override
  _PrivacyScanPageState createState() => _PrivacyScanPageState();
}

class _PrivacyScanPageState extends State<PrivacyScanPage> {
  static const MethodChannel appCheckChannel =
      MethodChannel('com.example.spyware/app_check');
  static const MethodChannel appDetailsChannel =
      MethodChannel('com.example.spyware/app_details');

  List<Map<String, String>> installedApps = [];

  @override
  void initState() {
    super.initState();
    _checkInstalledApps();
  }

  Future<bool> _isAppInstalled(String packageName) async {
    try {
      final bool result = await appCheckChannel
          .invokeMethod('isAppInstalled', {'packageName': packageName});
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> _checkInstalledApps() async {
    List<String> socialMediaApps = [
      'com.instagram.android',
      'com.snapchat.android',
      'com.facebook.katana',
      'com.twitter.android',
      'com.whatsapp'
    ];
    for (String app in socialMediaApps) {
      bool isInstalled = await _isAppInstalled(app);
      if (isInstalled) {
        Map<String, String>? appDetails = await _getAppDetails(app);
        if (appDetails != null) {
          setState(() {
            installedApps.add(appDetails);
          });
        }
      }
    }
  }

  Future<Map<String, String>?> _getAppDetails(String packageName) async {
    try {
      final Map<dynamic, dynamic> result = await appDetailsChannel
          .invokeMethod('getAppDetails', {'packageName': packageName});
      return Map<String, String>.from(result);
    } catch (e) {
      return null;
    }
  }

  Future<void> _launchApp(String packageName) async {
    Map<String, String> urlMap = {
      'com.instagram.android':
          'https://www.instagram.com/accounts/login/?next=/accounts/manage_access/',
      'com.snapchat.android':
          'https://accounts.snapchat.com/accounts/login?continue=%2Faccounts%2Fmanage_access',
      'com.facebook.katana': 'fb://settings',
      'com.twitter.android': 'https://twitter.com/settings/account',
      'com.whatsapp': 'https://whatsapp.com'
    };

    String? urlString = urlMap[packageName];
    if (urlString != null) {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        //print('Could not launch $urlString');
      }
    } else {
      //print('No URL found for $package');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Scan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _launchPrivacyCheckup,
                child: Text('Google Account Privacy Checkup'),
              ),
            ),
            const Divider(
              height: 30,
              thickness: 2,
              indent: 20,
              endIndent: 20,
            ),
            ...installedApps.map((app) {
              return ListTile(
                leading: app['icon'] != null
                    ? Image.memory(base64Decode(app['icon']!))
                    : null,
                title: Text('Open ${app['name']} Settings'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => _launchAppSettings(app['package']!),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _launchApp(app['package']!),
                    ),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('samples.flutter.dev/spyware');
  static const settingsChannel = MethodChannel('com.example.spyware/settings');
  bool _searchPerformed = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _spywareApps = [];

  Future<void> _getSpywareApps() async {
    setState(() {
      _isLoading = true;
    });

    List<dynamic> spywareApps;
    try {
      final List<dynamic> result =
          await platform.invokeMethod('getSpywareApps');
      spywareApps = result.map((app) {
        return Map<String, String>.from(app.map((key, value) {
          return MapEntry(key.toString(), value.toString());
        }));
      }).toList();
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
      _isLoading = false;
      _searchPerformed = true;
    });
  }

  Future<void> _openAppSettings(String package) async {
    try {
      await settingsChannel
          .invokeMethod('openAppSettings', {'package': package});
    } catch (e) {
      //print('Failed to open app settings: $e');
    }
  }

  Color lightColor(Map<String, dynamic> app, String installer, String type) {
    if (app['installer'] != 'com.android.vending') {
      return const Color.fromARGB(255, 255, 177, 177);
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

  @override
  Widget build(BuildContext context) {
    const List<String> secureInstallers = [
      'com.android.vending',
      'com.amazon.venezia',
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
                _spywareApps.clear();
                _searchPerformed = false;
                _isLoading = false;
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
                ? const Center(child: CircularProgressIndicator())
                : _spywareApps.isEmpty && _searchPerformed
                    ? const Center(
                        child: Text("No spyware apps detected on your device"))
                    : ListView.builder(
                        itemCount: _spywareApps.length,
                        itemBuilder: (context, index) {
                          var app = _spywareApps[index];
                          Color baseColor =
                              lightColor(app, app['installer'], app['type']);

                          return TextButton(
                            onPressed: () {
                              _openAppSettings(app['id']);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(.1),
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                tileColor: Colors.transparent,
                                leading: app['icon'] != null
                                    ? Image.memory(
                                        base64Decode(app['icon']?.trim() ?? ''))
                                    : null,
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
                                        text: '(${app['id'] ?? 'Unknown ID'})',
                                      ),
                                    ],
                                  ),
                                ),
                                trailing:
                                    secureInstallers.contains(app['installer'])
                                        ? IconButton(
                                            icon: const Icon(Icons.open_in_new),
                                            onPressed: () =>
                                                _launchURL(app['storeLink']),
                                          )
                                        : null,
                              ),
                            ),
                          );
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
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('List Detected Spyware Applications'),
        ),
      ),
    );
  }
}

class ADBScanPage extends StatefulWidget {
  const ADBScanPage({super.key});

  @override
  _ADBScanPageState createState() => _ADBScanPageState();
}

class _ADBScanPageState extends State<ADBScanPage> {
  static const MethodChannel adbChannel =
      MethodChannel('com.example.spyware/adb');

  String _scanResult = "";
  bool _isScanning = false;

  Future<void> _scanOtherDevice() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final String result = await adbChannel.invokeMethod('scanOtherDevice');
      setState(() {
        _scanResult = result;
      });
    } catch (e) {
      setState(() {
        _scanResult = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Instructions for ADB Scan'),
          content: const Text(
              '1. Connect the target device to this device using a USB cable.\n'
              '2. Ensure that USB debugging is enabled on the target device.\n'
              '3. Press "Scan Other Device" to begin the scan.\n'
              '4. Wait for the scan to complete and review the results.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADB Scan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _showInstructions,
              child: const Text('Show Instructions'),
            ),
            const Divider(height: 20),
            ElevatedButton(
              onPressed: _isScanning ? null : _scanOtherDevice,
              child: _isScanning
                  ? const CircularProgressIndicator()
                  : const Text('Scan Other Device'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _scanResult,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchURL(String? urlString) async {
  if (urlString != null) {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      //print('Could not launch $urlString');
    }
  }
}

Future<void> _launchPrivacyCheckup() async {
  const MethodChannel privacyChannel =
      MethodChannel('com.example.spyware/privacy');
  try {
    await privacyChannel.invokeMethod('launchPrivacyCheckup');
  } catch (e) {
    //print('Failed to launch privacy checkup: $e');
  }
}

Future<void> _launchAppSettings(String package) async {
  const MethodChannel settingsChannel =
      MethodChannel('com.example.spyware/settings');
  try {
    await settingsChannel.invokeMethod('openAppSettings', {'package': package});
  } catch (e) {
    //print('Failed to open app settings: $e');
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
