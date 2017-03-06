; this program uses the attr cells to make a black and white display
; where a box is moved around with wasd
; it's sort of like an etchasketch

org 32768

	; setup interrupt handler, disable interrupts
	ld hl, interrupt_handler
	call setup_interrupt_handler

	; set border to green
	ld a, 4
	call 8859

	; set pixels to 0, background to white, foreground to black
	call clear_pixels
	call clear_attrs

	; set the screen to black
	;ld d, $ff
	;call fill_all_pixels

    ; set the initial tower to build
    ld a, 0
    ld (49152), a

	; draw the map from the tile map
	ld hl, tile_map
	call load_map

	ld d, 10
	ld e, 9

    call clear_status

    ld a,2              ; upper screen
    call 5633           ; open channel
    
    ld de, round       ; address of string
    ld bc, r_end-round  ; length of string to print
    call 8252           ; print our string
    
    ld de, enemy_count 
    ld bc, ec_end-enemy_count
    call 8252

    ld de, money_life
    ld bc, ml_end-money_life
    call 8252

    ld de, tower_title
    ld bc, tt_end-tower_title
    call 8252

    ld de, laser
    ld bc, l_end-laser
    call 8252

    ld a, 1
    call 5633
    ld de, bomb
    ld bc, bo_end-bomb
    call 8252

    ld de, slow
    ld bc, s_end-slow
    call 8252

    call set_status_attrs


	push bc
	push bc

	; enable interrupts again now that we're set up
	ei
	; wait for next interrupt
infinite_wait:
	jp infinite_wait

; cursor stuff
interrupt_handler:
	di

	ld a, (frame_counter)
	add 1
	ld (frame_counter), a
	and 1
	jp nz, interrupt_handler_end

	; save old coordinates
	push de

    call is_e_down
    cp 1
    call z, change_tower

	call is_r_down
	cp 1
	call z, draw_tower

	call is_w_down
    ld c, a
	ld a, e
	sub c
	ld e, a

	call is_s_down
	add a, e
	ld e, a

	call is_a_down
    ld c, a
	ld a, d
	sub c
	ld d, a

	call is_d_down
    add a, d
	ld d, a

	; check if new coords differ from old coords
	; brind old de into hl
	pop hl
	; check if h == d
	ld a, h
	sub d
	ld b, a
	; check if l == e
	ld a, l
	sub e
	or b
	; if not equal
	call nz, do_thing

    call set_flash

interrupt_handler_end:
	ei
	reti

change_tower:
    ld a, (49152)
    inc a
    ld (49152), a

draw_tower:
	push de
	call get_cell_addr
	ex de, hl
    ld a, (49152)
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

; d = x
; e = y
; hl = addr of src tile
draw_tile:
	ldi
	inc d
	dec de
	ldi
	inc d
	dec de
	ldi
	inc d
	dec de
	ldi
	inc d
	dec de
	ldi
	inc d
	dec de
	ldi
	inc d
	dec de
	ldi
	inc d
	dec de
	ldi
	inc d
	dec de
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
is_e_down:
    ld bc, $fbfe
    in b, (c)
	bit 2, b
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
	ld c, 60
wait_dur_outer_loop:
	ld b, 255
wait_dur_inner_loop:
	djnz wait_dur_inner_loop
	dec c
	jp nz, wait_dur_outer_loop
	ret

clear_status:
    ld d, 0
	call fill_all_status
	ret

fill_all_status:
	ld hl, $5000
	ld c, 8
fill_status:
fill_status_outer_loop:
	ld (hl), d
	inc hl
	ld b, 255
fill_status_inner_loop:
	ld (hl), d
	inc hl
	djnz fill_status_inner_loop
	dec c
	jp nz, fill_status_outer_loop
	ret

set_status_attrs:
	ld d, $07
	call do_set_status_attrs
	ret

; d = fill byte
do_set_status_attrs:
	ld hl, $5a00
	ld c, 3
set_status_attrs_outer_loop:
	ld (hl), d
	inc hl
	ld b, 255
set_status_attrs_inner_loop:
	ld (hl), d
	inc hl
	djnz set_status_attrs_inner_loop
	dec c
	jp nz, set_status_attrs_outer_loop
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

ignore_filler:
	defs 128

tile_map:
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	defb $00, $84, $44, $49, $00, $00, $00, $00, $00, $00, $84, $44, $44, $49, $00, $00
	defb $00, $6f, $55, $e7, $00, $00, $00, $00, $00, $00, $6f, $55, $55, $e7, $00, $00
	defb $44, $c7, $10, $67, $00, $00, $84, $44, $44, $44, $c7, $00, $00, $67, $00, $00
	defb $55, $5b, $00, $67, $00, $00, $6f, $55, $55, $55, $5b, $00, $00, $67, $00, $00
	defb $00, $00, $00, $67, $00, $00, $67, $10, $00, $00, $00, $00, $00, $67, $00, $00
	defb $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00, $01, $67, $00, $00

	defb $00, $00, $84, $c7, $00, $00, $6d, $49, $00, $00, $84, $44, $44, $c7, $00, $00
	defb $00, $00, $6f, $5b, $00, $00, $a5, $e7, $00, $00, $6f, $55, $55, $5b, $00, $00
	defb $00, $00, $67, $00, $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00
	defb $00, $00, $67, $10, $00, $00, $00, $67, $00, $00, $67, $00, $00, $00, $00, $00
	defb $00, $00, $6d, $44, $44, $44, $44, $c7, $00, $00, $6d, $44, $44, $44, $44, $44
	defb $00, $00, $a5, $55, $55, $55, $55, $5b, $00, $00, $a5, $55, $55, $55, $55, $55
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

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
    defw tower_basic, tower_basic_upgrade
    defw tower_bomb, tower_bomb_upgrade
    defw tower_zap, tower_zap_upgrade
    defw tower_obelisk, tower_obelisk_upgrade

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




    round:      defb 22, 16, 0,'Wave: 1'
    r_end:      equ $

    enemy_count:defb 22, 17, 0,'Enemies: 5'
    ec_end:     equ $

    money_life: defb 22, 16, 20,'$800    *10'
    ml_end:     equ $

    tower_title:defb 22, 20, 20,'Towers:'
    tt_end:     equ $

    laser:      defb 22, 21, 20,'1:Laser $100'
    l_end:      equ $

    ; Printed using channel 1, so their y offset is different
    bomb:       defb 22, 0, 20,'2:Bomb  $300'
    bo_end:     equ $

    slow:       defb 22, 1, 20,'3:Slow  $200'
    s_end:      equ $
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
