import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // لتحويل القوائم إلى نصوص والعكس

class Apps extends StatefulWidget {
  const Apps({super.key});

  @override
  State<Apps> createState() => _AppsState();
}

class _AppsState extends State<Apps> {
  static const platform = MethodChannel('com.example.proup/installed_apps');

  // القائمة الأساسية للتطبيقات
  List<Map<String, String>> apps = [
    {
      "name": "ترتيل",
      "path": "com.mmmoussa.iqra",
    },
    {
      "name": "يوتيوب",
      "path": "com.google.android.youtube",
    },
    {
      "name": "واتساب",
      "path": "com.whatsapp",
    },
    {
      "name": "TickTick",
      "path": "com.ticktick.task",
    },
  ];

  // قائمة التطبيقات المثبتة
  List<Map<String, String>> installedApps = [];

  // جلب التطبيقات المثبتة
  Future<void> fetchInstalledApps() async {
    try {
      final List<dynamic> result =
          await platform.invokeMethod('getInstalledApps');
      print("Fetched apps: $result"); // التحقق من النتيجة

      setState(() {
        installedApps = result
            .map((app) => {
                  "name": app["name"].toString(),
                  "path": app["package"].toString()
                })
            .cast<Map<String, String>>()
            .toList();
      });
    } on PlatformException catch (e) {
      print("Error fetching apps: ${e.message}");
    }
  }

  Future<void> saveAppsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedApps = jsonEncode(apps); // تحويل القائمة إلى JSON
    await prefs.setString('savedApps', encodedApps); // حفظ القائمة
    print("Apps saved to storage: $encodedApps");
  }

  Future<void> loadAppsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedApps = prefs.getString('savedApps');
    if (encodedApps != null) {
      setState(() {
        apps = List<Map<String, String>>.from(
          jsonDecode(encodedApps), // تحويل JSON إلى قائمة
        );
      });
      print("Apps loaded from storage: $apps");
    }
  }

  @override
  void initState() {
    super.initState();
    loadAppsFromStorage(); // تحميل التطبيقات من التخزين المحلي
    fetchInstalledApps(); // جلب التطبيقات المثبتة
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: apps
          .map(
            (app) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GestureDetector(
                onTap: () async {
                  await LaunchApp.openApp(
                    androidPackageName: app['path'],
                    openStore: false,
                  );
                },
                onLongPress: () {
                  // فتح قائمة التطبيقات المثبتة
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return ListView.builder(
                        itemCount: installedApps.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(installedApps[index]["name"] ?? ""),
                            onTap: () {
                              setState(() {
                                apps[apps.indexOf(app)] = installedApps[index];
                              });
                              saveAppsToStorage(); // حفظ التطبيقات بعد التعديل
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  );
                },
                child: Column(
                  children: [
                    Text(
                      app['name'].toString(),
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
