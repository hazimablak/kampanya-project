import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';

class QrScannerScreen extends StatelessWidget {
  final Function(String) onScan;
  const QrScannerScreen({Key? key, required this.onScan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşterinin Kodunu Okut', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              // Kodu bulduğu an kamerayı kapatıp veriyi panele gönderiyoruz
              Get.back(); 
              onScan(barcode.rawValue!);
              break; 
            }
          }
        },
      ),
    );
  }
}