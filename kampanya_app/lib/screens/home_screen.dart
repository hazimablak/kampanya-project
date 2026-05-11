import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart'; // GERÇEK KONUM İÇİN EKLENDİ
import 'map_screen.dart';
import 'qr_screen.dart';
import 'merchant_dashboard.dart';
import 'profile_screens.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = GetStorage();
  final dio = Dio();
  final String backendUrl = 'http://10.137.38.131:3000'; 
  
  List<dynamic> campaigns = [];
  bool isLoading = true;
  String selectedCategory = 'Tümü';

  @override
  void initState() {
    super.initState();
    _determinePositionAndLoad();
  }

  // GERÇEK GPS KONUMUNU ALAN FONKSİYON
  Future<void> _determinePositionAndLoad() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => isLoading = true);

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Hata', 'Lütfen cihazınızın konum servisini açın.');
      setState(() => isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Hata', 'Konum izni reddedildi. Yakındaki fırsatları göremezsiniz.');
        setState(() => isLoading = false);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Hata', 'Konum izinleri kalıcı olarak reddedilmiş. Ayarlardan açmanız gerekiyor.');
      setState(() => isLoading = false);
      return;
    } 

    // Gerçek konumu al
    Position position = await Geolocator.getCurrentPosition();
    loadCampaigns(position.latitude, position.longitude);
  }

  void loadCampaigns(double lat, double lng) async {
    try {
      final response = await dio.get(
        '$backendUrl/campaigns/nearby',
        queryParameters: {
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'radius': '5000', // 5 km çap
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          campaigns = response.data['campaigns'] ?? [];
        });
      }
    } catch (e) {
      print('API Hatası: $e');
      setState(() => campaigns = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = storage.read('userName') ?? 'Kullanıcı';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampanya Avcısı', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF7A00),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showProfileMenu(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF7A00),
        onRefresh: () async => _determinePositionAndLoad(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, $userName! 👋',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yakınındaki fırsatları keşfet',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Kategori Filtreleri (Canlı)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Tümü', 'Kahveci', 'Berber', 'Yemek']
                        .map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(cat),
                              selected: selectedCategory == cat,
                              selectedColor: const Color(0xFFFF7A00).withOpacity(0.2),
                              checkmarkColor: const Color(0xFFFF7A00),
                              onSelected: (selected) {
                                setState(() => selectedCategory = cat);
                                // İleride buraya kategoriye göre filtreleme eklenecek
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Kampanyalar Listesi
                if (isLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
                else if (campaigns.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.location_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Yakında kampanya bulunamadı', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return CampaignCard(campaign: campaign);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: const Color(0xFFFF7A00),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Get.to(() => const MapScreen());
          } else if (index == 2) {
            // ALT MENÜ QR BUTONU MANTIĞI EKLENDİ
            Get.snackbar(
              'Cüzdan Boş', 
              'Henüz aktif bir kodunuz yok. Lütfen listeden bir kampanyanın detaylarına girip kodu alın.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.black87,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          } else if (index == 3) {
            _showProfileMenu();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Cüzdanım'), // İsim değişti
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFFFF7A00)),
              title: const Text('Geçmiş'),
              onTap: () {
                Get.back();
                Get.to(() => const HistoryScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFFFF7A00)),
              title: const Text('Ayarlar'),
              onTap: () {
                Get.back();
                Get.to(() => const SettingsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              onTap: () {
                GetStorage().erase(); 
                Get.offAll(() => const LoginScreen()); 
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.store, color: Colors.black87),
              title: const Text('İşletme Hesabına Geç'), // ARTIK TEST YAZMIYOR
              onTap: () {
                Get.back();
                Get.offAll(() => const MerchantDashboard());
              },
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

class CampaignCard extends StatelessWidget {
  final dynamic campaign;
  const CampaignCard({Key? key, required this.campaign}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final distance = campaign['distance_meters'] ?? 0;
    final distanceStr = distance > 1000 ? '${(distance / 1000).toStringAsFixed(1)}km' : '${distance}m';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.orange.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign['title'] ?? 'Kampanya',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        campaign['business_name'] ?? 'İşletme',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF7A00).withOpacity(0.5)),
                  ),
                  child: Text(
                    '%${campaign['discount_percent'] ?? 0}',
                    style: const TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(distanceStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => QrScreen(campaign: campaign)); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('İndirimi Kap', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}