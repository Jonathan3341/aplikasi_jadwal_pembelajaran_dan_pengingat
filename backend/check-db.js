
const db = require('./src/config/database');

const tables = db.prepare(`
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
`).all();

console.log('Daftar tabel database:');
console.log(tables);

const columns = db.prepare(`
    PRAGMA table_info(schedules)
`).all();

console.log('\nKolom tabel schedules:');
console.log(columns);

db.close();
