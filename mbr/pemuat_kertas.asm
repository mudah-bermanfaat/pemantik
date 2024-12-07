	; Untuk memuat data, lakukan interupsi BIOS 0x13. Referensi: https: / / www.cs.cmu.edu / ~ralf / files.html, part 1, INTERRUPT.B
	
	; Sebelum melakukan interupsi, register AH, AL, CH, CL, DH, DL, dan ES:BX harus dikonfigurasi dahulu karena
	; BIOS akan menggunakan register tersebut untuk menentukan jenis operasi dan alamat mana yang datanya akan dimuat
	
muat_kertas:
	pusha                        ; Cadangkan nilai seluruh register
	
	mov ah, 0x02                 ; Register AH diisi dengan 0x02 untuk memerintahkan pemuatan data
	mov al, 0x02                 ; Register AL diatur menjadi 2 agar BIOS membaca sebanyak 2 sektor
	mov cl, 0x02                 ; Register CL diatur menjadi 2 agar BIOS membaca mulai dari sektor 2
	mov ch, 0x00                 ; Register CH diatur menjadi 0 agar BIOS membaca pada silinder 0
	mov dh, 0x00                 ; Register DH diatur menjadi 0 agar BIOS membaca pada head 0
	mov dl, [DRIVE_BOOT]         ; Register DL adalah nomor drive. Nilainya harus sama dengan drive yang dipakai untuk booting
	mov bx, JARAK_AWAL_KERTAS    ; Register BX adalah alamat RAM tempat menyimpan data yang dimuat.
	
	int 0x13                     ; Lakukan interupsi BIOS 0x13
	jc kegagalan_disk            ; Jika bit carry berisi 1, berarti terjadi kegagalan pemuatan. Lompat ke titik kegagalan_disk
	
	; Setelah pembacaan, al akan diisi oleh BIOS dengan nilai jumlah sektor yang berhasil dimuat
	cmp al, 0x02                 ; Bandingkan jumlah sektor berhasil dimuat dengan ekspektasi
	jne kegagalan_sektor         ; Jika tidak sesuai ekspektasi, lompat ke titik kegagalan_sektor
	
	popa                         ; Pulihkan nilai seluruh register saat bagian ini belum dieksekusi
	ret                          ; Kembali ke titik pemanggil
	
kegagalan_disk:
	jmp hentikan                 ; Lompat ke titik hentikan
	
kegagalan_sektor:
	jmp hentikan                 ; Lompat ke titik hentikan
