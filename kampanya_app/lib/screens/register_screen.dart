import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void _register() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Hata', 'Tüm alanları doldurun!', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);

    try {
      final dio = Dio();
      final String backendUrl = 'http://10.137.38.131:3000'; // IP Adresin

      final response = await dio.post(
        '$backendUrl/api/register',
        data: {
          'name': nameController.text,
          'phone': phoneController.text,
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        Get.snackbar('Başarılı', 'Kayıt tamam! Şimdi giriş yapabilirsiniz.', backgroundColor: Colors.green, colorText: Colors.white);
        Get.back(); // Giriş ekranına geri dön
      }
    } on DioException catch (e) {
      // API'den gelen hatalar (Örn: Numara zaten var)
      if (e.response?.statusCode == 400) {
        Get.snackbar('Hata', 'Bu telefon numarası zaten kayıtlı!', backgroundColor: Colors.orange, colorText: Colors.white);
      } else {
        Get.snackbar('Hata', 'Kayıt başarısız oldu.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      // Diğer tüm beklenmeyen hatalar
      print("KAYIT HATASI DETAYI: $e");
      Get.snackbar('Hata', 'Bağlantı kurulamadı!', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      // Sayfa hala ekrandaysa yükleme animasyonunu durdur
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('İşletme Kayıt', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFFF7A00)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'İşletme Adı', prefixIcon: Icon(Icons.store), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon Numarası', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre Belirle', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00)),
                child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Kayıt Ol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}