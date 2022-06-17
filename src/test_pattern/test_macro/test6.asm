LDW		macro		@r1, @r2
			if r1 == "BC"
				if r2 == "DE"
					ld	b, d
					ld	c, e
				elseif r2 == "HL"
					ld	b, h
					ld	c, l
				else
					error "Illegal operand."
				endif
			elseif r1 == "DE"
				if r2 == "BC"
					ld	d, b
					ld	e, c
				elseif r2 == "HL"
					ld	d, h
					ld	e, l
				else
					error "Illegal operand."
				endif
			elseif r1 == "HL"
				if r2 == "BC"
					ld	h, b
					ld	l, c
				elseif r2 == "DE"
					ld	h, d
					ld	l, e
				else
					error "Illegal operand."
				endif
			else
				error "Illegal operand."
			endif
		endm

		ldw		bc, de
		ldw		de, hl
		ldw		hl, bc
