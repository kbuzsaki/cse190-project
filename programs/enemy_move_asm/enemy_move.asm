; this program uses the attr cells to make a black and white display
; where a box is moved around with wasd
; it's sort of like an etchasketch

org 32768

	; setup interrupt handler, disable interrupts
	ld hl, interrupt_handler
	call setup_interrupt_handler

	; set border to green
	ld a, 4
	out ($fe), a

	; set pixels to 0, background to white, foreground to black
	call clear_pixels
	call clear_attrs

	; set the screen to black
	ld d, $ff
	call fill_all_pixels

	; draw the map from the tile map
	ld hl, tile_map
	call load_map

	ld d, 10
	ld e, 9

;	push bc
;	push bc
;
;	ld hl, enemy_path
;	ld b, 56
;	ld c, 0
;loop_thing:
;	ld e, (hl)
;	inc hl
;	ld d, (hl)
;	inc hl
;
;	push hl
;	push bc
;	call wait_dur
;	ld hl, fat_enemy
;	call draw_tile
;	pop bc
;	pop hl
;	djnz loop_thing
;
;
;	jp end

	ld hl, enemy_path
	push hl

	; enable interrupts again now that we're set up
	ei
	; wait for next interrupt
infinite_wait:
	jp infinite_wait

; cursor stuff
interrupt_handler:
	di

	; only animate every 8th frame
	ld a, (frame_counter)
	add 1
	ld (frame_counter), a
	and $07
	jp nz, interrupt_handler_end

	; b is our index into the fat enemy array
	ld b, 0
handle_fat_enemy_loop:
	; load the position for this enemy to do checks
	ld hl, fat_enemy_array
	ld l, b
	ld a, (hl)
	; check for $fe (skip enemy)
	cp $fe
	jp z, skip_handle_enemy
	; check for $ff (end of array)
	cp $ff
	jp z, interrupt_handler_end

	; if it's not, then call handle_enemy
	push bc
	ld a, b
	call handle_enemy
	pop bc

skip_handle_enemy:
	inc b
	; repeat
	jp handle_fat_enemy_loop

	jp interrupt_handler_end

;	; get old position
;	dec hl
;	dec hl
;	ld e, (hl)
;	inc hl
;	ld d, (hl)
;	inc hl
;
;	; check if old position was end of the path
;	ld a, d
;	cp $ff
;	jp z, interrupt_handler_end
;
;	; clear old position
;	push hl
;	ld hl, blank_tile
;	call draw_tile
;	pop hl
;
;	; get new position
;	ld e, (hl)
;	inc hl
;	ld d, (hl)
;	inc hl
;
;	; check if we reached the end of the path (high byte $ff)
;	ld a, d
;	cp $ff
;	jp nz, draw_new_position
;	; if we did reach the end of the path, set border to red and abort
;	ld a, 2
;	out ($fe), a
;	jp interrupt_handler_end
;
;draw_new_position:
;	; draw new position
;	push hl
;	ld a, (frame_counter)
;	and $18
;	ld hl, fat_enemy
;	ld l, a
;	call draw_tile
;	pop hl

interrupt_handler_end:
	ei
	reti


; inputs:
;  a: the enemy's index into the enemy array
; todo: take the ticker as a param?
handle_enemy:
	ld hl, fat_enemy_array
	ld l, a
	ld (current_enemy_index), a

	; load the enemy's current position index
	; and store its next position index back
	ld a, (hl)
	inc a
	ld (hl), a
	dec a

	; load the enemy's old position in vram
	sla a
	ld hl, enemy_path
	ld l, a
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl

	; clear the enemy at its old position
	push hl
	ld hl, blank_tile
	call draw_tile
	pop hl

	; load the enemy's new position in vram
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl

	; if the enemy's new position is the end ($ff), then abort
	ld a, d
	cp $ff
	jp nz, draw_new_position
	; if we did reach the end of the path, then:
	; set position to fe so this enemy is skipped
	ld hl, fat_enemy_array
	ld a, (current_enemy_index)
	ld l, a
	ld (hl), $fe
	; set border to red, and abort
	ld a, 2
	out ($fe), a
	jp interrupt_handler_end

draw_new_position:
	; draw the enemy at its new position
	; load the frame ticker
	ld a, (frame_counter)
	and $18
	ld hl, fat_enemy
	ld l, a
	call draw_tile

	ret


draw_tower:
	push de
	call get_cell_addr
	ex de, hl
	ld a, 1
	call lookup_and_draw_tile
	pop de
	ret

do_thing:
	push de
	ex de, hl
	call set_no_flash
	pop de
	ret

set_flash:
    call get_coord
	ld a, $c0
	or (hl)
	ld (hl), a
    ret

set_no_flash:
    call get_coord
	ld a, $3f
	and (hl)
	ld (hl), a
    ret

get_coord:
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


; loads the map pointed to by hl
load_map:
	ld d, $40
	ld e, $00
	call draw_map

	; draw lower half of map
	ld d, $48
	ld e, $00
	call draw_map
	ret
	

; pointers
;   position in compressed map bits
;   position on screen
;   lookup table
;   tile to print
; loop invariants
;   hl:
draw_map:
	; de is the current position in vram
	; hl is the current byte in the map bits

draw_map_loop_body:
	push hl
	; load first 4 map bits into a
	rld
	and $0f

	push de
	call lookup_and_draw_tile
	pop de
	inc e

	pop hl
	push hl
	; load second 4 map bits into a
	rld
	and $0f

	push de
	call lookup_and_draw_tile
	pop de
	inc e

	; reload
	pop hl
	inc hl
	ld a, e
	cp $00
	jp nz, draw_map_loop_body
	ret

inf_loop:
	jp inf_loop

; a = tile code
; de = tile location in vram
lookup_and_draw_tile:
	; lookup 4 bits in offset table
	ld hl, lookup
	add a, a
	add a, l
	ld l, a

	; load tile address into hl
	push de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	pop de

	; draw the tile
	call draw_tile

	ret


draw_square:
	call get_coord
	ld (hl), 0
	ret

clear_square:
	call get_attr_coord
	ld (hl), 255
	ret

; de = addr of dest in vram
; hl = addr of src tile
draw_tile:
	push de

	; load y2, y1, y0 into a
	ld a, d
	and 7

	; calculate the number of iterations until y2, y1, y0 == 0
	ld b, a
	ld a, 7
	sub b
	jp z, end_draw_tile_loop_a
	add 1
	ld b, a
	ld c, 0

draw_tile_loop_a:
	ldi
	inc d
	dec de
	djnz draw_tile_loop_a
end_draw_tile_loop_a:

	ld a, (hl)
	ld (de), a
	inc hl

	pop de

	ld a, d
	and 7
	jp z, end_draw_tile_loop_b
	ld b, a
	xor d
	ld d, a
	ld a, e
	add 32
	ld e, a
	jp nc, skip_fix
	ld a, d
	add 8
	ld d, a
skip_fix:

draw_tile_loop_b:
	ldi
	inc d
	dec de
	djnz draw_tile_loop_b
end_draw_tile_loop_b:
	ret

; takes x and y coordinates of cell
; gets address of attribute byte for that cell
;
; read coordinates from d = x, e = y
; set address to hl
get_attr_coord:
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

; read coordinates from d = x, e = y
; set address to hl
get_cell_addr:
	ld a, e
	sla a
	sla a
	sla a
	ld e, a
	ld a, d
	sla a
	sla a
	sla a
	ld d, a
	call get_pixel_addr
	ret


; read coordinates from d = x, e = y
; set address to hl
get_pixel_addr:
	ld a, d
	and $f8
	srl a
	srl a
	srl a
	ld l, a
	ld a, e
	and $38
	sla a
	sla a
	or l
	ld l, a
	ld a, e
	and $7
	ld h, a
	ld a, e
	and $c0
	srl a
	srl a
	srl a
	add a, $40
	or h
	ld h, a
	ret

get_pixel_bit:
	ld a, d
	and $07
	jp z, get_pixel_bit_ret_one
	ld b, a
	ld a, $80
get_pixel_bit_loop:
	srl a
	djnz get_pixel_bit_loop
	ret
get_pixel_bit_ret_one:
	ld a, $80
	ret


get_attr:
	xor a
	ld h, $54
	ld l, a
	ld a, d
	srl a
	srl a
	srl a
	ld l, a
	ld a, e
	and $f8
	sla a
	sla a
	add a, l
	ld l, a
	ld a, e
	srl a
	srl a
	srl a
	srl a
	srl a
	add a, h
	ld h, a
	ret


is_w_down:
    ld bc, $fbfe
    in b, (c)
	bit 1, b
	jp z, set_a
	ld a, 0
	ret
is_r_down:
    ld bc, $fbfe
    in b, (c)
	bit 3, b
	jp z, set_a
	ld a, 0
	ret
is_a_down:
    ld bc, $fdfe
    in b, (c)
	bit 0, b
	jp z, set_a
	ld a, 0
	ret
is_s_down:
    ld bc, $fdfe
    in b, (c)
	bit 1, b
	jp z, set_a
	ld a, 0
	ret
is_d_down:
    ld bc, $fdfe
    in b, (c)
	bit 2, b
	jp z, set_a
	ld a, 0
	ret
set_a:
	ld a, 1
	ret


wait_dur:
	ld c, 255
wait_dur_outer_loop:
	ld b, 255
wait_dur_inner_loop:
	djnz wait_dur_inner_loop
	dec c
	jp nz, wait_dur_outer_loop
	ret


; d = fill byte
clear_pixels:
	ld d, 0
	call fill_all_pixels
	ret

fill_all_pixels:
	ld hl, $4000
	ld c, 24
fill_pixels:
fill_pixels_outer_loop:
	ld (hl), d
	inc hl
	ld b, 255
fill_pixels_inner_loop:
	ld (hl), d
	inc hl
	djnz fill_pixels_inner_loop
	dec c
	jp nz, fill_pixels_outer_loop
	ret


clear_attrs:
	ld d, $38
	call fill_all_attrs
	ret

; d = fill byte
fill_all_attrs:
	ld hl, $5800
	ld c, 3
fill_attrs:
fill_attrs_outer_loop:
	ld (hl), d
	inc hl
	ld b, 255
fill_attrs_inner_loop:
	ld (hl), d
	inc hl
	djnz fill_attrs_inner_loop
	dec c
	jp nz, fill_attrs_outer_loop
	ret


; Address space wrap-around interrupt handler discussed in class
; Code adapted from:
; http://www.animatez.co.uk/computers/zx-spectrum/interrupts/
; Uses the address in hl as the interrupt handler
setup_interrupt_handler:
    di                         ; disable interrupts
    ld ix, $FFF0               ; Where to stick this code
    ld (ix + $4), $C3          ; Z80 opcode for JP
    ld (ix + $5), l            ; Where to JP to (in HL)
    ld (ix + $6), h
    ld (ix + $F), $18          ; Z80 Opcode for JR
    ld a, $39                  ; High byte address of vector table
    ld i, a                    ; Set I register to this
    im 2                       ; Set Interrupt Mode 2
	ret

frame_counter:
	defb 0

; pixel address:
; [0, 1, 0, y7,  y6, y2, y1, y0] [y5, y4, y3, x7,  x6, x5, x4, x3]
;
; attr address
; [0, 1, 0,  1,  1,  0, y7, y6] [y5, y4, y3, x7, x6, x5, x4, x3]

; filler padding for alignment
; enemy data
defs $9000 - $

enemy_path:
	defw $0000
	defw $40a0, $40a1, $40a2, $40a3, $40a4, $40c4, $40e4, $4804
	defw $4824, $4825, $4826, $4827, $4828, $4829, $482a, $482b
	defw $480b, $40eb, $40cb, $40ab, $408b, $406b, $406c, $406d
	defw $406e, $406f, $4070, $4071, $4072, $4073, $4093, $40b3
	defw $40d3, $40f3, $4813, $4833, $4853, $4873, $4893, $4894
	defw $4895, $4896, $4897, $4898, $4899, $489a, $489b, $487b
	defw $485b, $483b, $481b, $40fb, $40fc, $40fd, $40fe, $40ff
	defw $ffff

current_enemy_index:
	defb $00

defs $9100 - $

; enemy positions
fat_enemy_array:
	defb $00
	defb $02
	defb $04
	defb $08
	defb $10
	defb $ff

; tiles and sprites
defs $a000 - $

tile_map:
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	defb $00, $00, $00, $00, $00, $84, $44, $44, $44, $44, $90, $00, $00, $00, $00, $00
	defb $00, $00, $00, $00, $00, $60, $00, $00, $00, $00, $70, $00, $00, $00, $00, $00
	defb $44, $44, $49, $00, $00, $60, $f5, $55, $55, $e0, $70, $00, $00, $00, $00, $00
	defb $00, $00, $07, $00, $00, $60, $70, $00, $00, $60, $70, $00, $00, $00, $00, $00
	defb $55, $5e, $07, $00, $00, $60, $70, $00, $00, $60, $70, $00, $00, $84, $44, $44
	defb $00, $06, $07, $00, $00, $60, $70, $00, $00, $60, $70, $00, $00, $60, $00, $00

	defb $00, $06, $0d, $44, $44, $c0, $70, $00, $00, $60, $70, $00, $00, $60, $f5, $55
	defb $00, $06, $00, $00, $00, $00, $70, $00, $00, $60, $70, $00, $00, $60, $70, $00
	defb $00, $0a, $55, $55, $55, $55, $b0, $00, $00, $60, $70, $00, $00, $60, $70, $00
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $60, $d4, $44, $44, $c0, $70, $00
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $60, $00, $00, $00, $00, $70, $00
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $a5, $55, $55, $55, $55, $b0, $00
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	defb $00, $84, $44, $49, $00, $00, $00, $00, $00, $00, $84, $44, $44, $49, $00, $00
;	defb $00, $6f, $55, $e7, $00, $00, $00, $00, $00, $00, $6f, $55, $55, $e7, $00, $00
;	defb $44, $c7, $10, $67, $00, $00, $84, $44, $44, $44, $c7, $00, $00, $67, $00, $00
;	defb $55, $5b, $00, $67, $00, $00, $6f, $55, $55, $55, $5b, $00, $00, $67, $00, $00
;	defb $00, $00, $00, $67, $00, $00, $67, $10, $00, $00, $00, $00, $00, $67, $00, $00
;	defb $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00, $01, $67, $00, $00
;
;	defb $00, $00, $84, $c7, $00, $00, $6d, $49, $00, $00, $84, $44, $44, $c7, $00, $00
;	defb $00, $00, $6f, $5b, $00, $00, $a5, $e7, $00, $00, $6f, $55, $55, $5b, $00, $00
;	defb $00, $00, $67, $00, $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00
;	defb $00, $00, $67, $10, $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00
;	defb $00, $00, $6d, $44, $44, $44, $44, $c7, $00, $00, $6d, $44, $44, $44, $44, $44
;	defb $00, $00, $a5, $55, $55, $55, $55, $5b, $00, $00, $a5, $55, $55, $55, $55, $55
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	defb $00, $84, $44, $49, $00, $00, $00, $00, $00, $00, $84, $44, $44, $49, $00, $00
;	defb $00, $6f, $55, $e7, $00, $00, $00, $00, $00, $00, $6f, $55, $55, $e7, $00, $00
;	defb $44, $c7, $00, $67, $00, $00, $84, $44, $44, $44, $c7, $00, $00, $67, $00, $00
;	defb $55, $5b, $00, $67, $00, $00, $6f, $55, $55, $55, $5b, $00, $00, $67, $00, $00
;	defb $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00, $00, $67, $00, $00
;	defb $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00, $00, $67, $00, $00
;
;	defb $00, $00, $84, $c7, $00, $00, $6d, $49, $00, $00, $84, $44, $44, $c7, $00, $00
;	defb $00, $00, $6f, $5b, $00, $00, $a5, $e7, $00, $00, $6f, $55, $55, $5b, $00, $00
;	defb $00, $00, $67, $00, $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00
;	defb $00, $00, $67, $00, $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00
;	defb $00, $00, $6d, $44, $44, $44, $44, $c7, $00, $00, $6d, $44, $44, $44, $44, $44
;	defb $00, $00, $a5, $55, $55, $55, $55, $5b, $00, $00, $a5, $55, $55, $55, $55, $55
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00


;
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	defb $00, $84, $44, $49, $00, $00, $00, $00, $00, $00, $84, $44, $44, $49, $00, $00
;	defb $00, $6f, $55, $e7, $00, $00, $00, $00, $00, $00, $6f
;
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;
;old_tile_map:
;	defb $02, $03, $12, $13, $23, $01, $01, $01
;	defb $11, $11, $11, $11, $11, $11, $11, $11
;
;	defb $01, $02, $03, $12, $13, $23, $01, $01
;	defb $11, $11, $11, $11, $11, $11, $11, $11
;
;	defb $01, $01, $02, $03, $12, $13, $23, $01
;	defb $11, $11, $11, $11, $11, $11, $11, $11
;
;	defb $01, $01, $01, $02, $03, $12, $13, $23
;	defb $11, $11, $11, $11, $11, $11, $11, $11
;
;	defb $01, $01, $01, $02, $03, $12, $13, $23
;	defb $11, $11, $11, $11, $11, $11, $11, $11
;
;	defb $01, $01, $02, $03, $12, $13, $23, $01
;	defb $11, $11, $11, $11, $11, $11, $11, $11
;
;	defb $01, $02, $03, $12, $13, $23, $01, $01
;	defb $11, $11, $11, $11, $11, $11, $11, $11
;
;	defb $02, $03, $12, $13, $23, $01, $01, $01
;	defb $11, $11, $11, $11, $11, $11, $11, $11
;

lookup:
	defw blank_tile, dot_tile, circle_tile, cross_tile
	defw top_wall, bottom_wall, left_wall, right_wall
	defw top_left_corner, top_right_corner, bottom_left_corner, bottom_right_corner
	defw top_left_nub, top_right_nub, bottom_left_nub, bottom_right_nub

old_lookup:
	defw some_tile, blank_tile, cross_tile, circle_tile

blank_tile:
	defb $00, $00, $00, $00, $00, $00, $00, $00

some_tile:
	defb $ff, $81, $81, $99, $99, $81, $81, $ff

cross_tile:
	defb $c3, $66, $3c, $18, $18, $3c, $66, $c3

circle_tile:
	defb $3c, $66, $c3, $81, $81, $c3, $66, $3c

dot_tile:
	defb $00, $3c, $7e, $7e, $7e, $7e, $3c, $00

;	defb $81, $c3, $66, $3c, $3c, $66, $c3, $81


top_wall:
	defb 44, 219, 0, 0, 0, 0, 0, 0
bottom_wall:
	defb 0, 0, 0, 0, 0, 0, 219, 44
left_wall:
	defb 128, 64, 64, 64, 128, 128, 64, 64
right_wall:
	defb 2, 2, 1, 1, 2, 2, 2, 1

top_left_corner:
	defb 102, 153, 144, 128, 64, 128, 128, 64
top_right_corner:
	defb 152, 100, 6, 1, 2, 2, 2, 1
bottom_left_corner:
	defb 64, 128, 128, 64, 128, 144, 153, 102
bottom_right_corner:
	defb 1, 2, 2, 2, 1, 6, 100, 152

top_left_nub:
	defb 64, 128, 0, 0, 0, 0, 0, 0
top_right_nub:
	defb 2, 1, 0, 0, 0, 0, 0, 0
bottom_left_nub:
	defb 0, 0, 0, 0, 0, 0, 128, 64
bottom_right_nub:
	defb 0, 0, 0, 0, 0, 0, 1, 2

tower_basic:
    defb 90     ;     # ## #
    defb 255    ;    ########
    defb 126    ;     ######
    defb 60     ;      ####
    defb 60     ;      ####
    defb 60     ;      ####
    defb 60     ;      ####
    defb 60     ;      ####

tower_basic_upgrade:
    defb 165    ;    # #  # #
    defb 255    ;    ########
    defb 219    ;    ## ## ##
    defb 255    ;    ########
    defb 126    ;     ######
    defb 60     ;      ####
    defb 60     ;      ####
    defb 60     ;      ####

tower_bomb:
    defb 255    ;    ########
    defb 129    ;    #      #
    defb 153    ;    #  ##  #
    defb 165    ;    # #  # #
    defb 165    ;    # #  # #
    defb 153    ;    #  ##  #
    defb 129    ;    #      #
    defb 255    ;    ########

tower_bomb_upgrade:
    defb 60     ;      ####
    defb 36     ;      #  #
    defb 219    ;    ## ## ##
    defb 165    ;    # #  # #
    defb 165    ;    # #  # #
    defb 219    ;    ## ## ##
    defb 36     ;      #  #
    defb 60     ;      ####

tower_zap:
    defb 60     ;      ####
    defb 66     ;     #    #
    defb 66     ;     #    #
    defb 60     ;      ####
    defb 24     ;       ##
    defb 24     ;       ##
    defb 24     ;       ##
    defb 24     ;       ##

tower_zap_upgrade:
    defb 126    ;     ######
    defb 129    ;    #      #
    defb 129    ;    #      #
    defb 129    ;    #      #
    defb 126    ;     ######
    defb 60     ;      ####
    defb 24     ;       ##
    defb 24     ;       ##

tower_obelisk:
    defb 24     ;       ##   
    defb 60     ;      ####  
    defb 60     ;      ####  
    defb 60     ;      ####  
    defb 60     ;      ####  
    defb 126    ;     ###### 
    defb 255    ;    ########
    defb 255    ;    ########

tower_obelisk_upgrade:
    defb 60     ;      #### 
    defb 36     ;      #  #  
    defb 102    ;     ##  ## 
    defb 66     ;     #    # 
    defb 66     ;     #    # 
    defb 66     ;     #    # 
    defb 195    ;    ##    ##
    defb 255    ;    ########

lightning:
    defb 3      ;          ##
    defb 14     ;        ###
    defb 56     ;      ###
    defb 254    ;    #######
    defb 127    ;     #######
    defb 28     ;       ###
    defb 122    ;     ###
    defb 192    ;    ##

dollar:
    defb 36     ;      #  #
    defb 126    ;     ######
    defb 165    ;    # #  # #
    defb 116    ;     ### #
    defb 46     ;      # ###
    defb 165    ;    # #  # #
    defb 126    ;     ######
    defb 36     ;      #  #

heart:
    defb 102    ;     ##  ##
    defb 255    ;    ########
    defb 255    ;    ########
    defb 255    ;    ########
    defb 126    ;     ######
    defb 60     ;      ####
    defb 24     ;       ##
    defb 0      ;

heart_hollow:
    defb 102    ;     ##  ##
    defb 154    ;    #  ##  #
    defb 129    ;    #      #
    defb 129    ;    #      #
    defb 66     ;     #    #
    defb 36     ;      #  #
    defb 24     ;       ##
    defb 0      ;

bullet:
    defb 24     ;       ##
    defb 60     ;      ####
    defb 126    ;     ######
    defb 126    ;     ######
    defb 126    ;     ######
    defb 126    ;     ######
    defb 0      ;
    defb 126    ;     ######

bullet_hollow:
    defb 24     ;       ##
    defb 36     ;      #  #
    defb 66     ;     #    #
    defb 66     ;     #    #
    defb 66     ;     #    #
    defb 126    ;     ######
    defb 0      ;
    defb 126    ;     ######

; pad so enemy sprites are aligned
defs $b000 - $

fat_enemy:
	defb $3c    ;   ####  
	defb $5a    ;  # ## # 
	defb $ff    ; ########
	defb $e7    ; ###  ###
	defb $db    ; ## ## ##
	defb $ff    ; ########
	defb $7e    ;  ###### 
	defb $e7    ; ###  ###
	defb $3c    ;   ####  
	defb $5a    ;  # ## # 
	defb $ff    ; ########
	defb $e7    ; ###  ###
	defb $db    ; ## ## ##
	defb $fe    ; ####### 
	defb $7f    ;  #######
	defb $e0    ; ###     
	defb $3c    ;   ####  
	defb $5a    ;  # ## # 
	defb $ff    ; ########
	defb $e7    ; ###  ###
	defb $db    ; ## ## ##
	defb $ff    ; ########
	defb $7e    ;  ###### 
	defb $e7    ; ###  ###
	defb $3c    ;   ####  
	defb $5a    ;  # ## # 
	defb $ff    ; ########
	defb $e7    ; ###  ###
	defb $db    ; ## ## ##
	defb $7f    ;  #######
	defb $fe    ; ####### 
	defb $07    ;      ###

; ################
; #   ######    ##
;   # ##     ## ##
; ### ## ###### ##
; ##  ##  ##    ##
; ## #### ## #####
; ##      ##      
; ################

;[[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
; [0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0],
; [1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0],
; [0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0],
; [0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0],
; [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0],
; [0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1],
; [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]

end:
