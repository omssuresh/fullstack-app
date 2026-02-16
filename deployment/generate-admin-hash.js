const bcrypt = require('bcrypt');

// Generate hash for default admin password
const password = 'Admin@123';
const saltRounds = 10;

bcrypt.hash(password, saltRounds, (err, hash) => {
  if (err) {
    console.error('Error generating hash:', err);
    process.exit(1);
  }
  
  console.log('Generated password hash for: Admin@123');
  console.log('Hash:', hash);
  console.log('\nUpdate init.sql with this hash');
  console.log('Replace the INSERT statement with:');
  console.log(`
INSERT INTO users (username, email, password_hash, role) 
VALUES (
  'admin', 
  'admin@example.com', 
  '${hash}',
  'admin'
) ON DUPLICATE KEY UPDATE id=id;
  `);
});
