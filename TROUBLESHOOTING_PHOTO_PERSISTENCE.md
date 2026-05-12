# Troubleshooting: Foto Kandidat Hilang Saat Reload

## Penyebab Umum & Solusi

### 1. **Import `dart:typed_data` Hilang** ✅ DIPERBAIKI
- **Gejala:** Build error atau runtime crash saat compress image
- **Solusi:** Ensure import ada di `persistent_storage_service.dart`
  ```dart
  import 'dart:typed_data';  // HARUS ADA
  ```
- **Status:** Fixed - import sudah ditambahkan

### 2. **Photo URL Tidak Disimpan ke SharedPreferences**
- **Debug:** Buka browser DevTools → Console
- **Cari logs:**
  ```
  [PersistentStorage] Saving X candidates...
  [PersistentStorage] Candidate 0: <nama> | Photo1 length: XXXX | Photo2 length: YYYY
  [PersistentStorage] JSON size: ZZZZ bytes
  ```
- **Jika Photo1/2 length = 0 atau tidak ada**
  - Photo tidak di-encode menjadi base64
  - Check admin screen: `[ManageCandidate] Photo 1 encoded: ...`
  - Jika tidak ada, photo bytes tidak teradisi dengan baik

### 3. **Photo Tersimpan Tapi Tidak Dimuat**
- **Debug:** Reload page (F5) dan lihat console
- **Cari logs:**
  ```
  [PersistentStorage] Loading candidates...
  [PersistentStorage] ✓ Successfully loaded X candidates
  [PersistentStorage] Candidate 0: <nama> | Photo1 length: XXXX
  ```
- **Jika Photo1 length = 0 setelah reload**
  - Data tersimpan tapi photo URL corrupt/hilang saat save
  - Check JSON di browser storage: `Application → Storage → Local Storage`
  - Cari key `candidates_v2` atau `candidates_backup`
  - Lihat apakah `photoUrl1` ada dan tidak empty

### 4. **LocalStorage Storage Size Limit**
- **Gejala:** Foto hilang tiba-tiba setelah menambah banyak kandidat
- **Penyebab:** Browser localStorage limit ~5-10MB per domain
- **Solusi:** Chunking otomatis untuk data > 800KB
  ```
  [PersistentStorage] JSON exceeds chunk size limit, saving chunked...
  [PersistentStorage] Saving X chunks...
  ```
- **Debug:** Check aplikasi → Storage info (admin dashboard)

### 5. **Browser Cache Issue**
- **Solusi 1:** Hard refresh (Ctrl+Shift+R atau Cmd+Shift+R)
- **Solusi 2:** Clear site data
  ```
  DevTools → Application → Storage → Clear site data
  ```
- **Solusi 3:** Restart browser completely

## Step-by-Step Test

### Test 1: Upload & Immediate Reload
```
1. Login admin
2. Manage Candidates → Upload foto kandidat
3. Click "Simpan"
4. Tunggu snackbar "✓ Data tersimpan"
5. Lihat console untuk logs:
   - [ManageCandidate] Photo 1 encoded: xxx...
   - [ManageCandidate] ✓ Candidate data verified as saved | Photo1: OK
   - [PersistentStorage] Saving X candidates... Photo1 length: XXXX
   
6. Refresh page (F5)
7. Lihat console:
   - [PersistentStorage] Loading candidates...
   - [PersistentStorage] Candidate 0: <nama> | Photo1 length: XXXX
   
8. Cek UI: Photo masih tampil?
```

### Test 2: Logout & Login Ulang
```
1. Upload foto seperti Test 1
2. Logout (atau close browser tab sepenuhnya)
3. Buka ulang aplikasi / Login ulang
4. Cek dashboard - foto masih ada?
5. Check console logs (step 5-7 dari Test 1)
```

### Test 3: Check Storage Directly
```
1. Upload foto
2. Buka DevTools (F12)
3. Go to "Application" tab
4. Storage → Local Storage → http://localhost:8080 (atau domain kamu)
5. Cari key: candidates_v2 atau candidates_backup
6. Klik → Copy value
7. Paste ke online JSON formatter → Check struktur:
   - Harus ada "photoUrl1": "<base64 string>"
   - Base64 harus mulai dengan /9j/ (JPEG) atau iVBORw0KGgo (PNG)
   - Atau dimulai dengan data:image/
```

## Debug Logs Interpretation

| Log | Arti | Action |
|-----|------|--------|
| `[PersistentStorage] Saving X candidates...` | Proses simpan dimulai | Normal |
| `Photo1 length: 0` | Photo tidak ada | ❌ Upload ulang |
| `Photo1 length: >10000` | Photo tersimpan | ✅ OK |
| `JSON size: >5MB` | Data besar, pakai chunking | ✅ Normal |
| `Saving X chunks...` | Chunked save dimulai | ✅ Normal untuk data besar |
| `JSON exceeds chunk limit` | Automatic chunking triggered | ✅ Normal |
| `✓ Successfully saved candidates` | Save berhasil | ✅ OK |
| `✗ Error saving candidates` | Save gagal | ❌ Retry |
| `Loading candidates...` | Load dimulai pada reload | ✅ Normal |
| `✓ Successfully loaded X candidates` | Load berhasil | ✅ OK |
| `✗ Error loading candidates` | Load gagal | ❌ Check storage |
| `No saved data found` | Storage kosong | ℹ️ First run atau cleared |
| `Backup recovery also failed` | Backup juga corrupt | ❌ Clear storage & re-upload |

## Fast Fixes

### Jika Foto Hilang Setelah Refresh
```
1. DevTools → Application → Storage → Clear site data
2. Refresh page
3. Upload foto ulang
4. Verify di console: Photo1 length > 0
5. Refresh & check apakah tersimpan
```

### Jika Tetap Tidak Bisa
```
1. Pastikan browser support localStorage (all modern browsers)
2. Check Private/Incognito mode? → Try normal mode
3. Check browser storage quota:
   - Open DevTools Console
   - Run: navigator.storage.estimate().then(e => console.log(e))
   - Check available space
4. Report logs dengan:
   - Screenshot dari console [PersistentStorage] logs
   - Storage info dari admin dashboard
```

## For Developers

### To Add More Detailed Logging
Edit `persistent_storage_service.dart`:
```dart
debugPrint('[PersistentStorage] Photo1 Value: ${candidates[i].photoUrl1?.substring(0, 100)}...');
```

### To Export Storage for Inspection
In browser console:
```javascript
const data = localStorage.getItem('candidates_v2');
console.log(JSON.parse(data));
// atau save to file
copy(data)
```

---

**Last Updated:** May 11, 2026
**Build:** Flutter web release with async persistence & photo logging
