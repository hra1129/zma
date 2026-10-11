; -----------------------------------------------------------------------------
;	test program
; -----------------------------------------------------------------------------

	org			0
start:
	if (end_label - start) < 128
		jr	end_label
	else
		jp	end_label
	endif
end_label:
	ret
