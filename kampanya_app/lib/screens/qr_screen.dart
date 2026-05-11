import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';

class QrScreen extends StatelessWidget {
  final dynamic campaign;
  
  const QrScreen({Key? key, this.campaign}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Eğer alt menüden basıldıysa ve kampanya seçilmediyse:
    if (campaign == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cüzdanım'), backgroundColor: const Color(0xFFFF7A00)),
        body: const Center(
          child: Text('Lütfen ana sayfadan bir kampanya seçin.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }

    // Seçili Kampanya Verileri
    final storage = GetStorage();
    final userId = storage.read('userId') ?? '101';
    final campaignId = campaign['id'] ?? 1;
    final businessName = campaign['business_name'] ?? 'İşletme';
    final discount = campaign['discount_percent'] ?? 0;

    // ESNAFIN OKUYACAĞI GİZLİ JSON VERİSİ
    // Gerçekte bu veri backend'de şifrelenir (JWT gibi), MVP için JSON atıyoruz.
    final qrDataObj = {
      "userId": userId,
      "campaignId": campaignId,
      "timestamp": DateTime.now().millisecondsSinceEpoch
    };
    final String qrDataString = jsonEncode(qrDataObj);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('İndirim Kodun', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF7A00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Müşteri için şık bir bilet tasarımı
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '%$discount İndirim Fırsatı',
                      style: const TextStyle(fontSize: 18, color: Color(0xFFFF7A00), fontWeight: FontWeight.w600),
                    ),                  
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(thickness: 2, color: Colors.grey), // Bilet kesik çizgisi efekti
                    ),
                    // İŞTE BARKOD BURADA ÜRETİLİYOR!
                    QrImageView(
                      data: qrDataString,
                      version: QrVersions.auto,
                      size: 250.0,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bu kodu kasada okutun',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Kod tek kullanımlıktır ve 5 dakika geçerlidir.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            ],
          ),
        ),
      ),
    );
  }
}