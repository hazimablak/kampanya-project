import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kampanya_app/services/api_client.dart'; // Ajanı buraya çağırdık!

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final storage = GetStorage();
  bool isLoading = false;
  final secureStorage = const FlutterSecureStorage();

  // ESNAF GİRİŞİ API İSTEĞİ (Ajan Kullanarak)
  void _merchantLogin() async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Hata', 'Telefon ve şifre zorunludur!', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);

    try {
      // IP ve Dio yazmak yok! Ajan (ApiClient) adresi zaten biliyor.
      final response = await ApiClient.dio.post(
        '/api/login',
        data: {
          'phone': phoneController.text,
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        // İki bileti de kasaya (Secure Storage) sakla
        await secureStorage.write(key: 'accessToken', value: response.data['accessToken']);
        await secureStorage.write(key: 'refreshToken', value: response.data['refreshToken']);
        
        // Esnaf rolünü normal storage'da tutabilirsin
        storage.write('isMerchant', true); 
        storage.write('merchantPhone', phoneController.text);
        
        Get.offAllNamed('/home'); // Ana sayfaya yönlendir
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        Get.snackbar('Hata', 'Numara veya şifre hatalı!', backgroundColor: Colors.redAccent, colorText: Colors.white);
      } 
      else if (e.response?.statusCode == 429) {
        Get.snackbar('🛡️ Engellendi', e.response?.data['message'] ?? 'Çok fazla deneme yaptınız.', 
            backgroundColor: Colors.orange, colorText: Colors.white, duration: const Duration(seconds: 4));
      } 
      else {
        // KAMUFLAJI KALDIRDIK: Node.js'in fırlattığı GERÇEK hatayı paketten çıkarıp ekrana basıyoruz!
        final String realError = e.response?.data?['error'] ?? e.response?.data?['message'] ?? e.message ?? 'Bilinmeyen Hata';
        
        Get.snackbar('Backend Ne Diyor?', realError, 
            backgroundColor: Colors.purple, colorText: Colors.white, duration: const Duration(seconds: 8));
        
        print("🚨 GİZLİ HATA DETAYI: ${e.response?.data}");
      }
    } catch (e) {
      print("LOGIN BEKLENMEYEN HATA: $e");
      Get.snackbar('Hata', 'Bir hata oluştu!', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // MÜŞTERİ (MİSAFİR) GİRİŞİ - KAYIT YOK!
  void _guestLogin() {
    storage.write('isMerchant', false);
    storage.write('userName', 'Misafir');
    Get.offAll(() => const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.local_offer, size: 80, color: Color(0xFFFF7A00)),
              const SizedBox(height: 24),
              const Text(
                'Kampanya Avcısı',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 40),

              // KOCAMAN MİSAFİR GİRİŞ BUTONU
              ElevatedButton.icon(
                onPressed: _guestLogin,
                icon: const Icon(Icons.explore, color: Colors.white, size: 28),
                label: const Text('Kayıt Olmadan Keşfet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              const SizedBox(height: 40),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('VEYA ESNAF GİRİŞİ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  Expanded(child: Divider(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 24),

              // Esnaf Telefon
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  prefixIcon: const Icon(Icons.store, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Esnaf Şifre
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Esnaf Giriş Butonu
              SizedBox(
                height: 55,
                child: OutlinedButton(
                  onPressed: isLoading ? null : _merchantLogin,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF7A00), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Color(0xFFFF7A00))
                      : const Text('İşletme Sahibi Girişi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF7A00))),
                ),
              ),
              TextButton(
                onPressed: () => Get.to(() => const RegisterScreen()),
                child: const Text('İşletmeniz yok mu? Hemen Kayıt Olun', style: TextStyle(color: Color(0xFFFF7A00))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}