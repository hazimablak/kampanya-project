import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- GEÇMİŞ EKRANI ---
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Geçmişi', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF7A00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Kahve Dünyası - %20 İndirim'),
            subtitle: Text('12 Mayıs 2026 - 14:30'),
            trailing: Text('Kullanıldı', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Erkek Kuaför - %15 İndirim'),
            subtitle: Text('5 Mayıs 2026 - 10:15'),
            trailing: Text('Kullanıldı', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- AYARLAR EKRANI ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF7A00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Bildirimlere İzin Ver'),
            subtitle: const Text('Yakındaki fırsatları kaçırma'),
            value: notificationsEnabled,
            activeColor: const Color(0xFFFF7A00),
            onChanged: (bool value) {
              setState(() {
                notificationsEnabled = value;
              });
              Get.snackbar('Başarılı', notificationsEnabled ? 'Bildirimler açıldı.' : 'Bildirimler kapatıldı.', snackPosition: SnackPosition.BOTTOM);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Kullanıcı Bilgilerimi Güncelle'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.defaultDialog(
                title: 'Bilgiler',
                content: const TextField(decoration: InputDecoration(hintText: 'Yeni Adınız')),
                textConfirm: 'Kaydet',
                confirmTextColor: Colors.white,
                buttonColor: const Color(0xFFFF7A00),
                onConfirm: () {
                  Get.back();
                  Get.snackbar('Güncellendi', 'Bilgileriniz kaydedildi.', backgroundColor: Colors.green, colorText: Colors.white);
                }
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Destek ve İletişim'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.snackbar('İletişim', 'destek@kampanyaavcisi.com adresine mail atabilirsiniz.', duration: const Duration(seconds: 4));
            },
          ),
        ],
      ),
    );
  }
}