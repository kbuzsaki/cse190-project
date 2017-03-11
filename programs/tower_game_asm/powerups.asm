powerups_init:
    call powerups_prepare_powerups_map_b

    ret

powerups_spawn_randomly:

    ; skip chance to spawn powerup_one if it exists already
    ld a, (powerup_one)
    cp 0
    jp nz, powerups_spawn_randomly_skip_one

    ; skip chance to spawn if cursor is on powerup_one spot
    ld a, (cursor_x)
    ld a, b
    ld a, (powerup_one_x)
    cp b
    jp nz, powerups_spawn_randomly_spawn_one 

    ld a, (cursor_y)
    ld a, b
    ld a, (powerup_one_y)
    cp b
    jp z, powerups_spawn_randomly_skip_one 

  powerups_spawn_randomly_spawn_one:

    ld a, r
    and $11
    call z, powerups_spawn_powerup_one

  powerups_spawn_randomly_skip_one:

    ; skip chance to spawn powerup_two if it exsts already
    ld a, (powerup_two)
    cp 0
    jp nz, powerups_spawn_randomly_skip_two

    ;skip chance to spawn if cursor is on powerup_two spot
    ld a, (cursor_x)
    ld a, b
    ld a, (powerup_two_x)
    cp b
    jp nz, powerups_spawn_randomly_spawn_two 

    ld a, (cursor_y)
    ld a, b
    ld a, (powerup_two_y)
    cp b
    jp z, powerups_spawn_randomly_skip_two 

  powerups_spawn_randomly_spawn_two:


    ld a, r
    and $22
    call z, powerups_spawn_powerup_two

  powerups_spawn_randomly_skip_two:

    ret


powerups_prepare_powerups_map_b:
    ld d, 2
    ld e, 2
    call powerups_draw_small_lake

    ld a, 3
    ld (powerup_one_x), a
    ld (powerup_one_y), a

    ld d, 10
    ld e, 10
    call powerups_draw_small_lake

    ld a, 11
    ld (powerup_two_x), a
    ld (powerup_two_y), a

    ret

powerups_spawn_powerup_one:
    ld a, (powerup_one)

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
    
; bc = address of powerup_one or powerup_two
; d = x for powerup cell
; e = y for powerup cell
; hl = address of powerup tile to draw
powerups_spawn_powerup:
    ld a, r
    bit 3, a
    jp z, powerups_spawn_money

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

    ret


powerups_get_health:
    call status_inc_health
    call powerups_clear_powerup
    ret

powerups_get_money:
    call status_inc_money
    call powerups_clear_powerup
    ret

; Draws a 3x3 lake
;
; d = x for upper left cell 
; e = y for upper left cell
powerups_draw_small_lake:
    
    ; attr byte
    ld b, $0c
    
    push de
    call cursor_get_cell_attr
    ld (hl), b
    call cursor_get_cell_addr
    ex de, hl
    ld hl, small_lake
    call util_draw_tile
    pop de

    inc d
    push de
    call cursor_get_cell_attr
    ld (hl), b 
    call cursor_get_cell_addr
    ex de, hl
    ld hl, small_lake+8
    call util_draw_tile
    pop de

    inc d

    push de 
    call cursor_get_cell_attr
    ld (hl), b
    call cursor_get_cell_addr
    ex de, hl
    ld hl, small_lake+16
    call util_draw_tile
    pop de

    dec d 
    dec d
    inc e

    push de 
    call cursor_get_cell_attr
    ld (hl), b
    call cursor_get_cell_addr
    ex de, hl
    ld hl, small_lake+8*3
    call util_draw_tile
    pop de

    inc d

    push de 
    call cursor_get_cell_attr
    ld (hl), b
    call cursor_get_cell_addr
    ex de, hl
    ld hl, small_lake+8*4
    call util_draw_tile
    pop de

    inc d

    push de 
    call cursor_get_cell_attr
    ld (hl), b
    call cursor_get_cell_addr
    ex de, hl
    ld hl, small_lake+8*5
    call util_draw_tile
    pop de

    dec d 
    dec d
    inc e

    push de 
    call cursor_get_cell_attr
    ld (hl), b
    call cursor_get_cell_addr
    ex de, hl
    ld hl, small_lake+8*6
    call util_draw_tile
    pop de

    inc d

    push de 
    call cursor_get_cell_attr
    ld (hl), b
    call cursor_get_cell_addr
    ex de, hl
    ld hl, small_lake+8*7
    call util_draw_tile
    pop de

    inc d

    push de 
    call cursor_get_cell_attr
    ld (hl), b
    call cursor_get_cell_addr
    ex de, hl
    ld hl, small_lake+8*8
    call util_draw_tile
    pop de

    ret

    





