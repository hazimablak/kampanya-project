import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'home_screen.dart';
import 'merchant_dashboard.dart';

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

  void _handleLogin() async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Hata', 'Lütfen tüm alanları doldurun', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);

    // Gerçek dünyada burada backend'e (Node.js) istek atacağız.
    // Şimdilik UI/UX testleri için simülasyon yapıyoruz:
    await Future.delayed(const Duration(seconds: 1)); // API bekleme simülasyonu

    String phone = phoneController.text;
    
    // HİLE KODU: Numara 555 ise işletme sahibidir!
    if (phone == "555") {
      storage.write('isMerchant', true);
      storage.write('userName', 'Kahve Dünyası Patronu');
      storage.write('businessId', '1'); // İşletme ID'sini kaydet
      Get.offAll(() => const MerchantDashboard());
    } else {
      // Normal Müşteri
      storage.write('isMerchant', false);
      storage.write('userName', 'Niko'); // Test Müşterisi
      storage.write('userId', '101'); // Müşteri ID'sini kaydet
      Get.offAll(() => const HomeScreen());
    }

    setState(() => isLoading = false);
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
              const SizedBox(height: 60),
              // Logo veya İkon
              const Icon(Icons.local_offer, size: 80, color: Color(0xFFFF7A00)),
              const SizedBox(height: 24),
              const Text(
                'Kampanya Avcısı',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Şehrindeki en iyi indirimleri yakala!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // Telefon Input
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  hintText: '5XX XXX XX XX',
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFFFF7A00)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Şifre Input
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifre / OTP Kodu',
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF7A00)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Giriş Butonu
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Test Notu
              const Text(
                '* Esnaf paneli için numaraya "555" yazın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            ],
          ),
        ),
      ),
    );
  }
}