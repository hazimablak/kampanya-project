import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'qr_scanner_screen.dart'; // Aşama 3'te oluşturacağımız kamera ekranı

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({Key? key}) : super(key: key);

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  final dio = Dio();
  // Android emulator için adresi 10.0.2.2 yap, fiziksel telefon için bilgisayarının IP'sini yaz (örn: 192.168.1.10)
  final String backendUrl = 'http://10.137.38.131:3000'; 
  final String myBusinessId = '1'; // Şimdilik test işletmemiz

  // VERİTABANI ONAYI (Backend'e istek gider)
  void _processQrScan(String rawQrData) async {
    Get.defaultDialog(title: "Doğrulanıyor...", content: const CircularProgressIndicator());
    try {
      final response = await dio.post(
        '$backendUrl/redemptions/scan',
        data: {'qrData': rawQrData, 'business_id': myBusinessId},
      );
      Get.back(); // Yükleniyor'u kapat
      if (response.statusCode == 200) {
        Get.snackbar('Başarılı! 🎉', 'İndirim veritabanına işlendi.', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Hata', 'Geçersiz QR Kod.', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // YENİ KAMPANYA EKLEME
  void _showAddCampaignDialog() {
    final titleController = TextEditingController();
    final discountController = TextEditingController();

    Get.defaultDialog(
      title: 'Yeni Kampanya Ekle',
      content: Column(
        children: [
          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Kampanya Adı (Örn: Çay Günü)')),
          TextField(controller: discountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'İndirim % (Örn: 50)')),
        ],
      ),
      textConfirm: 'Yayınla',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFFF7A00),
      onConfirm: () async {
        Get.back();
        try {
          await dio.post('$backendUrl/campaigns', data: {
            'business_id': myBusinessId,
            'title': titleController.text,
            'description': 'Özel Fırsat!',
            'discount_percent': int.parse(discountController.text),
            'category': 'Kahveci'
          });
          Get.snackbar('Süper!', 'Kampanya anında yayınlandı. Müşteriler artık görebilir.', backgroundColor: Colors.green, colorText: Colors.white);
        } catch (e) {
          Get.snackbar('Hata', 'Eklenemedi.', backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Esnaf Paneli', style: TextStyle(color: Colors.white)), backgroundColor: Colors.black87),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kahve Dünyası', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddCampaignDialog,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Kampanya Patlat'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00), foregroundColor: Colors.white),
            ),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () {
                  Get.to(() => QrScannerScreen(onScan: _processQrScan)); // Kamerayı aç
                },
                child: Container(
                  width: 200, height: 200,
                  decoration: const BoxDecoration(color: Color(0xFFFF7A00), shape: BoxShape.circle),
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.qr_code_scanner, size: 80, color: Colors.white),
                    SizedBox(height: 10),
                    Text('KAMERAYI AÇ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}