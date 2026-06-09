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
  "contentVersion": 1,
  "generatedAt": "2026-06-08T23:51:15",
  "baseUrl": "https://cdn.jsdelivr.net/gh/USERNAME/jihati-content@content-v1/",
  "fileCount": 65,
  "files": [{ "path": "jihati/1.json", "sha256": "10adfb…", "bytes": 2150 }]
}
```

| Field            | Tipe   | Keterangan                                                           |
| ---------------- | ------ | -------------------------------------------------------------------- |
| `contentVersion` | int    | Nomor versi konten. Dinaikkan setiap ada perubahan.                  |
| `generatedAt`    | string | Waktu manifest dibuat (ISO 8601).                                    |
| `baseUrl`        | string | Prefix URL CDN untuk mengunduh file.                                 |
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

File di repo publik ini otomatis dapat diakses melalui jsDelivr:

```
https://cdn.jsdelivr.net/gh/USERNAME/jihati-content@<versi>/manifest.json
https://cdn.jsdelivr.net/gh/USERNAME/jihati-content@<versi>/jihati/26.json
```

`<versi>` sebaiknya berupa **tag rilis** (mis. `content-v2`) atau **commit hash** agar:

- isi **permanen** (immutable) dan **selalu fresh** (di-cache aman), dan
- pembaruan terkontrol per rilis.

Hindari `@latest`/`@main` untuk file konten karena di-cache ~12 jam.

---

## Cara Memperbarui Konten (Tutorial)

Contoh: memperbaiki harakat pada Surat Al-Mulk (`jihati/26.json`).

1. **Edit file** konten terkait, mis. `jihati/26.json`. (Atau ubah `published` di `jihati/0-daftar-isi.json` untuk menampilkan/menyembunyikan entri.)
2. **Regenerasi manifest** otomatis (hash & ukuran dihitung ulang, `contentVersion` naik):
   ```bash
   python generate_manifest.py
   ```
   atau set versi & baseUrl secara eksplisit:
   ```bash
   python generate_manifest.py --version 2 --base-url "https://cdn.jsdelivr.net/gh/USERNAME/jihati-content@content-v2/"
   ```
3. **Commit** perubahan:
   ```bash
   git add .
   git commit -m "fix(26): koreksi harakat Surat Al-Mulk"
   ```
4. **Buat tag/rilis** baru:
   ```bash
   git tag content-v2
   git push origin main --tags
   ```
5. _(Opsional)_ **Purge cache jsDelivr** untuk manifest agar pembaruan langsung terbaca:
   ```
   https://purge.jsdelivr.net/gh/USERNAME/jihati-content@content-v2/manifest.json
   ```

Selesai. Aplikasi akan mendeteksi `contentVersion`/hash baru lalu mengunduh hanya file yang berubah.

---

## Konvensi Versi & Rilis

- **`contentVersion`** di `manifest.json` dinaikkan setiap publikasi (otomatis oleh `generate_manifest.py`).
- **Tag git** memakai format `content-vN` (mis. `content-v1`, `content-v2`).
- `baseUrl` pada manifest harus menunjuk ke tag yang sama dengan rilis tersebut.

---

## Integrasi dengan Aplikasi

- Aplikasi Jihati menerapkan pola **offline-first**:
  1. **Data hasil unduhan terbaru** (tersimpan lokal) → dipakai jika ada.
  2. **Aset bawaan di dalam APK** → cadangan untuk instalasi baru / saat belum pernah online.
- Internet hanya dibutuhkan **sesaat** untuk mengunduh pembaruan; setelah itu aplikasi berjalan penuh tanpa jaringan.
- Pembaruan bersifat **data saja** (sesuai kebijakan Google Play yang hanya melarang pembaruan _kode_ di luar Play).

---

## Lisensi

Konten dalam repositori ini dilisensikan di bawah **[Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)**. Anda bebas menyebarkan dan mengadaptasi dengan mencantumkan atribusi. Lihat berkas [`LICENSE`](LICENSE) untuk teks lengkap.

Ayat-ayat Al-Qur'an merupakan domain publik; atribusi berlaku untuk kurasi, transkripsi, dan penstrukturan dataset ini.
