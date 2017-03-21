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
    ld a, $0c
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
    ld a, $0c
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
    ld a, $0c
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


; most of the rom has roughly equal entropy, so starting at 0 is fine
powerup_spawn_powerup_rand_ptr:
	defw $0000

; bc = address of powerup_one or powerup_two
; d = x for powerup cell
; e = y for powerup cell
powerups_spawn_powerup:
	; load the rom pointer into hl, inc it by a random amount based on r, and put it back
	push bc
	ld hl, (powerup_spawn_powerup_rand_ptr)
	ld a, r
	and $07
	ld b, 0
	ld c, a
	inc bc
	add hl, bc
	ld (powerup_spawn_powerup_rand_ptr), hl
	pop bc

	; then read from rom to get a random value
	ld a, (hl)

    sub 50
    jp pe, powerups_spawn_slow
    
    sub 40
    jp pe, powerups_spawn_bomb

    sub 40
    jp pe, powerups_spawn_zap 
    
    sub 40
    jp pe, powerups_spawn_life

	jp powerups_spawn_money

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

	; play the get item sfx
	ld a, (sound_effect_flags)
	or $02
	ld (sound_effect_flags), a


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
    call status_inc_zap
    call powerups_clear_powerup
    ret

powerups_get_bomb:
    call status_inc_bomb
    call powerups_clear_powerup
    ret

powerups_get_slow:
    call status_inc_slow
    call powerups_clear_powerup
    ret

powerups_use_zap:
	; try to dec a charge, give up if we can't
    call status_dec_zap
	cp 0
	ret z

	; set the zap sound effect
	ld a, (sound_effect_flags)
	or $04
	ld (sound_effect_flags), a

	; flash the path
	; todo: make this flash back and forth for a set period
	; right now it stays lit for a semi-random number of frames
	call tower_set_path_highlights

	; damage all of the enemies
	; todo: maybe queue up the zap again so it flashes and then does damage?
	call powerups_do_zap_damage

    ret

; zaps all enemies currently on the path
powerups_do_zap_damage:
	; weak enemies
	ld hl, weak_enemy_position_array
	ld (current_enemy_position_array), hl
	ld hl, weak_enemy_health_array
	ld (current_enemy_health_array), hl
	ld a, 1
	ld (current_attacked_enemy_value), a

	call powerups_do_zap_damage_generic

	; strong enemies
	ld hl, strong_enemy_position_array
	ld (current_enemy_position_array), hl
	ld hl, strong_enemy_health_array
	ld (current_enemy_health_array), hl
	ld a, 2
	ld (current_attacked_enemy_value), a

	call powerups_do_zap_damage_generic

	ret

powerups_do_zap_damage_generic:
	ld a, 0
	ld (current_enemy_index), a
powerups_do_zap_damage_generic_loop:
	; load the position for this enemy to do checks
	ld a, (current_enemy_index)
	call enemy_handler_load_position_index

	; check for $fe (skip enemy)
	cp $fe
	jp z, powerups_do_zap_damage_generic_loop_increment

	; check for $ff (end of array)
	cp $ff
	ret z

	ld a, (current_enemy_index)
	call tower_handler_damage_enemy

	; increment loop counter and jump to beginning of loop
powerups_do_zap_damage_generic_loop_increment:
	ld a, (current_enemy_index)
	inc a
	ld (current_enemy_index), a

	jp powerups_do_zap_damage_generic_loop

powerups_check_bomb_count:
    ld hl, bomb_position_array

powerups_check_bomb_loop:
    ld a, (hl)

    ; if a is $ff (end of array) then set b to 0 and return
    cp $ff
    ld b, 0
    ret z

    ; if a is $ff (empty) then set b to 1 and return
    cp $fe
    ld b, 1
    ret z

    ; else, check the next spot
    inc hl
    jp powerups_check_bomb_loop
    
    
powerups_use_bomb:
	; paint the bomb
	ld a, (cursor_x)
	ld d, a
	ld a, (cursor_y)
	ld e, a

	; check if the coordinates are valid
	ld hl, (enemy_path_xy)
	call build_find_xys_tile_index
	cp $ff
	ret z

	; stash the position index in c
	ld c, a

    call powerups_check_bomb_count
    ld a, b
    cp 0
    ret z

	; try to dec a charge, give up if we can't
	push de
    call status_dec_bomb
	pop de
	cp 0
	ret z

	; if we got this far, then draw the bomb
	ld a, c
	call enemy_handler_load_position_vram
	ld hl, bomb
	call util_draw_tile

	; set the bomb sound effect
	ld a, (sound_effect_flags)
	or $01
	ld (sound_effect_flags), a

	; todo:
	; do game state for making the bomb actually explode and damage an enemy
	ld hl, bomb_position_array-1

powerups_use_bomb_loop:
	inc hl
	; load this index, check if it's valid
	ld a, (hl)
	cp $fe
	jp nz, powerups_use_bomb_loop

	; else if it's valid then store the bomb position
	ld (hl), c
    ret

; checks whether bombs should explode (because they have an enemy before them)
powerups_handle_bomb_explode_checks:
	ld de, bomb_position_array-1
	ld hl, enemy_position_to_index_array

powerups_handle_bomb_explode_checks_loop:
	inc de
	ld a, (de)

	; if it's fe then it's empty so skip
	cp $fe
	jp z, powerups_handle_bomb_explode_checks_loop

	; if it's ff then end of array so return
	cp $ff
	ret z

	; else it's present so check if there's an enemy right before it
	dec a
	ld l, a
	ld a, (hl)

	; if there isn't then skip
	cp $ff
	jp z, powerups_handle_bomb_explode_checks_loop

	; if there is, then set it to empty 
	ex de, hl
	ld (hl), $fe
	ex de, hl

	; and explode it!
	push de
	push hl
	call powerups_handle_bomb_explode
	pop hl
	pop de
	
	ret

; inputs:
;   a - the packed enemy index to explode
;   l - the path position
powerups_handle_bomb_explode:
	push hl

	; kill the enemy
	call tower_handler_init_enemy_arrays
	ld a, (current_attacked_enemy_index)
	call tower_handler_kill_enemy

	; get the position of the bomb
	pop hl
	ld b, l
	inc b

	; draw the explosion sprite
	ld a, b
	call enemy_handler_load_position_vram
	ld hl, explosion
	call util_draw_tile

	; set the explosion attribute
	ld a, b
	ld hl, (enemy_path_attr)
	ld d, 0
	sla a
	ld e, a
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	ld (hl), $72

	; insert the explosion as a path element to remove later
	ld c, $04
	call powerups_insert_path_element
	
	ret


powerups_use_slow:
	; try to dec a charge, give up if we can't
    call status_dec_slow
	cp 0
	ret z


powerups_slow_start:
	ld a, $10
	ld (slow_counter), a 

	; set the background color to cyan
	ld a, $05
	out ($fe), a
	ld ($fdcc), a

	ret

powerups_slow_end:
	; set the background color back to blue
	ld a, $01
	out ($fe), a
	ld ($fdcc), a

	ret



; inputs:
;   b - the position value
;   c - the timer value
powerups_insert_path_element:
	ld hl, path_elements_timer_array
	ld de, path_elements_position_array

powerups_insert_path_element_loop:
	; if it's empty, then use this spot
	ld a, (hl)
	cp $fe
	jp z, powerups_insert_path_element_do_insert
	cp $ff
	jp z, powerups_insert_path_element_do_insert

	; else loop back
	inc hl
	inc de
	jp powerups_insert_path_element_loop

powerups_insert_path_element_do_insert:
	ld (hl), c
	ex de, hl
	ld (hl), b

	ret

; checks to clear temporary path elements like explosions and blood splatters
powerups_clear_path_elements:
	ld hl, path_elements_timer_array
	ld de, path_elements_position_array

powerups_clear_path_elements_loop:
	ld a, (hl)

	; if we find $ff then we're done
	cp $ff
	ret z

	; if we find not $fe then process
	cp $fe
	call nz, powerups_clear_path_element_process_element

	; finally loop back
	inc hl
	inc de
	jp powerups_clear_path_elements_loop


; removes the element pointed to by hl and de
powerups_clear_path_element_process_element:
	; dec the timer, if we don't hit 0 then abort
	dec (hl)
	ret nz

	; if we do hit 0 then remove the element
	push hl
	push de

	; clear the element in the array
	ld (hl), $fe

	; load its position
	ld a, (de)

	; stash it in a
	ld b, a

	; clear the vram addr
	call enemy_handler_load_position_vram
	ld hl, blank_tile
	call util_draw_tile

	; clear the attr byte
	ld a, b
	ld hl, (enemy_path_attr)
	ld d, 0
	sla a
	ld e, a
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	ld (hl), $30

	pop de
	pop hl
	ret
