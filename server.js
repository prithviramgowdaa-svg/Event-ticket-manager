const express = require('express');
const path = require('path');
const os = require('os');
const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files from the root directory
app.use(express.static(__dirname));

// Route mapping
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/details', (req, res) => {
  res.sendFile(path.join(__dirname, 'details.html'));
});

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin.html'));
});

app.get('/scanner', (req, res) => {
  res.sendFile(path.join(__dirname, 'scanner.html'));
});

// Detect local network IP
let localIp = 'localhost';
const networkInterfaces = os.networkInterfaces();
for (const interfaceName in networkInterfaces) {
  const interfaces = networkInterfaces[interfaceName];
  for (const iface of interfaces) {
    if (iface.family === 'IPv4' && !iface.internal) {
      localIp = iface.address;
      break;
    }
  }
}

app.listen(PORT, () => {
  console.log(`===================================================`);
  console.log(`  EventPass QR Platform is running!`);
  console.log(`  Local URL:   http://localhost:${PORT}`);
  console.log(`  Mobile URL:  http://${localIp}:${PORT}/scanner`);
  console.log(`===================================================`);
});
