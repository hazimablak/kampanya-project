const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
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
  .then(() => console.log('✅ PostgreSQL (Yeni Mimari) başarıyla bağlandı!'))
  .catch(err => console.error('❌ Veritabanı hatası:', err.stack));

// 1. ESNAF GİRİŞ API'Sİ
app.post('/api/login', async (req, res) => {
  const { phone, password } = req.body;
  try {
    const result = await pool.query(
      'SELECT id, name, is_business_owner FROM users WHERE phone = $1 AND password = $2',
      [phone, password]
    );

    if (result.rows.length > 0) {
      res.json({ success: true, user: result.rows[0] });
    } else {
      res.status(401).json({ success: false, message: 'Hatalı telefon veya şifre!' });
    }
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 2. KAMPANYALARI GETİR (Ana Ekran - Müşteri & Esnaf Ortak)
// İl, ilçe veya kategoriye göre filtreleme destekler
app.get('/api/campaigns', async (req, res) => {
  const { city, district, category } = req.query;
  
  let query = 'SELECT * FROM campaigns WHERE 1=1';
  let values = [];
  let counter = 1;

  if (city) {
    query += ` AND city = $${counter}`;
    values.push(city);
    counter++;
  }
  if (district) {
    query += ` AND district = $${counter}`;
    values.push(district);
    counter++;
  }
  if (category) {
    query += ` AND category = $${counter}`;
    values.push(category);
    counter++;
  }

  query += ' ORDER BY created_at DESC';

  try {
    const result = await pool.query(query, values);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 3. YENİ KAMPANYA EKLE (Sadece Esnaf Kullanacak)
app.post('/api/campaigns', async (req, res) => {
  const { user_id, title, description, category, city, district, address, end_date } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO campaigns (user_id, title, description, category, city, district, address, end_date) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [user_id, title, description, category, city, district, address, end_date]
    );
    res.json({ success: true, campaign: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Kampanya eklenemedi' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 API Sunucusu http://localhost:${PORT} adresinde ayaklandı!`);
});