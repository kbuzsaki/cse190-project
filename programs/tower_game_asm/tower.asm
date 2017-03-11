tower_handler_entry_point_handle_attacks:
	call tower_handler_handle_attacks
	ret

; iterates over the towers that have been built
; and performs the tower attacks
tower_handler_handle_attacks:
	ld a, 0
	ld (current_tower_index), a

tower_handler_handle_attacks_loop:
	; load the tower type to perform checks
	ld a, (current_tower_index)
	call tower_handler_load_tower_type

	; check for $fe (empty)
	cp $fe
	jp z, tower_handler_handle_attacks_loop_increment

	; check for $ff (end of array)
	cp $ff
	ret z

	; check for $01 (laser tower)
	cp $01
	call z, tower_handler_handle_laser_attack

	; increment loop counter and jump to beginning of loop
tower_handler_handle_attacks_loop_increment:
	ld a, (current_tower_index)
	inc a
	ld (current_tower_index), a

	jp tower_handler_handle_attacks_loop
	ret


; input:
;  a - the build tile index
; output:
;  a - the type of the tower
tower_handler_load_tower_type:
	ld hl, build_tile_towers
	ld l, a
	ld a, (hl)
	ret

; input:
;  a - the build tile index
; output:
;  hl - the ptr into the build_tile_attackables array
tower_handler_get_attackable_ptr:
	ld hl, build_tile_attackables_d
	sla a
	sla a
	ld l, a
	ret




; todo: check if this tower has attacked already
; handles the attack for a laser tower
tower_handler_handle_laser_attack:
	; get the attackables pointer
	ld a, (current_tower_index)

	; get the attackable ptr in hl
	; the attackable position bytes are the 4 bytes at this address
	call tower_handler_get_attackable_ptr

	; check the first attackable, do attack if we find a position
	ld a, (hl)
	call tower_handler_handle_laser_attack_check_attackable
	cp $ff
	jp nz, tower_handler_handle_laser_attack_do_attack

	; check the second attackable, do attack if we find a position
	inc hl
	ld a, (hl)
	call tower_handler_handle_laser_attack_check_attackable
	cp $ff
	jp nz, tower_handler_handle_laser_attack_do_attack

	; check the third attackable, do attack if we find a position
	inc hl
	ld a, (hl)
	call tower_handler_handle_laser_attack_check_attackable
	cp $ff
	jp nz, tower_handler_handle_laser_attack_do_attack

	; check the fourth attackable, do attack if we find a position
	inc hl
	ld a, (hl)
	call tower_handler_handle_laser_attack_check_attackable
	cp $ff
	jp nz, tower_handler_handle_laser_attack_do_attack

	; if we get here then none of the attackables had an enemy
	; so just do nothing
	ret

	; jump here when we attack an enemy so that we only attack one enemy
tower_handler_handle_laser_attack_do_attack:

	; attack the enemy at the position in a
	call tower_handler_handle_laser_attack_enemy

	ret


; input:
;   a - the first position of this attackable
; output:
;   a - the first position of this attackable that has an enemy, or $ff
tower_handler_handle_laser_attack_check_attackable:
	; if it's ff, then there's nothing to check so skip it
	cp $ff
	ret z

	; else, check the 3 tiles in this attackable range
	; (this position and the following 2)

	ld b, a
	; check first position, return if we find something
	call tower_handler_find_enemy_at
	cp $ff
	ret nz

	ld a, b
	inc a
	ld b, a
	; check second position, return if we find something
	call tower_handler_find_enemy_at
	cp $ff
	ret nz

	ld a, b
	inc a
	; check third position, always return
	call tower_handler_find_enemy_at
	ret


; input:
;  a - the packed type / index of the enemy to attack
tower_handler_handle_laser_attack_enemy:
	call tower_handler_init_enemy_arrays
	call tower_handler_damage_enemy
	call tower_handler_toggle_border_color
	ret

tower_handler_init_enemy_arrays:
	; save the packed index into b
	ld b, a

	; store the real index
	and $7f
	ld (current_attacked_enemy_index), a

	; reload the packed index from b, check the type
	ld a, b
	and $80
	jp nz, tower_handler_init_enemy_arrays_strong_enemy

	; weak enemy
	ld hl, weak_enemy_position_array
	ld (current_enemy_position_array), hl
	ld hl, weak_enemy_health_array
	ld (current_enemy_health_array), hl

	ret

	; strong enemy
tower_handler_init_enemy_arrays_strong_enemy:

	ld hl, strong_enemy_position_array
	ld (current_enemy_position_array), hl
	ld hl, strong_enemy_health_array
	ld (current_enemy_health_array), hl

	ret


tower_handler_damage_enemy:
	; find and decrement the enemy's health
	ld a, (current_attacked_enemy_index)
	ld hl, (current_enemy_health_array)
	ld l, a
	dec (hl)

	; if we hit 0, remove the enemy
	call z, tower_handler_kill_enemy
	ret


; todo: blood splatter, clean up enemy
tower_handler_kill_enemy:
	ld a, (current_attacked_enemy_index)
	call enemy_handler_clear_enemy_at_index
	ret


; input:
;  a - the position index to search for
; output:
;  a - the enemy index for that position
tower_handler_find_enemy_at:
	ld de, enemy_position_to_index_array
	ld e, a
	ld a, (de)
	ret


border_color:
	defb $00

tower_handler_toggle_border_color:
	ld a, (border_color)
	inc a
	and $07
	ld (border_color), a
	out ($fe), a
	ret
