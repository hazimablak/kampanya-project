const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcrypt'); // Şifre kriptolayıcı
const jwt = require('jsonwebtoken'); // Dijital Biletçi
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
});

pool.connect()
  .then(() => console.log('✅ PostgreSQL bağlandı!'))
  .catch(err => console.error('❌ Veritabanı hatası:', err.stack));

// GÜVENLİK DUVARI: Sadece bileti (Token) olanları içeri alan fonksiyon
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // "Bearer TOKEN" formatından token'ı ayıkla

  if (!token) return res.status(401).json({ success: false, message: 'Erişim reddedildi! Biletin yok.' });

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ success: false, message: 'Geçersiz veya süresi dolmuş bilet!' });
    req.user = user; // Bilet onaylandı, kullanıcının kimliğini (ID) isteğin içine koy
    next(); // Kapıyı aç, devam etmesine izin ver
  });
};

// 1. ESNAF KAYIT OL (Şifre Kriptolama)
app.post('/api/register', async (req, res) => {
  const { phone, password, name } = req.body;
  try {
    // Şifreyi 10 katmanlı tuzlama (salt) ile kırılmaz hale getir
    const hashedPassword = await bcrypt.hash(password, 10); 
    
    const result = await pool.query(
      'INSERT INTO users (phone, password, name) VALUES ($1, $2, $3) RETURNING id, phone, name',
      [phone, hashedPassword, name]
    );
    res.json({ success: true, user: result.rows[0], message: 'Kayıt başarılı!' });
  } catch (err) {
    if (err.code === '23505') return res.status(400).json({ error: 'Bu telefon numarası zaten kayıtlı.' });
    res.status(500).json({ error: 'Kayıt hatası' });
  }
});

// 2. ESNAF GİRİŞ YAP (Şifre Kontrolü ve JWT Üretimi)
app.post('/api/login', async (req, res) => {
  const { phone, password } = req.body;
  try {
    // 1. Kullanıcıyı bul
    const result = await pool.query('SELECT * FROM users WHERE phone = $1', [phone]);
    if (result.rows.length === 0) return res.status(401).json({ success: false, message: 'Kullanıcı bulunamadı!' });

    const user = result.rows[0];

    // 2. Girilen şifre ile veritabanındaki kriptolu şifreyi eşleştir
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) return res.status(401).json({ success: false, message: 'Hatalı şifre!' });

    // 3. Şifre doğru! Ona 30 gün geçerli bir dijital bilet (JWT) ver
    const token = jwt.sign({ id: user.id, phone: user.phone }, process.env.JWT_SECRET, { expiresIn: '30d' });

    res.json({ 
      success: true, 
      token: token, // İŞTE BU BİLET! Flutter bunu cebine atacak.
      user: { id: user.id, name: user.name, is_business_owner: user.is_business_owner } 
    });

  } catch (err) {
    res.status(500).json({ error: 'Giriş hatası' });
  }
});

// 3. KAMPANYALARI GETİR (Herkes görebilir, bilet gerekmez)
app.get('/api/campaigns', async (req, res) => {
  const { city, district, category } = req.query;
  let query = 'SELECT * FROM campaigns WHERE 1=1';
  let values = [];
  let counter = 1;

  if (city && city !== 'Tümü') { query += ` AND city = $${counter}`; values.push(city); counter++; }
  if (district) { query += ` AND district = $${counter}`; values.push(district); counter++; }
  if (category && category !== 'Tümü') { query += ` AND category = $${counter}`; values.push(category); counter++; }

  query += ' ORDER BY created_at DESC';

  try {
    const result = await pool.query(query, values);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 4. YENİ KAMPANYA EKLE (DİKKAT: authenticateToken ile KORUMA ALTINDA!)
app.post('/api/campaigns', authenticateToken, async (req, res) => {
  // Artık user_id'yi Flutter'dan güvenmeyip, direkt doğrulanan Token'ın içinden alıyoruz!
  const userId = req.user.id; 
  const { title, description, category, city, district, address, end_date } = req.body;
  
  try {
    const result = await pool.query(
      `INSERT INTO campaigns (user_id, title, description, category, city, district, address, end_date) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [userId, title, description, category, city, district, address, end_date]
    );
    res.json({ success: true, campaign: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Kampanya eklenemedi' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Güvenli API Sunucusu http://localhost:${PORT} adresinde ayaklandı!`));