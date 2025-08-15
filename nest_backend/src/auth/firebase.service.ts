import * as admin from 'firebase-admin';
import * as path from 'path';
import { readFileSync } from 'fs';

const serviceAccountPath = path.resolve(process.cwd(), 'serviceAccountKey.json');
const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;
