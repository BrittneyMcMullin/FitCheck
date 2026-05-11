const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: 'localhost',
  database: 'fitcheck',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port: 5432,
});

module.exports = pool;