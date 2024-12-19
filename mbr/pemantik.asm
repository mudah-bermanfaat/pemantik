    ; Penulis kode: Fikri Mustofa
    ; Kontak: fikrimustofa024@gmail.com

    ; /==================================*
    ; pemantik.asm - Program yang akan dieksekusi pertama kali ketika komputer
    ; dengan arsitektur x86 BIOS dinyalakan

	; Ada 4 agenda yang dikerjakan oleh program ini :
	; 1. Menyalin program ke alamat memori 0x500
	; 2. Memindahkan penunjuk alamat program saat ini ke alamat baru
	; 3. Memuat data pada LBA 34 dan 35 yang berisi program selanjutnya
	; 4. Lompat ke alamat program selanjutnya

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

	; Beritahu pengkompilasi bahwa seluruh alamat variabel dan program yang ditunjuk perlu ditambah 0x7c00
    [org 0x7c00]

	; Atur titik paling bawah stack dan penunjuk stack saat ini di alamat memori 0xFFFF 
	; (alamat 16-bit terkahir yang dapat dijangkau dan boleh dipakai)
	; Referensi: https://wiki.osdev.org/Memory_Map_(x86)
	mov bp, 0xffff
	mov sp, bp

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

	; /==================================*
	; [ AGENDA 2 ]
	; Memindahkan penunjuk alamat program saat ini ke alamat baru
	;
	; *==================================/

	; Alamat absolut tujuan lompatan. Tujuan lompatnya adalah alamat saat ini yang sedang 
	; dieksekusi (simbol $) dikurangi 0x7c00 (alamat memori lama) kemudian ditambah dengan 0x500
	; (alamat memori baru) dan ditambah 1. Tujuannya adalah agar instruksi program 
	; tetap dilanjutkan meskipun lokasi berbeda
	target_salinan_program equ $ - 0x7c00 + 0x500 + 1

	; Lompat menuju program baru
	jmp 0x0000:target_salinan_program

	; /==================================*
	; [ AGENDA 3 ]
	; Memuat data pada LBA 34 dan 35 yang berisi program selanjutnya
	;
	; *==================================/
	
	; /==================================*
	; Data sepanjang 1024 byte yang berawal pada LBA 34 akan dimuat ke memori dan diletakkan mulai
	; pada alamat 0x700 (tepat setelah program pemantik)
	; *==================================/

	; /==================================*
	; Pemuatan data dilakukan dengan menginterupsi 0x13. Sebelum pemanggilan, beberapa
	; register perlu dikonfigurasi. Register yang perlu diatur adalah
	; 1. AH    = Perintah. Harus diatur ke 0x2 untuk membaca dari drive.
	; 2. AL    = Jumlah sektor yang akan dibaca
	; 3. CH    = Bit rendah nomor silinder
	; 4. CL    = Bit 0-5 adalah nomor sektor dan bit 6-7 adalah bit tinggi nomor silinder
	; 5. DH    = Nomor head
	; 6. DL    = Nomor drive
	; 7. ES:BX = Alamat memori tujuan untuk meletakkan data
	;
	; Referensi: http://www.cs.cmu.edu/~ralf/interrupt-list
	; *==================================/

	; Matikan interupsi
	cli

	; Atur ES menjadi 0
	xor ax, ax
	mov es, ax

	; Atur BX menjadi 0x700
	mov bx, 0x700

	; Atur AH menjadi 0x2
	mov ah, 0x2

	; Atur AL menjadi 2. Jumlah sektor yang akan dibaca adalah 2 sektor
	mov al, 0x2

	; Atur silinder menjadi 0.
	mov ch, 0x0

	; Atur nomor sektor menjadi 34
	mov cl, 34

	; Atur head menjadi 0.
	mov dh, 0

	; Biarkan nomor drive sesuai bawaan. DL sudah diisi BIOS sebelum program ini dijalankan

	; Cadangkan nilai AL. Nilai AL akan berubah menjadi jumlah sektor yang terbaca setelah
	; interupsi. Mencadangkan AX sama dengan mencadangkan AH dan AL
	push ax

	; Nyalakan kembali interupsi
	sti

	; Interupsi 0x13
	int 0x13

	; /==================================*
	; Setelah interupsi, perlu pengecekan beberapa register yang menjadi data status pemuatan
	; 1. bit CF = 1 jika gagal. 0 jika berhasil
	; 2. AH     = Status
	; 3. AL     = Jumlah sektor yang berhasil terbaca
	;
	; Referensi: http://www.cs.cmu.edu/~ralf/interrupt-list
	; *==================================/

	; pulihkan nilai AL sebelumnya ke CL. CX adalah register yang tidak dipakai untuk
	; status pemuatan. Memulihkan CX sama dengan memulihkan AH sebelumnya ke CH
	; dan AL sebelumnya ke CL
	pop cx
	
	; lompat ke galat_drive jika bit CF bernilai 1
	jc galat_drive

	; Bandingkan antara nilai AL (sektor terbaca) dengan CL (jumlah sektor yang diinginkan)
	cmp al, cl

	; Lompat ke galat_drive jika kedua nilai tidak sama
	jne galat_drive

	; /==================================*
	; [ AGENDA 4 ]
	; Lompat ke alamat program selanjutnya
	;
	; *==================================/

	; Lompat ke alamat 0x700
	jmp 0:0x700

galat_drive:
	jmp $

	times 510-($-$$) db 0

	dw 0xAA55