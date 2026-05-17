import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddCampaignScreen extends StatefulWidget {
  const AddCampaignScreen({Key? key}) : super(key: key);

  @override
  State<AddCampaignScreen> createState() => _AddCampaignScreenState();
}

class _AddCampaignScreenState extends State<AddCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final storage = GetStorage();
  bool isLoading = false;
  final secureStorage = const FlutterSecureStorage();

  // Text Controller'lar
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final districtController = TextEditingController();
  final addressController = TextEditingController();

  // Dropdown ve Tarih Değişkenleri
  String? selectedCategory;
  String? selectedCity;
  DateTime? selectedDate;

  // Sabit Listeler
  final List<String> categories = ['Kahveci', 'Yemek', 'Hizmet', 'Giyim', 'Market'];
  final List<String> cities = ['İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Siirt'];

  // TARİH SEÇİCİ (Takvim)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF7A00), // Takvim Turuncu Tema
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // VERİTABANINA KAYIT FONKSİYONU
  void _submitCampaign() async {
    if (!_formKey.currentState!.validate() || selectedCategory == null || selectedCity == null || selectedDate == null) {
      Get.snackbar('Eksik Bilgi', 'Lütfen tüm alanları doldurun.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);

    try {
      final dio = Dio();
      final String backendUrl = 'http://192.168.137.1:3000'; // IP adresini kontrol et
      
      // HAFIZADAKİ BİLETİ (TOKEN) AL
      final String? token = await secureStorage.read(key: 'token'); 

      final response = await dio.post(
        '$backendUrl/api/campaigns',
        data: {
          // user_id'yi sildik, çünkü backend bunu token'dan kendisi bulacak!
          'title': titleController.text,
          'description': descriptionController.text,
          'category': selectedCategory,
          'city': selectedCity,
          'district': districtController.text,
          'address': addressController.text,
          'end_date': selectedDate!.toIso8601String(),
        },
        // BİLETİ GÜVENLİK GÖREVLİSİNE (BACKEND) GÖSTER
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        Get.snackbar('Başarılı!', 'Kampanyanız yayına alındı 🚀', backgroundColor: Colors.green, colorText: Colors.white);
        Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      Get.snackbar('Yetki Hatası', 'Oturumunuzun süresi dolmuş olabilir. Tekrar giriş yapın.', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Yeni Kampanya Oluştur', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF7A00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Kampanya Başlığı (Örn: Çaylar Müesseseden!)', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Başlık zorunludur' : null,
              ),
              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Açıklama / Şartlar', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Açıklama zorunludur' : null,
              ),
              const SizedBox(height: 16),

              // Kategori & Şehir Yan Yana
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                      value: selectedCategory,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Şehir', border: OutlineInputBorder()),
                      value: selectedCity,
                      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => selectedCity = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // İlçe
              TextFormField(
                controller: districtController,
                decoration: const InputDecoration(labelText: 'İlçe (Örn: Kadıköy)', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'İlçe zorunludur' : null,
              ),
              const SizedBox(height: 16),

              // Tam Adres
              TextFormField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Açık Adres', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Adres zorunludur' : null,
              ),
              const SizedBox(height: 24),

              // Bitiş Tarihi Seçici
              OutlinedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today, color: Color(0xFFFF7A00)),
                label: Text(
                  selectedDate == null 
                      ? 'Bitiş Tarihi Seçin' 
                      : 'Bitiş: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  style: const TextStyle(color: Colors.black87),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),

              // YAYINLA BUTONU
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kampanyayı Yayınla 🚀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}