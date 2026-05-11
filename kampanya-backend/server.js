require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const http = require('http');
const socketIo = require('socket.io');

// ===== SETUP =====
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});

// Middleware
app.use(express.json());
app.use(cors());

// ===== DATABASE CONNECTION =====
const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
});

pool.on('error', (err) => {
  console.error('Database error:', err);
});

console.log('✅ Database havuzu başlatıldı');

// ===== ROUTES =====

// 1. SAĞLIK KONTROLÜ
app.get('/health', (req, res) => {
  res.json({ status: 'API çalışıyor ✅', timestamp: new Date() });
});

// 2. PHONE LOGIN - OTP GÖNDER
app.post('/auth/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone || phone.length < 10) {
      return res.status(400).json({ error: 'Geçersiz telefon numarası' });
    }

    // Kullanıcı var mı kontrol et
    const user = await pool.query(
      'SELECT id FROM users WHERE phone = $1',
      [phone]
    );

    // Yoksa oluştur
    if (user.rows.length === 0) {
      await pool.query(
        'INSERT INTO users (phone, name) VALUES ($1, $2)',
        [phone, 'Yeni Kullanıcı']
      );
    }

    // OTP oluştur (Gerçekte SMS gateway'e gönder)
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Geçici depolama (Gerçekte Redis kullan)
    global.otpStore = global.otpStore || {};
    global.otpStore[phone] = {
      code: otp,
      expiresAt: Date.now() + 10 * 60 * 1000, // 10 dakika
    };

    console.log(`[TEST] OTP ${phone}'ye gönderildi: ${otp}`);

    res.json({
      message: 'OTP gönderildi',
      phone: phone,
      // DEV SADECE: OTP'yi döndür (production'da silme!)
      test_otp: process.env.NODE_ENV === 'development' ? otp : undefined,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'OTP gönderilemedi' });
  }
});

// 3. OTP DOĞRULA & TOKEN ÜRETKen
app.post('/auth/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;

    const stored = global.otpStore?.[phone];

    if (!stored || stored.code !== otp) {
      return res.status(401).json({ error: 'Geçersiz OTP' });
    }

    if (stored.expiresAt < Date.now()) {
      return res.status(401).json({ error: 'OTP süresi dolmuş' });
    }

    // OTP başarılı → User ID döndür
    const user = await pool.query(
      'SELECT id, name, is_business_owner FROM users WHERE phone = $1',
      [phone]
    );

    // Cleanup
    delete global.otpStore[phone];

    res.json({
      success: true,
      userId: user.rows[0].id,
      name: user.rows[0].name,
      is_business_owner: user.rows[0].is_business_owner,
      // Gerçekte JWT token oluştur:
      // token: jwt.sign({ userId: user.rows[0].id }, process.env.JWT_SECRET)
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Doğrulama başarısız' });
  }
});

// 4. YAKINNDAKI KAMPANYALARı (Konum Bazlı)
app.get('/campaigns/nearby', async (req, res) => {
  try {
    const { latitude, longitude, radius = 500 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: 'Konum parametreleri gerekli' });
    }

    const result = await pool.query(
      `SELECT 
        c.id, 
        c.title, 
        c.description, 
        c.discount_percent,
        c.special_condition,
        b.name as business_name, 
        b.category,
        b.phone as business_phone,
        ST_Distance(
          b.location, 
          ST_MakePoint($3, $2)::geography
        ) as distance_meters
       FROM campaigns c
       JOIN businesses b ON c.business_id = b.id
       WHERE 
        ST_DWithin(
          b.location, 
          ST_MakePoint($3, $2)::geography, 
          $1
        )
        AND c.is_active = true
       ORDER BY distance_meters ASC
       LIMIT 50`,
      [radius, latitude, longitude]
    );

    res.json({
      count: result.rows.length,
      campaigns: result.rows.map(row => ({
        ...row,
        distance_meters: Math.round(row.distance_meters),
      })),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Kampanyalar yüklenemedi' });
  }
});

// 5. KATEGORİYE GÖRE KAMPANYALAR
app.get('/campaigns/category/:category', async (req, res) => {
  try {
    const { category } = req.params;

    const result = await pool.query(
      `SELECT c.id, c.title, c.description, c.discount_percent, b.name, b.category
       FROM campaigns c
       JOIN businesses b ON c.business_id = b.id
       WHERE b.category ILIKE $1 AND c.is_active = true
       ORDER BY c.created_at DESC
       LIMIT 50`,
      [`%${category}%`]
    );

    res.json({
      category: category,
      count: result.rows.length,
      campaigns: result.rows,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Kampanyalar yüklenemedi' });
  }
});

// 6. KAMPANYA DETAY
app.get('/campaigns/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT 
        c.id, c.title, c.description, c.discount_percent, c.special_condition,
        b.id as business_id, b.name, b.category, b.phone, b.location,
        c.created_at, c.end_date
       FROM campaigns c
       JOIN businesses b ON c.business_id = b.id
       WHERE c.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Kampanya bulunamadı' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Kampanya yüklenemedi' });
  }
});

// 7. KAMPANYA OLUŞTUR (İşletmeler için)
app.post('/campaigns', async (req, res) => {
  try {
    const {
      business_id,
      title,
      description,
      discount_percent,
      special_condition,
      category,
      end_date,
    } = req.body;

    const result = await pool.query(
      `INSERT INTO campaigns 
       (business_id, title, description, discount_percent, special_condition, category, end_date, is_active, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, true, NOW())
       RETURNING *`,
      [business_id, title, description, discount_percent, special_condition, category, end_date]
    );

    res.status(201).json({
      message: 'Kampanya oluşturuldu',
      campaign: result.rows[0],
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Kampanya oluşturulamadı' });
  }
});

// 8. İŞLETME KAYDOL
app.post('/businesses/register', async (req, res) => {
  try {
    const { owner_id, name, phone, category, city, district, latitude, longitude } = req.body;

    const result = await pool.query(
      `INSERT INTO businesses 
       (owner_id, name, phone, category, city, district, location)
       VALUES ($1, $2, $3, $4, $5, $6, ST_MakePoint($7, $8))
       RETURNING *`,
      [owner_id, name, phone, category, city, district, longitude, latitude]
    );

    res.status(201).json({
      message: 'İşletme kaydedildi',
      business: result.rows[0],
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'İşletme kayıtlanamadı' });
  }
});

// ===== WEBSOCKET (Real-time Notifications) =====
io.on('connection', (socket) => {
  console.log(`Kullanıcı bağlandı: ${socket.id}`);

  // Canlı bildirim
  socket.on('nearby_campaign', (data) => {
    console.log('Yakında kampanya bildirim:', data);
    io.emit('notification', {
      message: `${data.distance}m yakında %${data.discount} indirim!`,
      campaign_id: data.campaign_id,
    });
  });

  socket.on('disconnect', () => {
    console.log(`Kullanıcı çıktı: ${socket.id}`);
  });
});

// ===== ERROR HANDLING =====
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Sunucu hatası' });
});

// QR KOD OKUTMA VE İNDİRİMİ KAYDETME
app.post('/redemptions/scan', async (req, res) => {
  try {
    const { qrData, business_id } = req.body;
    const parsedData = JSON.parse(qrData);

    await pool.query(
      `INSERT INTO redemptions (campaign_id, user_id, business_id, qr_code, verified, qr_scanned_at)
       VALUES ($1, $2, $3, $4, true, NOW())`,
      [parsedData.campaignId, parsedData.userId, business_id, qrData]
    );

    res.json({ success: true, message: 'İndirim başarıyla kullanıldı!' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Kod okunamadı veya zaten kullanılmış.' });
  }
});

// ===== SUNUCU BAŞLAT =====
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Sunucu http://10.137.38.131:${PORT} adresinde çalışıyor`);
  console.log(`   Health check: GET http://10.137.38.131:${PORT}/health`);
  console.log(`   OTP gönder: POST http://10.137.38.131:${PORT}/auth/send-otp`);
});