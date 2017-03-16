powerups_init:

    ; do not init a powerup if its value is $ff
    ld a, (powerup_one)
    cp $ff
    jp z, powerups_init_skip_one

    ld a, (powerup_one_x)
    sub 1
    ld d, a
    ld a, (powerup_one_y)
    sub 1
    ld e, a

    ld hl, lake_3x3
    ld b, 3
    ld c, 3
    call util_draw_image

  powerups_init_skip_one:
    
    ld a, (powerup_two)
    cp $ff
    jp z, powerups_init_skip_two

    ld a, (powerup_two_x)
    sub 1
    ld d, a
    ld a, (powerup_two_y)
    sub 2
    ld e, a

    ld hl, lake_3x5
    ld b, 3
    ld c, 5
    call util_draw_image


  powerups_init_skip_two:

    ld a, (powerup_three)
    cp $ff
    jp z, powerups_init_skip_three

    ld a, (powerup_three_x)
    sub 2
    ld d, a
    ld a, (powerup_three_y)
    sub 1
    ld e, a

    ld hl, lake_5x3
    ld b, 5
    ld c, 3
    call util_draw_image

  powerups_init_skip_three:
    ret

powerups_spawn_randomly:

    ; skip chance to spawn powerup_one if it exists already
    ld a, (powerup_one)
    cp 0
    jp nz, powerups_spawn_randomly_skip_one

    ; skip chance to spawn if cursor is on powerup_one spot
    ld a, (cursor_x)
    ld b, a
    ld a, (powerup_one_x)
    cp b
    jp nz, powerups_spawn_randomly_spawn_one 

    ld a, (cursor_y)
    ld b, a
    ld a, (powerup_one_y)
    cp b
    jp z, powerups_spawn_randomly_skip_one 

  powerups_spawn_randomly_spawn_one:

    ld a, r
    and $aa
    call z, powerups_spawn_powerup_one

  powerups_spawn_randomly_skip_one:

    ; skip chance to spawn powerup_two if it exsts already
    ld a, (powerup_two)
    cp 0
    jp nz, powerups_spawn_randomly_skip_two

    ;skip chance to spawn if cursor is on powerup_two spot
    ld a, (cursor_x)
    ld b, a
    ld a, (powerup_two_x)
    cp b
    jp nz, powerups_spawn_randomly_spawn_two 

    ld a, (cursor_y)
    ld b, a
    ld a, (powerup_two_y)
    cp b
    jp z, powerups_spawn_randomly_skip_two 

  powerups_spawn_randomly_spawn_two:

    ld a, r
    and $bb
    call z, powerups_spawn_powerup_two

  powerups_spawn_randomly_skip_two:

    ; skip chance to spawn powerup_two if it exsts already
    ld a, (powerup_three)
    cp 0
    jp nz, powerups_spawn_randomly_skip_three

    ;skip chance to spawn if cursor is on powerup_two spot
    ld a, (cursor_x)
    ld b, a
    ld a, (powerup_three_x)
    cp b
    jp nz, powerups_spawn_randomly_spawn_three

    ld a, (cursor_y)
    ld b, a
    ld a, (powerup_three_y)
    cp b
    jp z, powerups_spawn_randomly_skip_three

  powerups_spawn_randomly_spawn_three:

    ld a, r
    and $cc
    call z, powerups_spawn_powerup_three

  powerups_spawn_randomly_skip_three:

    ret

powerups_spawn_powerup_one:
    ld bc, powerup_one
    ld a, (powerup_one_x)
    ld d, a
    ld a, (powerup_one_y)
    ld e, a
    call powerups_spawn_powerup

    ret

powerups_spawn_powerup_two:
    ld bc, powerup_two
    ld a, (powerup_two_x)
    ld d, a
    ld a, (powerup_two_y)
    ld e, a
    call powerups_spawn_powerup

    ret
   
powerups_spawn_powerup_three:
    ld bc, powerup_three
    ld a, (powerup_three_x)
    ld d, a
    ld a, (powerup_three_y)
    ld e, a
    call powerups_spawn_powerup

    ret 

; bc = address of powerup_one or powerup_two
; d = x for powerup cell
; e = y for powerup cell
powerups_spawn_powerup:
    ; the lower bits seem to be more random than upper bits
    ld a, r
    rr a
    rr a
    rr a

    sub 30
    jp pe, powerups_spawn_slow
    
    sub 30
    jp pe, powerups_spawn_bomb

    sub 30
    jp pe, powerups_spawn_zap 
    
    sub 30
    jp pe, powerups_spawn_money

  powerups_spawn_life:
    ld hl, heart
    ld a, $01 ; set the powerup to be the value for the health powerup
    ld (bc), a
    ld c, $0a ; desired attr byte value
    jp powerups_spawn_draw

  powerups_spawn_money:
    ld hl, dollar
    ld a, $02 ; set the powerup to be the value for the money powerup
    ld (bc), a
    ld c, $0c ; desired attr byte value
    jp powerups_spawn_draw

  powerups_spawn_zap:
    ld hl, lightning
    ld a, $03
    ld (bc), a
    ld c, $0e
    jp powerups_spawn_draw

  powerups_spawn_bomb:
    ld hl, bomb
    ld a, $04
    ld (bc), a
    ld c, $08
    jp powerups_spawn_draw

  powerups_spawn_slow:
    ld hl, snowflake
    ld a, $05
    ld (bc), a
    ld c, $0d
    jp powerups_spawn_draw

  powerups_spawn_draw:
    push hl
    call cursor_get_cell_attr
    ld (hl), c
    pop hl

    push hl
    call cursor_get_cell_addr
    ex de, hl
    pop hl
    call util_draw_tile

    ret

; bc = address of powerup_one or powerup_two
; d = x for powerup cell
; e = y for powerup cell
powerups_clear_powerup:
    ld a, 0
    ld (bc), a

    call cursor_get_cell_addr
    ex de, hl
    ld hl, blank_tile
    call util_draw_tile
    ret

; bc = address of powerup_one or powerup_two
; d = x for powerup cell
; e = y for powerup cell
powerups_get_powerup:
    ld a, (bc)

    cp $01
    call z, powerups_get_health

    cp $02
    call z, powerups_get_money

    cp $03
    call z, powerups_get_zap

    cp $04
    call z, powerups_get_bomb

    cp $05
    call z, powerups_get_slow

    ret


powerups_get_health:
    call status_inc_health
    call powerups_clear_powerup
    ret

powerups_get_money:
    push bc
    ld b, 0
    ld c, 1
    call status_add_money
    pop bc
    call powerups_clear_powerup
    ret

powerups_get_zap:
    push de
    call status_inc_zap
    pop de
    call powerups_clear_powerup
    ret

powerups_get_bomb:
    push de
    call status_inc_bomb
    pop de
    call powerups_clear_powerup
    ret

powerups_get_slow:
    push de
    call status_inc_slow
    pop de
    call powerups_clear_powerup
    ret

powerups_use_zap:
	; try to dec a charge, give up if we can't
    call status_dec_zap
	cp 0
	ret z

	; flash the path
	ld b, $75
	call load_map_set_path_attr_bytes

	; damage all of the enemies
	; todo: maybe queue up the zap again so it flashes and then does damage?

    ret

powerups_use_bomb:
	; try to dec a charge, give up if we can't
    call status_dec_bomb
	cp 0
	ret z

	; todo: validate coords, actually make this do something
	; paint the bomb
	ld a, (cursor_x)
	ld d, a
	ld a, (cursor_y)
	ld e, a
	call cursor_get_cell_addr
	ex de, hl
	ld hl, bomb
	call util_draw_tile

    ret

powerups_use_slow:
	; try to dec a charge, give up if we can't
    call status_dec_slow
	cp 0
	ret z

	; todo: actually make this do something

    ret

