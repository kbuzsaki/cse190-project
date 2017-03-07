cursor_init:
	ld a, 7
	ld (cursor_x), a
	ld a, 2
	ld (cursor_y), a

	ld d, 7
	ld e, 2
	call cursor_get_cell_attr
	ld a, (hl)
	ld (cursor_old_attr), a
	ld (hl), 199

	ret

cursor_entry_point_handle_input:
	; load up the old cell attr vram address
	ld a, (cursor_x)
	ld d, a
	ld a, (cursor_y)
	ld e, a
	call cursor_get_cell_attr
	; put back the old attribute byte
	ld a, (cursor_old_attr)
	ld (hl), a

	; get and save the new cursor position
	call cursor_check_inputs
	call cursor_check_bounds
	ld a, d
	ld (cursor_x), a
	ld a, e
	ld (cursor_y), a

	; save the attr byte already there
	call cursor_get_cell_attr
	ld a, (hl)
	ld (cursor_old_attr), a

	; set to highlight
	ld (hl), 199
	
	ret


cursor_check_inputs:
	call input_is_w_down
	ld c, a
	ld a, e
	sub c
	ld e, a

	call input_is_s_down
	add a, e
	ld e, a

	call input_is_a_down
	ld c, a
	ld a, d
	sub c
	ld d, a

	call input_is_d_down
	add a, d
	ld d, a

	ret


cursor_check_bounds:
	; check x left wrap around
	ld a, d
	cp $ff
	jp nz, cursor_check_bounds_no_left_reset_x
	ld d, 0
cursor_check_bounds_no_left_reset_x:

	; check x right wrap around
	cp 32
	jp nz, cursor_check_bounds_no_right_reset_x
	ld d, 31
cursor_check_bounds_no_right_reset_x:

	; check y top wrap around
	ld a, e
	cp $ff
	jp nz, cursor_check_bounds_no_top_reset_y
	ld e, 0
cursor_check_bounds_no_top_reset_y:

	; check y bottom wrap around
	cp 16
	jp nz, cursor_check_bounds_no_bottom_reset_y
	ld e, 15
cursor_check_bounds_no_bottom_reset_y:

	ret


; inputs:
;  d - the x cell
;  e - the y cell
; outputs:
;  hl - the address of the attribute byte
cursor_get_cell_attr:
	ld a, d
	and $1f
	ld l, a
	ld a, e
	and $07
	rrc a
	rrc a
	rrc a
	add a, l
	ld l, a
	ld a, e
	and $18
	srl a
	srl a
	srl a
	add a, $58
	ld h, a
	ret      
