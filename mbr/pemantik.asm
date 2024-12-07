	; x86_mbr.asm - Pemantik untuk arsitektur x86 BIOS
	
	; Seluruh kode di berkas ini harus berukuran 512 byte
	
	; Kode pemuat harus selesai di byte 445, karena byte berikutnya dipakai untuk
	; informasi partisi dalam struktur disk MBR
	
	; Ketika komputer baru menyala, komputer menggunakan real mode. Pada real mode, 
	; komputer menggunakan instruksi 16 - bit
	[bits 16]                    ; Memberitahu compiler agar kode assembly ini dicompile menjadi
	; kode mesin 16 - bit
	
	; Program akan diletakkan pada alamat 0x7c00
	[org 0x7c00]                 ; Atur jarak awal alamat relatif menjadi 0x7c00
	
	JARAK_AWAL_KERTAS equ 0x1000
	
	; Pada awal booting, BIOS mengatur nilai register dl dengan nomor drive yang dipakai booting
	mov [DRIVE_BOOT], dl         ; Cadangkan nilai dl ke DRIVE_BOOT
	
	; Konfigurasi tumpukan memori
	; Alamat 0x9000 berada di bagian Conventional Memory pada Real Mode
	mov bp, 0x9000               ; Atur alamat memori terbawah dari tumpukan di 0x9000
	mov sp, bp                   ; Samakan penunjuk alamat tumpukan saat ini dengan alamat tumpukan terbawah
	
	call muat_kertas             ; Panggil titik muat kertas
	
	; Kode berikut hanya dieksekusi jika terjadi kegagalan
hentikan:
	jmp $                        ; Larang CPU melanjutkan program. JALAN DI TEMPAT!!
	
	%include "pemuat_kertas.asm"
	
	DRIVE_BOOT db 0              ; Buat tempat menyimpan nomor drive yang dipakai untuk booting dengan nama DRIVE_BOOT
	
	times 510 - ($ - $$) db 0    ; Isi sisa alamat yang tidak terpakai hingga byte 510 dengan nilai 0
	
	; Agar seluruh kode di berkas ini tidak ditolak oleh BIOS, 
	; posisi byte ke - 511 dan ke - 512 harus diisi dengan 0x55 dan 0xAA
	dw 0xAA55                    ; Penanda
