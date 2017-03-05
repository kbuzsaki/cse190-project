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
	call util_clear_pixels
	call util_clear_attrs

	; set the screen to black
	ld d, $ff
	call util_fill_all_pixels

	; draw the map from the tile map
	ld hl, tile_map
	call load_map

	; enable interrupts again now that we're set up
	ei

	; infinite loop that spins while we wait for an interrupt
infinite_wait:
	jp infinite_wait


; main game loop
interrupt_handler:
	di

	; only animate every 8th frame
	ld a, (real_frame_counter)
	add 1
	ld (real_frame_counter), a
	and 7
	jp nz, interrupt_handler_end
	ld a, (real_frame_counter)
	srl a
	srl a
	srl a
	and 3
	ld (frame_counter), a

	; loop over the array of fat enemies
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

interrupt_handler_end:
	ei
	reti


include "enemy_handler.asm"
include "enemy_sprite.asm"
include "input.asm"
include "load_map.asm"
include "misc.asm"
include "util.asm"


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


saved_sp:
    defw    0


real_frame_counter:
	defb 0

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

defs $9100 - $

enemy_path_direction:
	defb $00
	defb $00, $00, $00, $00, $03, $03, $03, $03
	defb $00, $00, $00, $00, $00, $00, $00, $02
	defb $02, $02, $02, $02, $02, $00, $00, $00
	defb $00, $00, $00, $00, $00, $03, $03, $03
	defb $03, $03, $03, $03, $03, $03, $00, $00
	defb $00, $00, $00, $00, $00, $00, $02, $02
	defb $02, $02, $02, $00, $00, $00, $00, $00

current_enemy_index:
	defb $00

defs $9200 - $

; enemy positions
fat_enemy_array:
	defb $00
	defb $02
	defb $04
	defb $06
	defb $08
	defb $0a
	defb $0c
	defb $0e
	defb $10
	defb $12
	defb $14
	defb $16
	defb $18
	defb $1a
	defb $1c
	defb $1e
	defb $20
	defb $22
	defb $24
	defb $26
	defb $28
	defb $2a
	defb $2c
	defb $2e
	defs $9300 - $, $ff

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
defb 60  	;   ####  
defb 122  	;  #### # 
defb 255  	; ########
defb 253  	; ###### #
defb 254  	; ####### 
defb 127  	;  #######
defb 24  	;    ##   
defb 28  	;    ###  

defb 15  	;     ####
defb 30  	;    #### 
defb 63  	;   ######
defb 63  	;   ######
defb 63  	;   ######
defb 31  	;    #####
defb 13  	;     ## #
defb 14  	;     ### 

defb 3  	;       ##
defb 7  	;      ###
defb 15  	;     ####
defb 15  	;     ####
defb 15  	;     ####
defb 7  	;      ###
defb 1  	;        #
defb 1  	;        #

defb 0  	;         
defb 1  	;        #
defb 3  	;       ##
defb 3  	;       ##
defb 3  	;       ##
defb 1  	;        #
defb 0  	;         
defb 0  	;         

defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         

defb 0  	;         
defb 128  	; #       
defb 192  	; ##      
defb 64  	;  #      
defb 128  	; #       
defb 192  	; ##      
defb 128  	; #       
defb 192  	; ##      

defb 192  	; ##      
defb 160  	; # #     
defb 240  	; ####    
defb 208  	; ## #    
defb 224  	; ###     
defb 240  	; ####    
defb 128  	; #       
defb 192  	; ##      

defb 240  	; ####    
defb 232  	; ### #   
defb 252  	; ######  
defb 244  	; #### #  
defb 248  	; #####   
defb 252  	; ######  
defb 216  	; ## ##   
defb 236  	; ### ##  

defb 60  	;   ####  
defb 126  	;  ###### 
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 126  	;  ###### 
defb 231  	; ###  ###

defb 60  	;   ####  
defb 126  	;  ###### 
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 127  	;  #######
defb 254  	; ####### 
defb 7  	;      ###

defb 60  	;   ####  
defb 126  	;  ###### 
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 126  	;  ###### 
defb 231  	; ###  ###

defb 60  	;   ####  
defb 126  	;  ###### 
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 254  	; ####### 
defb 127  	;  #######
defb 224  	; ###     

defb 60  	;   ####  
defb 90  	;  # ## # 
defb 255  	; ########
defb 219  	; ## ## ##
defb 231  	; ###  ###
defb 255  	; ########
defb 126  	;  ###### 
defb 231  	; ###  ###

defb 60  	;   ####  
defb 90  	;  # ## # 
defb 255  	; ########
defb 219  	; ## ## ##
defb 231  	; ###  ###
defb 254  	; ####### 
defb 127  	;  #######
defb 224  	; ###     

defb 60  	;   ####  
defb 90  	;  # ## # 
defb 255  	; ########
defb 219  	; ## ## ##
defb 231  	; ###  ###
defb 255  	; ########
defb 126  	;  ###### 
defb 231  	; ###  ###

defb 60  	;   ####  
defb 90  	;  # ## # 
defb 255  	; ########
defb 219  	; ## ## ##
defb 231  	; ###  ###
defb 127  	;  #######
defb 254  	; ####### 
defb 7  	;      ###

defb 60  	;   ####  
defb 122  	;  #### # 
defb 255  	; ########
defb 254  	; ####### 
defb 253  	; ###### #
defb 127  	;  #######
defb 24  	;    ##   
defb 28  	;    ###  

defb 15  	;     ####
defb 30  	;    #### 
defb 63  	;   ######
defb 63  	;   ######
defb 63  	;   ######
defb 31  	;    #####
defb 13  	;     ## #
defb 14  	;     ### 

defb 3  	;       ##
defb 7  	;      ###
defb 15  	;     ####
defb 15  	;     ####
defb 15  	;     ####
defb 7  	;      ###
defb 1  	;        #
defb 1  	;        #

defb 0  	;         
defb 1  	;        #
defb 3  	;       ##
defb 3  	;       ##
defb 3  	;       ##
defb 1  	;        #
defb 0  	;         
defb 0  	;         

defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         
defb 0  	;         

defb 0  	;         
defb 128  	; #       
defb 192  	; ##      
defb 128  	; #       
defb 64  	;  #      
defb 192  	; ##      
defb 128  	; #       
defb 192  	; ##      

defb 192  	; ##      
defb 160  	; # #     
defb 240  	; ####    
defb 224  	; ###     
defb 208  	; ## #    
defb 240  	; ####    
defb 128  	; #       
defb 192  	; ##      

defb 240  	; ####    
defb 232  	; ### #   
defb 252  	; ######  
defb 248  	; #####   
defb 244  	; #### #  
defb 252  	; ######  
defb 216  	; ## ##   
defb 236  	; ### ##  

defb 60  	;   ####  
defb 126  	;  ###### 
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 126  	;  ###### 
defb 231  	; ###  ###

defb 60  	;   ####  
defb 126  	;  ###### 
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 127  	;  #######
defb 254  	; ####### 
defb 7  	;      ###

defb 60  	;   ####  
defb 126  	;  ###### 
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 126  	;  ###### 
defb 231  	; ###  ###

defb 60  	;   ####  
defb 126  	;  ###### 
defb 255  	; ########
defb 255  	; ########
defb 255  	; ########
defb 254  	; ####### 
defb 127  	;  #######
defb 224  	; ###     

defb 60  	;   ####  
defb 90  	;  # ## # 
defb 255  	; ########
defb 231  	; ###  ###
defb 219  	; ## ## ##
defb 255  	; ########
defb 126  	;  ###### 
defb 231  	; ###  ###

defb 60  	;   ####  
defb 90  	;  # ## # 
defb 255  	; ########
defb 231  	; ###  ###
defb 219  	; ## ## ##
defb 254  	; ####### 
defb 127  	;  #######
defb 224  	; ###     

defb 60  	;   ####  
defb 90  	;  # ## # 
defb 255  	; ########
defb 231  	; ###  ###
defb 219  	; ## ## ##
defb 255  	; ########
defb 126  	;  ###### 
defb 231  	; ###  ###

defb 60  	;   ####  
defb 90  	;  # ## # 
defb 255  	; ########
defb 231  	; ###  ###
defb 219  	; ## ## ##
defb 127  	;  #######
defb 254  	; ####### 
defb 7  	;      ###
