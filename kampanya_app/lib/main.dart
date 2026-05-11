import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'screens/login_screen.dart'; // Dosya yolunun doğru olduğundan emin ol

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter motorunu hazırla
  
  await GetStorage.init(); // Hafıza kutusunu (GetStorage) başlat! (Çökme burdan oluyordu)

  runApp(const KampanyaApp());
}

class KampanyaApp extends StatelessWidget {
  const KampanyaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // DİKKAT: MaterialApp yerine GetMaterialApp kullanmalıyız!
    return GetMaterialApp(
      title: 'Kampanya Avcısı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF7A00),
      ),
      home: const LoginScreen(),
    );
  }
}