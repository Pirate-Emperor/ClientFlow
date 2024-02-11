import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:clientflow/api/firebase_api.dart';
import 'package:clientflow/background_tasks.dart';
import 'package:clientflow/cart_page.dart';
import 'package:clientflow/firebase_options.dart';
import 'package:clientflow/home_page.dart';
import 'package:clientflow/notification_page.dart';
import 'package:clientflow/login_page.dart';
import 'package:clientflow/profile_page.dart';
import 'package:clientflow/sales_order_page.dart';
import 'package:clientflow/starting_page.dart';
import 'package:workmanager/workmanager.dart';
import 'db_sqlite.dart';
import 'products_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:clientflow/model/cart_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotifications();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/clientflow');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Check and request the SCHEDULE_EXACT_ALARM permission for Android 14+
  if (await shouldRequestExactAlarmPermission()) {
    await requestExactAlarmPermission();
  }

  // // Initialize Workmanager
  // await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // // Register periodic tasks
  // await Workmanager().registerPeriodicTask(
  //   "1",
  //   "fetchSalesOrderStatus",
  //   frequency: const Duration(minutes: 15),
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   ),
  // );

  // await Workmanager().registerPeriodicTask(
  //   "2",
  //   "checkTaskDueDates",
  //   frequency: const Duration(days: 1),
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   ),
  // );

  // await Workmanager().registerPeriodicTask(
  //   "3",
  //   "checkNewSalesLeads",
  //   frequency: const Duration(days: 1),
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   ),
  // );

  // Handling notifications received when the app is completely closed
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      Future.delayed(Duration.zero, () {
        navigatorKey.currentState?.pushNamed(
          NotificationsPage.route,
          arguments: message,
        );
      });
    }
  });

  // Handling notifications received when the app is open
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    developer.log("onMessageOpenedApp: $message");
    Future.delayed(Duration.zero, () {
      navigatorKey.currentState?.pushNamed(
        NotificationsPage.route,
        arguments: message,
      );
    });
  });

  // Initialize the SQLite database
  await DatabaseHelper.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
        // Add other providers here
      ],
      child: const MyApp(),
    ),
  );
}

// Permission handling functions for Android 14+
Future<bool> shouldRequestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    return true;
  }
  return false;
}

Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.request().isGranted) {
    developer.log('SCHEDULE_EXACT_ALARM permission granted');
  } else {
    developer.log('SCHEDULE_EXACT_ALARM permission denied');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  void _checkConnectivity() async {
    final ConnectivityResult result =
        (await Connectivity().checkConnectivity()) as ConnectivityResult;
    setState(() {
      isOffline = result == ConnectivityResult.none;
    });

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
          setState(() {
            isOffline = result == ConnectivityResult.none;
          });
        } as void Function(List<ConnectivityResult> event)?);
  }

  @override
  Widget build(BuildContext context) {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    cartModel.initializeCartCount();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: isOffline ? NoInternetScreen() : const StartingPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/sales': (context) => const SalesOrderPage(),
        '/product': (context) => const ProductsScreen(),
        '/cart': (context) => const CartPage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => const ProfilePage(),
        NotificationsPage.route: (context) => const NotificationsPage(),
      },
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("No Internet Connection"),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No internet connection available.',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
