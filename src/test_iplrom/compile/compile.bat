if exist zma*.log (
	del zma*.log
)

zma.exe ../iplrom_304k_rev300.asm iplrom_304k_rev300.bin
ren zma.log zma_304k.log

zma.exe ../iplrom_512k_rev300.asm iplrom_512k_rev300.bin
ren zma.log zma_512k.log
pause
