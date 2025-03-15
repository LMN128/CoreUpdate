; LnxSpectrum ASM editor (www.ilnx.cz) 10.07.2023
	module main
//	org	32768

;Definice ESXDOSu
	include	"esxdos_def.asm"


;Před vlastním startem je potřeba mít zapnuté DivMMC, na portu g_zxi 0x10.
;To tu ale nijak neřeším...

;===========================================================================
;Načteme informace o souboru a otevřeme kanál pro čtení jeho částí
;===========================================================================
Start	

	ld	ix,(main.path_back)	;cesta k souboru.

	push	ix	;ulož dočasně PATH

;v A bude disk ze kterého chceme číst.
;64=SD0,
;65=SD1,
;"$" je Systemový (boot) disk,
;"*" je "Současný" zvolený disk (dle NMI menu). Asi nejpoužívanější.
	ld	a,"*"

;Načteme si informace o souboru
	ld	de,mbuffer	;Ukládat sem
	rst	8
	defb	F_STAT	;API File status
	pop	ix
	ret	c	;carry=soubor neexistuje, exit.
			;v A je případně kód chyby.

;Zkopírujeme velikost souboru. Pro čtení to není potřeba vědět, ale třeba
;to budeš potřebovat při Flashování FPGA.
	ld	hl,mbuffer+7	;Délka souboru (DWord)
	ld	de,FileLen
	ld	bc,3	;Délka je sice 4 bajtová, ale už 
	ldir		;3 bajty ukazují až 16 MB.

;Otevřeme soubor pro čtení
	ld	a,"*"	;stejný kód pro disk jako u infa
	ld	b,FA_READ	;flag pro File.Read
	rst	8
	defb	F_OPEN	;API otevřít kanál.
	ret	c	;chyba>> návrat, v A je případná chyba.

;Otevřeno. Uložíme číslo kanálu
	ld	(fileID),a

	ret
;===========================================================================
;Tady začíná čtení souboru, po 512 B
;===========================================================================
	ld	bc,512	;délka načítaného bloku dat

LoadBlock	ld	a,(fileID)	;S tímto kanálem budeme pracovat

	ld	ix,mbuffer	;Načteme 512 B (délka v BC) do mbufferu
	rst	8
	defb	F_READ	;API Read block
	ret	c	;carry=chyba při čtení>> v A kód chyby

;Pokud nenastala žádná chyba, v BC máme počet skutečně načtených bajtů.
;Bude to 512 s výjimkou poslední části. Ta může být i 0, pokud délka souboru
;bude dělitelná délkou bloku bezezbytku. Tuto čás opakuj tak dlouho,
;dokud délka načtených dat není cokoliv jiného než 512.

	ld	a,b	;Není poslední část dlouhá 0?
	or	c	;Pokud ano, nebudeme spracovávat. Není co.
	jr	z,Close	;>>uzavřít soubor

	push	bc	;Dočasně uložíme délku načteného bloku

;takže tady spracujeme nějak ty data na adrese mbuffer a o délce v registru BC.

;...
;...
;...

;tady jsou již data spracované, takže budeme načítat další blok.
;Před vlastním startem je potřeba mít opět zapnuté DivMMC, na portu g_zxi 0x10.
;a opět to tu neřeším.

	pop	hl	;Vrátíme do HL délku bloku

	ld	bc,512	;Délka dalších načítaných dat
	and	a	;ClearCarry
	sbc	hl,bc	;byl posledně načtený blok 512 B?
	jr	z,LoadBlock	;Ano>> načteme další část.

;Poslední blok byl menší jak 512 B, nebo dokonce 0. Znamená to že jsme na
;konci souboru. Uzavřeme kanál souboru.

Close	ld	a,(fileID)	;S tímto kanálem budeme pracovat
	rst	8	;Zavřít kanál
	defb	F_CLOSE	;Carry=chyba

;Soubor zavřený, v Carry máme stav zavírání
;Pokud není Carry, vše proběhlo OK

	ret		;Hotovo.


FileLen	defb	#3A,#15,#49	//4789;Délka souboru (3 bajtová) 

fileID	defb	0	;Kanál (ID) souboru
path	defb	"el_au.bit",0
path2	defb	"el_au_p.bit",0
path3	defb	"mb_ut_1.bit",0
path4	defb	"mb_ut_2.bit",0
path_back defw 0
mbuffer	ds	#0200	;adresa bufferu pro ukládání dat/512Bytes
read_buffer	ds	#0200	;adresa bufferu pro verify dat/512Bytes


/*

Path může být relativní nebo absolutní.

Relativní:
"slozka/soubor.bin"

Absolutní:
"/slozka/soubor.bin"

"soubor.bin" bude načítán z aktuální složky (nastavitelné třeba pomocí NMI menu)

"/soubor.bin" bude načítán z Rootu

*/

	endmodule













