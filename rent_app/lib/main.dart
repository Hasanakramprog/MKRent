import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/app_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/rental_booking_screen.dart';
import 'screens/rental_confirmation_screen.dart';
import 'screens/rental_requests_screen.dart';
import 'screens/store_management_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/cache_management_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/rental_details_screen.dart';
import 'screens/category_management_screen.dart';
import 'models/rental.dart';
import 'models/product.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/category_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Initialize Auth Service
    print('Initializing Auth Service...');
    await AuthService.initialize();
    print('Auth Service initialized successfully');

    // Initialize Notification Service
    print('Initializing Notification Service...');
    await NotificationService.initialize();
    print('Notification Service initialized successfully');

    // Initialize default categories
    print('Initializing default categories...');
    await CategoryService.initializeDefaultCategories();
    print('Default categories initialized successfully');
  } catch (e) {
    print('Error during initialization: $e');
    // Continue anyway - we'll handle auth errors in the UI
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
    
    if (state == AppLifecycleState.resumed) {
      // App is back in foreground
      NotificationService.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFD700), // Bright Yellow
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color(0xFFFFD700), // Yellow
              secondary: const Color(0xFFFFD700), // Yellow
              surface: const Color(0xFF1A1A1A), // Dark Gray
              background: const Color(0xFF000000), // Pure Black
              onPrimary: Colors.black,
              onSecondary: Colors.black,
              onSurface: Colors.white,
              onBackground: Colors.white,
            ),
        scaffoldBackgroundColor: const Color(0xFF000000), // Black background
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF000000), // Black
          foregroundColor: Colors.white, // White text
        ),
      ),
      home: const AppSelectionScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/rental-booking':
            final product = settings.arguments as Product;
            return MaterialPageRoute(
              builder: (context) => RentalBookingScreen(product: product),
            );
          case '/rental-confirmation':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => RentalConfirmationScreen(
                rental: args['rental'] as RentalRequest,
                product: args['product'] as Product,
              ),
            );
          case '/rental-requests':
            return MaterialPageRoute(
              builder: (context) => const RentalRequestsScreen(),
            );
          case '/store-management':
            return MaterialPageRoute(
              builder: (context) => const StoreManagementScreen(),
            );
          case '/add-product':
            final product = settings.arguments as Product?;
            return MaterialPageRoute(
              builder: (context) => AddProductScreen(productToEdit: product),
            );
          case '/cache-management':
            return MaterialPageRoute(
              builder: (context) => const CacheManagementScreen(),
            );
          case '/category-management':
            return MaterialPageRoute(
              builder: (context) => const CategoryManagementScreen(),
            );
          case '/notifications':
            return MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            );
          case '/rental-details':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => RentalDetailsScreen(
                rental: args['rental'] as RentalRequest,
                product: args['product'] as Product?,
              ),
            );
          case '/':
          case '/app-selection':
            return MaterialPageRoute(
              builder: (context) => const AppSelectionScreen(),
            );
          case '/welcome':
            return MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}
