const fs = require('fs');
const path = require('path');

// Read admin identity from wallet
const walletPath = path.join(__dirname, '../backend/wallet');
const adminFile = path.join(walletPath, 'admin');

if (!fs.existsSync(adminFile)) {
    console.error('Admin identity not found');
    process.exit(1);
}

const identity = JSON.parse(fs.readFileSync(adminFile, 'utf8'));
const cert = identity.credentials.certificate;
const key = identity.credentials.privateKey;

// Create MSP directories
const adminMsp = path.join(__dirname, '../network/organizations/peerOrganizations/landreg.example.com/users/Admin@landreg.example.com/msp');
const peerMsp = path.join(__dirname, '../network/organizations/peerOrganizations/landreg.example.com/peers/peer0.landreg.example.com/msp');

// Ensure directories exist
['signcerts', 'keystore', 'cacerts', 'admincerts'].forEach(dir => {
    fs.mkdirSync(path.join(adminMsp, dir), { recursive: true });
    fs.mkdirSync(path.join(peerMsp, dir), { recursive: true });
});

// Write certificate to signcerts
fs.writeFileSync(path.join(adminMsp, 'signcerts/cert.pem'), cert);
fs.writeFileSync(path.join(peerMsp, 'signcerts/cert.pem'), cert);

// Write private key to keystore
const keyFileName = path.join(adminMsp, 'keystore/key.pem');
fs.writeFileSync(keyFileName, key);
fs.copyFileSync(keyFileName, path.join(peerMsp, 'keystore/key.pem'));

// Copy cert to admincerts
fs.copyFileSync(path.join(adminMsp, 'signcerts/cert.pem'), path.join(adminMsp, 'admincerts/cert.pem'));
fs.copyFileSync(path.join(adminMsp, 'signcerts/cert.pem'), path.join(peerMsp, 'admincerts/cert.pem'));

console.log('Admin certificates extracted successfully');
