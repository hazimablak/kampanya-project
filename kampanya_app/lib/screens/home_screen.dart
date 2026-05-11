import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'add_campaign_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = GetStorage();
  bool isMerchant = false;
  String userName = '';

  List<dynamic> campaigns = [];
  bool isLoading = true;

  // Filtre Değişkenleri
  String? selectedCity;
  String? selectedCategory;

  // Örnek Kategori ve Şehir Listeleri (MVP için sabit)
  final List<String> categories = ['Tümü', 'Kahveci', 'Yemek', 'Hizmet', 'Giyim', 'Market'];
  final List<String> cities = ['Tümü', 'İstanbul', 'Ankara', 'İzmir', 'Bursa'];

  @override
  void initState() {
    super.initState();
    // Giriş yapanın kimliğini hafızadan al
    isMerchant = storage.read('isMerchant') ?? false;
    userName = storage.read('userName') ?? 'Misafir';
    
    // Kampanyaları API'den çek
    _fetchCampaigns();
  }

  Future<void> _fetchCampaigns() async {
    setState(() => isLoading = true);
    try {
      final dio = Dio();
      // BİLGİSAYARININ IP ADRESİ
      final String backendUrl = 'http://192.168.137.1:3000'; 
      
      // Filtre parametrelerini hazırla
      Map<String, dynamic> queryParams = {};
      if (selectedCity != null && selectedCity != 'Tümü') queryParams['city'] = selectedCity;
      if (selectedCategory != null && selectedCategory != 'Tümü') queryParams['category'] = selectedCategory;

      final response = await dio.get('$backendUrl/api/campaigns', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        setState(() {
          campaigns = response.data;
        });
      }
    } catch (e) {
      Get.snackbar('Hata', 'Kampanyalar yüklenemedi. Sunucu bağlantısını kontrol edin.', 
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kampanya Avcısı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Hoş geldin, $userName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              storage.erase(); // Çıkış yap ve hafızayı temizle
              Get.offAllNamed('/'); // Login ekranına dön (Route ayarına göre değiştir)
            },
          )
        ],
      ),
      body: Column(
        children: [
          // FİLTRELEME ÇUBUĞU (Senin istediğin akıllı filtre mantığı)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Şehir Seç',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCity,
                    items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      setState(() => selectedCity = val);
                      _fetchCampaigns(); // Seçim değişince API'ye tekrar istek at
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Kategori Seç',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCategory,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      setState(() => selectedCategory = val);
                      _fetchCampaigns(); // Seçim değişince API'ye tekrar istek at
                    },
                  ),
                ),
              ],
            ),
          ),

          // KAMPANYA LİSTESİ
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
                : campaigns.isEmpty
                    ? const Center(child: Text('Bu kriterlere uygun kampanya bulunamadı 😔', style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                        itemCount: campaigns.length,
                        itemBuilder: (context, index) {
                          final camp = campaigns[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(camp['category'] ?? 'Genel', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        backgroundColor: const Color(0xFFFF7A00),
                                      ),
                                      Text('${camp['city']} / ${camp['district']}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    camp['title'] ?? 'Başlıksız',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    camp['description'] ?? '',
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(camp['address'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12))),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      
      // ESNAF İÇİN "KAMPANYA EKLE" BUTONU (Senin Stratejin)
      floatingActionButton: isMerchant
          ? FloatingActionButton.extended(
              onPressed: () {
                Get.to(() => const AddCampaignScreen());
              },
              backgroundColor: const Color(0xFFFF7A00),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Kampanya Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null, // Misafir girerse buton yok (null)
    );
  }
}