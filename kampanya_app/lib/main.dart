import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // Local storage initialize
  await GetStorage.init();
  
  runApp(const KampanyaApp());
}

class KampanyaApp extends StatelessWidget {
  const KampanyaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kampanya Avcısı',
      theme: ThemeData(
        primaryColor: const Color(0xFFFF7A00), // Orange
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF7A00),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Splash screen - Uygulamaya giriş
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    // 2 saniye bekle (splash göster)
    await Future.delayed(const Duration(seconds: 2));
    
    // Kullanıcı giriş yapmış mı kontrol et
    final isLoggedIn = GetStorage().read('userId') != null;
    
    if (isLoggedIn) {
      Get.offAll(() => const HomeScreen());
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF7A00),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Kampanya Avcısı',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Yakınındaki İndirimler',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}