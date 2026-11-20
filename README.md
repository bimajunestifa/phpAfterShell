# phpAfterShell Lab (CVE-2026-126714)

Lab reproduksi lokal untuk mekanisme bug **phpAfterShell**: race condition di handler session file PHP. Worker yang mati di tengah `pwrite()` meninggalkan ekor data lama di file session; ekor itu bisa kebaca sebagai objek serialized saat `session_start()` berikutnya, berujung RCE jika ada gadget chain.

Author: **Cotab1mzz**

## Status

| Variann | Deterministik? | Catatan |
|--------|----------------|---------|
| Lab lokal (interrupt agent) | Ya | Worker di-`kill -9` presisi mid-write |
| Remote HTTP murni (`remote_race.py`) | Tidak | Tergantung OOM/timeout kill; PoC referensi pun mencatat cut point belum stabil |

## Quickstart

```bash
git clone https://github.com/<you>/phpAfterShell-lab
cd phpAfterShell-lab
docker compose up --build -d
docker compose logs -f interrupt
```

Cek target hidup:

```bash
curl -s http://localhost:8080/index.php
```

Jalanin exploit deterministik:

```bash
cd exploit
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python3 lab_exploit.py http://localhost:8080
```

Output sukses:

```
[+] RCE CONFIRMED
OUT:uid=33(www-data) gid=33(www-data) groups=33(www-data)
HOST:abc123def456
TIME:1763600000
```

## Tiga bukti temuan

1. **Marker file** — `/tmp/pwned_<id>.txt` berisi `uid=33(www-data)` + hostname + timestamp.
2. **Log agent** — `docker compose logs interrupt` menampilkan `KILLED pid=... size=...`.
3. **Isi file session** — `docker compose exec web cat /var/lib/php/sessions/sess_<id>` menunjukkan prefix baru + ekor gadget.

## Struktur

| Path | Fungsi |
|------|--------|
| `php/src/gadget.php` | gadget demo (`Logger::__destruct`) |
| `php/src/upload.php` | endpoint `session.upload_progress` |
| `php/src/index.php` | entry point, trigger `session_start()` |
| `php/src/marker.php` | verifikasi output RCE via HTTP |
| `interrupt/agent.sh` | kill worker mid-write (kunci determinisme) |
| `exploit/banner.py` | banner bersama |
| `exploit/lab_exploit.py` | exploit end-to-end deterministik |
| `exploit/remote_race.py` | varian probabilistik untuk target nyata |

## Batasan

- Gadget chain `Logger` hanya ada di lab ini. Di target nyata, ganti dengan chain dari library target (phpggc atau source manual).
- `session.upload_progress.cleanup=Off` di lab bikin ekor payload bertahan. Target nyata default `On` — race harus lebih agresif.
- Varian rentan: PHP 8.2.0–8.2.35, 8.3.0–8.3.36, 8.4.0–8.4.27, 8.5.0–8.5.12, dengan `session.save_handler=files`.

## Catatan Penulis

Kode dan lab ini dibuat untuk **tujuan pembelajaran**—memahami mekanisme bug
phpAfterShell secara langsung, bukan sekadar baca teori. Semua yang ada di sini
ditujukan untuk dijalankan di lingkungan lokal yang lo kontrol sendiri.

Mohon maaf kalau ada bagian kode yang salah, kurang tepat, atau kurang jelas.
Ini adalah upaya terbaik saya untuk memetakan mekanisme bug secara jujur,
termasuk batasan dan ketidakpastiannya. Kalau lo menemukan kesalahan, typo,
atau langkah yang nggak jalan, silakan buka issue atau kirim pull request—
saya akan revisi.

**Yang penting dipahami sebelum menjalankan kode ini:**

- Lab ini sengaja rentan. Jangan pernah menjalankannya di server yang terbuka
  ke internet atau server produksi, bahkan untuk "tes sebentar". Container
  yang sengaja rentan bisa dipindai dan dieksploitasi oleh orang lain.
- Kalau lo mengadaptasi kode ini untuk target nyata, pastikan lo punya izin
  tertulis dari pemilik sistem. Tanpa izin, itu tindakan ilegal di hampir
  semua yurisdiksi—dan akibatnya bisa merugikan orang lain, termasuk lo
  sendiri.
- Kode ini bukan senjata yang siap pakai. Di target nyata, gadget chain
  `Logger` nggak akan ke-load, dan lo harus membangun chain sendiri dari
  library target. Lab ini menunjukkan mekanismenya, bukan menyediakan tool
  serangan siap tembak.
- Kalau ada bagian yang menyesatkan, kurang akurat, atau bisa disalahgunakan
  karena kurangnya penjelasan, itu tanggung jawab saya untuk memperbaikinya.
  Silakan beri tahu.

Terima kasih sudah membaca sampai sini. Semoga lab ini membantu lo memahami
bug ini lebih dalam—dan semoga pemahaman itu dipakai dengan bertanggung jawab.

## Troubleshooting

**Marker nggak muncul:**

```bash
docker compose logs interrupt                  # cek agent kill
docker compose exec web ls -l /var/lib/php/sessions
docker compose exec web cat /var/lib/php/sessions/sess_<SID>
```

Kalau agent nggak pernah kill, turunin `SESSION_THRESHOLD`:

```yaml
environment:
  - SESSION_THRESHOLD=50000
```

**Port 8080 bentrok:**

```yaml
ports:
  - "8090:80"
```

**Apache 500 di upload.php:**

```bash
docker compose exec web tail -50 /var/log/apache2/error.log
```

## Referensi

- CVE-2026-126714 (phpAfterShell) — NVD: https://nvd.nist.gov/vuln/detail/CVE-2026-126714
- Advisory PHP resmi untuk session handler fix
- phpggc — https://github.com/ambionics/phpggc
- Dokumentasi PHP `session.upload_progress` — https://www.php.net/manual/en/session.upload-progress.php
- Dokumentasi PHP `session.save_handler` — https://www.php.net/manual/en/session.configuration.php
