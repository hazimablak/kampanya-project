import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'home_screen.dart';

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

  // ESNAF GİRİŞİ API İSTEĞİ
  void _merchantLogin() async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Hata', 'Telefon ve şifre zorunludur!', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);

    try {
      final dio = Dio();
      // BİLGİSAYARININ IP ADRESİ BURAYA (Aynı Wi-Fi'da olmalısınız)
      final String backendUrl = 'http://192.168.137.1:3000'; 

      final response = await dio.post(
        '$backendUrl/api/login',
        data: {
          'phone': phoneController.text,
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200 && response.data['success']) {
        // Esnaf doğrulandı! Bilgileri kaydet
        final user = response.data['user'];
        storage.write('isMerchant', true);
        storage.write('userId', user['id']);
        storage.write('userName', user['name']);

        Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      Get.snackbar('Giriş Başarısız', 'Telefon numarası veya şifre hatalı.', backgroundColor: Colors.orange, colorText: Colors.white);
    } finally {
      setState(() => isLoading = false);
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

              // KOCAMAN MİSAFİR GİRİŞ BUTONU (Senin Stratejin)
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
            ],
          ),
        ),
      ),
    );
  }
}