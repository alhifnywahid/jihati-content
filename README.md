# Jihati Content

> Sumber data konten **OTA (Over-The-Air)** untuk aplikasi **Jihati** — kumpulan doa, amaliyah, dan bacaan keislaman dalam format JSON.

Repositori ini memungkinkan konten aplikasi Jihati **diperbarui tanpa merilis ulang aplikasi ke Play Store**. Cukup perbaiki file di sini (misalnya koreksi satu harakat), aplikasi akan mengunduh pembaruannya secara otomatis di latar belakang saat ada jaringan.

Repo ini berisi **HANYA data (JSON)** — tidak ada kode aplikasi sama sekali. Karena disajikan lewat CDN publik (jsDelivr), repo ini bersifat **public**.

---

## Daftar Isi

- [Cakupan](#cakupan)
- [Struktur Folder](#struktur-folder)
- [Format Data](#format-data)
  - [manifest.json](#manifestjson)
  - [0-daftar-isi.json](#0-daftar-isijson)
  - [File Konten (`jihati/<id>.json`)](#file-konten-jihatiidjson)
  - [Referensi `schema.type`](#referensi-schematype)
- [Akses via CDN (jsDelivr)](#akses-via-cdn-jsdelivr)
- [Cara Memperbarui Konten (Tutorial)](#cara-memperbarui-konten-tutorial)
- [Konvensi Versi & Rilis](#konvensi-versi--rilis)
- [Integrasi dengan Aplikasi](#integrasi-dengan-aplikasi)
- [Lisensi](#lisensi)

---

## Cakupan

**Yang dikelola di sini:** konten **jihati** (doa & amaliyah), yaitu file `jihati/1.json` … `jihati/64.json` beserta daftar isinya.

**Yang TIDAK termasuk:**

- **Al-Qur'an** dan data **lokasi (jadwal shalat)** — keduanya bersifat tetap, tidak diperbarui lewat OTA, dan tetap dibundel penuh di dalam aplikasi.
- Kode aplikasi.

---

## Struktur Folder

```
jihati-content/
├─ manifest.json          # Indeks versi + hash (SHA-256) setiap file
├─ generate_manifest.py   # Skrip untuk meregenerasi manifest.json otomatis
├─ LICENSE                # Lisensi CC BY 4.0
├─ README.md              # Dokumen ini
└─ jihati/
   ├─ 0-daftar-isi.json   # Daftar judul + flag tampil/tidak (published)
   ├─ 1.json              # Konten per entri (id 1 … 64)
   ├─ 2.json
   └─ ...
```

---

## Format Data

### `manifest.json`

Berkas indeks yang dibaca aplikasi pertama kali untuk menentukan apakah ada pembaruan.

```json
{
  "contentVersion": 2,
  "generatedAt": "2026-06-09T11:45:47",
  "baseUrl": "https://cdn.jsdelivr.net/gh/alhifnywahid/jihati-content@content-v2/",
  "fileCount": 65,
  "files": [{ "path": "jihati/1.json", "sha256": "10adfb…", "bytes": 2150 }]
}
```

| Field            | Tipe   | Keterangan                                                           |
| ---------------- | ------ | -------------------------------------------------------------------- |
| `contentVersion` | int    | Nomor versi konten. Dinaikkan setiap ada perubahan.                  |
| `generatedAt`    | string | Waktu manifest dibuat (ISO 8601).                                    |
| `baseUrl`        | string | Prefix URL CDN (tag immutable `@content-vN/`) untuk mengunduh file.  |
| `fileCount`      | int    | Jumlah file dalam manifest.                                          |
| `files[].path`   | string | Path file relatif terhadap `baseUrl`.                                |
| `files[].sha256` | string | Hash SHA-256 isi file → dipakai mendeteksi perubahan (delta update). |
| `files[].bytes`  | int    | Ukuran file (byte) → untuk validasi & estimasi unduhan.              |

> Aplikasi membandingkan `sha256` tiap file dengan yang tersimpan lokal. Hanya file yang hash-nya berbeda yang diunduh ulang.

### `0-daftar-isi.json`

Daftar seluruh entri (judul) beserta status tampil.

```json
[
  {
    "id": 1,
    "published": true,
    "title": { "arabic": "اَلتَّوَسُّلُ", "latin": "Tawassul" }
  },
  {
    "id": 3,
    "published": false,
    "title": {
      "arabic": "دُعَاءُ سُوْرَةِ الْوَاقِعَةِ",
      "latin": "Doa Surat Al-Waqi'ah"
    }
  }
]
```

| Field          | Tipe    | Keterangan                                                 |
| -------------- | ------- | ---------------------------------------------------------- |
| `id`           | int     | ID entri (cocok dengan nama file `jihati/<id>.json`).      |
| `published`    | boolean | `true` = ditampilkan di aplikasi; `false` = disembunyikan. |
| `title.arabic` | string  | Judul Arab.                                                |
| `title.latin`  | string  | Judul transliterasi/latin.                                 |

> Untuk menyembunyikan atau menampilkan sebuah entri, cukup ubah nilai `published` — tidak perlu menghapus entrinya. Pastikan entri yang di-`true`-kan sudah memiliki file kontennya (`jihati/<id>.json`).

### File Konten (`jihati/<id>.json`)

```json
{
  "schema": { "type": 1, "typeName": "" },
  "id": 1,
  "title": { "arabic": "اَلتَّوَسُّلُ", "latin": "Tawassul" },
  "content": "…teks Arab…"
}
```

Bentuk `content` ditentukan oleh `schema.type` (lihat tabel di bawah).

### Referensi `schema.type`

| type | Bentuk `content`                                                                  | Penggunaan                                                                         |
| ---- | --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `1`  | `string`                                                                          | Teks paragraf rata kanan-kiri (mis. tawassul, doa).                                |
| `2`  | `array<string>`                                                                   | Daftar baris/bait rata kanan-kiri. Bait memakai pemisah `\t۞\t`.                   |
| `3`  | `array<[arab, latin]>`                                                            | Pasangan teks Arab + transliterasi (nadham dua kolom).                             |
| `4`  | `array<string>`                                                                   | Sama seperti `2`, tetapi rata tengah.                                              |
| `5`  | `array<string>`                                                                   | Ayat-ayat Al-Qur'an (penomoran ayat ditangani oleh aplikasi, jangan tulis manual). |
| `6`  | `object` `{ pembuka:{bilal,jamaah}, sholat:[ {rakaat:[s1,s2], bilal, jamaah} ] }` | Format bilal/jamaah shalat (mis. tarawih).                                         |

> **Penting:** jangan ubah bentuk/struktur `content` dari tipenya. Mengubah `schema.type` tanpa menyesuaikan struktur dapat menyebabkan tampilan error di aplikasi.

---

## Akses via CDN (jsDelivr)

File di repo publik ini otomatis dapat diakses melalui jsDelivr. **Ada dua jenis alamat dengan peran berbeda:**

### 1. Manifest — dibaca dari alamat TETAP `@master`

Aplikasi selalu membaca manifest dari branch `master` (alamat tidak berubah), supaya **versi baru bisa ditemukan otomatis tanpa rilis ulang aplikasi**:

```
https://cdn.jsdelivr.net/gh/alhifnywahid/jihati-content@master/manifest.json
```

### 2. File konten — disajikan dari TAG immutable

`baseUrl` di dalam `manifest.json` menunjuk ke **tag rilis** (mis. `content-v2`). Semua file konten diunduh dari sana sehingga **permanen (immutable) & cache aman**:

```
https://cdn.jsdelivr.net/gh/alhifnywahid/jihati-content@content-v2/jihati/26.json
```

> **Inti pola ini:** _alamat manifest tetap_ (agar versi baru terdeteksi) + _file konten bertag_ (agar integritas & cache aman). Jangan pernah men-pin alamat manifest yang dibaca aplikasi ke tag — kalau di-pin ke tag, aplikasi tidak akan pernah tahu ada versi baru.
>
> Karena `@master` di-cache jsDelivr ±12 jam, **purge** alamat manifest setiap rilis (lihat tutorial) agar pembaruan langsung terbaca.

---

## Cara Memperbarui Konten (Tutorial)

Contoh: memperbaiki harakat pada Surat Al-Mulk (`jihati/26.json`), dirilis sebagai `content-v3`.

> Cara tercepat: jalankan skrip `release.ps1` (lihat bagian bawah) yang merangkum semua langkah ini menjadi satu perintah. Di bawah ini langkah manualnya.

1. **Edit file** konten terkait, mis. `jihati/26.json`. (Atau ubah `published` di `jihati/0-daftar-isi.json` untuk menampilkan/menyembunyikan entri.)
2. **Regenerasi manifest** dengan versi baru **dan** `baseUrl` ke tag yang akan dibuat:
   ```bash
   python generate_manifest.py --version 3 --base-url "https://cdn.jsdelivr.net/gh/alhifnywahid/jihati-content@content-v3/"
   ```
3. **Commit & push ke `main`** (di sinilah manifest yang dibaca aplikasi diperbarui):
   ```bash
   git add .
   git commit -m "content: rilis v3 (koreksi harakat Surat Al-Mulk)"
   git push origin main
   ```
4. **Buat & push tag immutable** `content-v3` (snapshot file untuk diunduh aplikasi):
   ```bash
   git tag content-v3
   git push origin content-v3
   ```
5. **Purge cache jsDelivr untuk manifest `@master`** (WAJIB agar versi baru cepat terbaca aplikasi):
   ```
   https://purge.jsdelivr.net/gh/alhifnywahid/jihati-content@master/manifest.json
   ```

Selesai. Aplikasi membaca `@master/manifest.json`, melihat `contentVersion`/hash baru, lalu mengunduh hanya file yang berubah dari tag `@content-v3`. **Tidak perlu rilis ulang APK ke Play Store.**

---

## Konvensi Versi & Rilis

- Aplikasi membaca manifest dari **alamat tetap** `@master/manifest.json` (lihat bagian Akses via CDN).
- **`contentVersion`** di `manifest.json` dinaikkan setiap publikasi (otomatis oleh `generate_manifest.py`).
- **Tag git** untuk file konten memakai format `content-vN` (mis. `content-v1`, `content-v2`, `content-v3`).
- `baseUrl` pada manifest **harus** menunjuk ke tag yang dibuat pada rilis tersebut (`@content-vN/`).
- Setiap rilis: push ke `main` **dan** push tag `content-vN`, lalu **purge** `@master/manifest.json`.

### Rilis sekali-jalan (`release.ps1`)

Untuk Windows/PowerShell, gunakan skrip pembantu agar tidak perlu mengingat semua langkah:

```powershell
# Rilis versi 3 (otomatis: regenerasi manifest, commit, push main, tag, push tag, purge)
./release.ps1 -Version 3 -Message "koreksi harakat Surat Al-Mulk"
```

Skrip akan menanyakan konfirmasi sebelum melakukan `git push`.

---

## Integrasi dengan Aplikasi

- Aplikasi membaca manifest dari **alamat tetap** `@master/manifest.json`, lalu mengunduh file konten dari **tag immutable** yang ditunjuk `baseUrl`.
- Aplikasi Jihati menerapkan pola **offline-first**:
  1. **Data hasil unduhan terbaru** (tersimpan lokal) → dipakai jika ada.
  2. **Aset bawaan di dalam APK** → cadangan untuk instalasi baru / saat belum pernah online.
- Internet hanya dibutuhkan **sesaat** untuk mengunduh pembaruan; setelah itu aplikasi berjalan penuh tanpa jaringan.
- Pembaruan bersifat **data saja** (sesuai kebijakan Google Play yang hanya melarang pembaruan _kode_ di luar Play). **Perubahan konten tidak memerlukan rilis ulang aplikasi ke Play Store.**

---

## Lisensi

Konten dalam repositori ini dilisensikan di bawah **[Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)**. Anda bebas menyebarkan dan mengadaptasi dengan mencantumkan atribusi. Lihat berkas [`LICENSE`](LICENSE) untuk teks lengkap.

Ayat-ayat Al-Qur'an merupakan domain publik; atribusi berlaku untuk kurasi, transkripsi, dan penstrukturan dataset ini.
