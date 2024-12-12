    ; Penulis kode: Fikri Mustofa
    ; Kontak: fikrimustofa024@gmail.com

    ; /==================================*
    ; pemantik.asm - Program yang akan dieksekusi pertama kali ketika komputer
    ; dengan arsitektur x86 BIOS dinyalakan

	; Ada 4 agenda yang dikerjakan oleh program ini :
	; 1. Menyalin program ke alamat memori 0x500
	; 2. Memindahkan penunjuk alamat program saat ini ke alamat baru
	; 3. Memuat data pada LBA 34 dan 35 yang berisi program selanjutnya
	; 4. Memindahkan penunjuk alamat program saat ini ke program selanjutan

    ; Hasil kompilasi dari program ini harus berukuran 512 byte, mengikuti format dari MBR
    ; Referensi: https://wiki.osdev.org/MBR_(x86)#MBR_Bootstrap

    ; Kode program harus selesai di byte 439, karena byte berikutnya dipakai untuk
    ; tanda tangan dan informasi partisi dalam struktur disk MBR

    ; Ketika komputer baru menyala, komputer menggunakan mode real. Saat mode real dijalankan,
    ; komputer menggunakan instruksi dan sistem pengalamatan 16 bit
    ; *==================================/

    ; Beri tahu pengkompilasi agar kode setelah baris ini dikompilasi dalam kode mesin 16 bit
    [bits 16]

	; /==================================*
    ; Sebelum program ini bisa dieksekusi oleh prosesor, program ini harus terletak pada RAM.
    ; BIOS akan meletakkan program ini pada RAM dengan titik awal pada alamat 0x7c00. Kemudian prosesor akan mengeksekusi
	; program ini mulai dari alamat 0x7c00.
	; *==================================/

	; Beritahu pengkompilasi bahwa seluruh alamat memori absolut yang ditunjuk perlu ditambah 0x7c00
    [org 0x7c00]

	; /==================================*
	; [ AGENDA 1 ]
	; Menyalin program ke alamat memori 0x500
	;
	; Tujuannya adalah agar titik awal dari program bisa dipindahkan ke titik awal memori yang boleh dipakai, yaitu 0x500. 
	; Pada mode real, alamat memori yang boleh dipakai adalah antara 0x500 s.d. 0x7FFFF. Pemindahan titik awal ini akan menambah
	; ruang memori yang tersedia setelah program ini.
	;
	; Penyalinan dilakukan dengan perintah MOVSW. MOVSW akan menyalin data sebanyak 2 byte dari memori yang ditunjuk oleh
	; register DS:SI ke memori yang ditunjuk oleh register ES:DI. Setelah itu, masing-masing penunjuk akan ditambah 2
	; atau dikurangi 2 secara otomatis sesuai dengan konfigurasi bit DF pada EFLAGS.
	; Referensi: Intel® 64 and IA-32 Architectures Software Developer’s Manual halaman 4-121
	; *==================================/

	; Matikan interupsi agar tidak mengganggu konfigurasi
	cli

    ; /==================================*
	; Atur DS:SI menjadi 0x0:0x7c00
	; *==================================/

	; /==================================*
	; DS adalah register segmen. Register segmen tidak dapat diatur secara langsung.
	; Teknik mengaturnya adalah dengan mengatur ke register AX. Kemudian nilai dari AX disalin ke DS
	; *==================================/

	; Mengatur nilai AX menjadi 0. XOR bilangan yang sama menyebabkan angka 0
	xor ax, ax

	; salin nilai ax ke ds
	mov ds, ax

	; atur nilai si menjadi 0x7c00
	mov si, 0x7c00

	; /==================================*
	; Atur ES:DI menjadi 0x0:0x500
	; *==================================/

	; /==================================*
	; ES adalah register segmen. Metode mengaturnya juga dengan meletakkan nilai pada register AX.
	; Kemudian menyalinnya ke ES
	; *==================================/

	; salin nilai ax ke es
	mov es, ax

	; atur nilai di menjadi 0x500
	mov di, 0x500

	; Nyalakan kembali interupsi
	sti

	; /==================================*
	; Agar tidak menuliskan MOVSW 256 kali, lebih baik menggunakan perulangan. Perulangan dilakukan dengan
	; perintah REPNZ. REPNZ akan mengulang eksekusi hingga register CX bernilai 0 atau bit ZF pada register EFLAGS 
	; bernilai 1. 
	;
	; MOVSW perlu dieksekusi 256 kali karena setiap eksekusi menyalin data sebanyak 2 byte. 
	; Program ini harus berukuran 512 byte. Sehingga MOVSW 256 kali akan menyalin program ini secara utuh.
	; *==================================/
	
	; Matikan bit DF agar arah penyalinannya menaik setelah eksekusi MOVSW. Ini akan mengakibatkan register DS:SI dan ES:DI
	; ditambah 2 setiap pemanggilan MOVSW
	cld

	; Atur nilai cx menjadi 0x100. 0x100 jika didesimalkan adalah 256. Ini akan mengakibatkan pemanggilan MOVSW sebanyak
	; 256 kali.
	mov cx, 0x100

	; Bandingan 2 register yang nilainya tidak sama untuk memicu diaturnya nilai 0 pada bit ZF oleh prosesor
	cmp ax, di

	; Ulangi perintah berikutnya hingga register CX = 0 atau bit ZF = 1
	REPNZ

	; Salin program
	MOVSW

