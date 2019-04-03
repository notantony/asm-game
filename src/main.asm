global    _start
section   .text
org 100h

_start:
    call    ini_timer
    call    enter_13h

    mov     ax, 0a000h 
    mov     es, ax

    ; mov     ax, data 
    ; mov     ds, ax 
    
    ;call    sleep




    call    draw_interface      ; not safe
    call    ini_field           ; not safe
    
    slmain:
    call    upd_field           ; not safe
    call    upd_video           ; not safe
    
    ;call    dbg_table
    
    mov     cx, 30000
    wait_key:
    call    upd_dirs
    loop    wait_key

    ;call    sleep
    jmp     slmain

    
    call    sleep
    ;jmp      slmain

    ;call dbg
    ;call all
    ;call dbg
    ;call sleep

    call exit_13h
    ret



println:
    push ax
    push dx
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    int 21h
    pop dx
    pop ax
    ret

printnum:
    push    ax
    push    bx
    push    cx
    push    dx
    
    mov     cx, 0
    mov     bx, 10
    loophere:
        mov     dx, 0
        div     bx                          ;divide by ten

        push    ax
        add     dl, '0'                     ;convert dl to ascii

        pop     ax                          ;restore ax
        push    dx                         ;digits are in reversed order, must use stack
        inc     cx                          ;remember how many digits we pushed to stack
        cmp     ax, 0                       ;if ax is zero, we can quit
    
    jnz     loophere
    mov     ah, 2                       ;2 is the function number of output char in the DOS Services.
    loophere2:
    pop     dx                          ;restore digits from last to first
    int     21h                         ;calls DOS Services
    loop    loophere2
    call    println
    
    pop    dx
    pop    cx
    pop    bx
    pop    ax
    ret

get_time: ; return: ax - timer
    in      al, 0x40            ; al = low byte of count
	mov     ah, al              ; ah = low byte of count
	in      al, 0x40            ; al = high byte of count
	rol     ax, 8               ; swap bits 
    ;call    printnum
    ret

enter_13h:
    mov     dl, 7
    mov     ax, 13h
    int     10h
    ret

exit_13h: ; Back to text mode
    xor     ah, ah
    mov     al, 3h
    int     10h
    ret

sleep: ; ah not safe, Wait for key press
    xor     ah, ah
    int     16h
    ret

ini_timer: ; https://en.wikibooks.org/wiki/X86_Assembly/Programmable_Interval_Timer
    mov     al, 0x36
    out     0x43, al    ; tell the PIT which channel we're setting

    mov     ax, 0
    out     0x40, al    ; send low byte
    mov     al, ah
    out     0x40, al    ; send high byte
    ret



draw_letter: ; al = letter, white color
    push    bx
    xor     bh, bh
    mov     bl, 15 ; bl = color 
    mov     ah, 0eh
    int     10h
    pop     bx
    ret

draw_word: ; dh = row, dl = column, cx = data_ptr
    push    di
    push    ax
    push    bx
    
    mov     di, 0           ; offset
    dwl1:
        mov     ah, 02h
        int     10h         ; set cursor, dh = row, dl = column

        mov     bx, cx 
        add     bx, di      
        mov     al, [bx]

        inc     dl
        inc     di
        call    draw_letter ; al = letter
        
        test    al, al
        jnz     dwl1
    
    pop    bx
    pop    ax
    pop    di
    ret

draw_block: ; ax = row, bx = column, cx = data_ptr 
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
    push    si

    mov     dx, 320 * 8
    mul     dx 
    push    ax
    mov     ax, 8
    mul     bx
    mov     bx, ax
    pop     ax
    add     ax, bx

    mov     bx, cx
    mov     cx, 8
    dbl2:
        mov     di, ax
        mov     si, 8
        dbl1:
            mov     dl, [bx]
            mov     [es:di], dl
            inc     di
            inc     bx
            dec     si
            jnz     dbl1
        add     ax, 320
        loop    dbl2

    pop     si
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret

; http://www.codenet.ru/progr/dos/int_0009.php
draw_interface: ; not safe    
    mov     dh, 0           ; row
    mov     dl, 3           ; column
    lea     cx, [snake_str] ; data_ptr
    call    draw_word       ; dh = row, dl = column, cx = data_ptr

    mov     dh, 0           ; row
    mov     dl, 22          ; column
    lea     cx, [player1_score_str] ; data_ptr
    call    draw_word       ; dh = row, dl = column, cx = data_ptr 

    mov     dh, 1           ; row
    mov     dl, 22          ; column
    lea     cx, [player2_score_str] ; data_ptr
    call    draw_word       ; dh = row, dl = column, cx = data_ptr 

    lea     cx, [brick]
    mov     di, 24
    dil1:
        mov     si, 39
        dil2:
            mov     ax, di
            mov     bx, si
            call    draw_block      ; ax = row, bx = column, cx = data_ptr
            dec     si
            cmp     si, -1
            jnz     dil2
        dec     di
        cmp     di, 1
        jnz     dil1

    lea     cx, [empty_block_tex]
    mov     di, 22
    dil3:
        mov     si, 37
        dil4:
            mov     ax, di
            mov     bx, si
            call    draw_block      ; ax = row, bx = column, cx = data_ptr
            dec     si
            mov     dx, 1
            cmp     si, dx
            jnz     dil4
        dec     di
        mov     dx, 3
        cmp     di, dx
        jnz     dil3

    ret

set_table: ; al = row, bl = column, cl = byte: ax, bx not safe  
    xor     ah, ah
    mov     bh, 40
    mul     bh
    xor     bh, bh
    add     bx, ax
    mov     [bx + table], cl        ; deleted tail1 from table
    
    ret

get_table: ; al = row, bl = column, cl = byte: ax, bx not safe
    xor     ah, ah
    mov     bh, 40
    mul     bh
    xor     bh, bh
    add     bx, ax
    mov     cl, byte [bx + table]
    ret

move_tails:
    mov     bx, [tail1]
    lea     di, [bx + snake1_datay]     ; *snake1_tail_y    
    lea     si, [bx + snake1_datax]     ; *snake1_tail_x

    mov     al, [di]
    mov     bl, [si]
    mov     cl, 0
    call    set_table

    mov     al, [di]
    mov     bl, [si]
    mov     [old1x], al 
    mov     [old1y], bl

    mov     bx, [tail2]
    lea     di, [bx + snake2_datay]     ; *snake1_tail_y 
    lea     si, [bx + snake2_datax]     ; *snake1_tail_x
    
    mov     al, [di]
    mov     bl, [si]
    mov     cl, 0
    call    set_table

    mov     al, [di]
    mov     bl, [si]
    mov     [old2x], al
    mov     [old2y], bl
    mov     di, [tail1] ; TODO: check overflow
    inc     di

    cmp     di, 21 * 34
    jnz     ovf1
    mov     di, 0
    ovf1:

    mov     [tail1], di

    mov     di, [tail2] ; TODO: check overflow
    inc     di

    cmp     di, 21 * 34
    jnz     ovf4
    mov     di, 0
    ovf4:

    mov     [tail2], di

    ret


add_tail2:
    mov     al, [old2x]
    mov     bl, [old2y]
    mov     cl, 3
    call    set_table

    mov     di, [tail2] ; TODO: check overflow
    dec     di

    cmp     di, -1
    jnz     ovf6
    mov     di, 21 * 34 - 1
    
    ovf6:

    mov     [tail2], di
    ret
add_tail1:
    mov     al, [old1x]
    mov     bl, [old1y]
    mov     cl, 2
    call    set_table

    mov     di, [tail1] ; TODO: check overflow
    dec     di

    cmp     di, -1
    jnz     ovf5
    mov     di, 21 * 34 - 1
    
    ovf5:

    mov     [tail1], di
    ret

move_step2:
    mov     ah, [dir2]
    jmp     ms2_enter
move_step1:  ; al = x, bl = y, return: al = x', bl = y', ah not safe
    mov     ah, [dir1]
    ms2_enter:

    cmp     ah, 0
    jz      ms1_0

    cmp     ah, 1
    jz      ms1_1

    cmp     ah, 2
    jz      ms1_2

    cmp     ah, 3
    jz      ms1_3
    
    ms1_0:
    dec     bl
    jmp     ms1_exit

    ms1_1:
    inc     al
    jmp     ms1_exit

    ms1_2:
    inc     bl
    jmp     ms1_exit

    ms1_3:
    dec     al
    jmp     ms1_exit


    ms1_exit:
    ret

move_heads:
    mov     bx, [head1]
    lea     di, [bx + snake1_datax]     ; *snake1_head_x
    lea     si, [bx + snake1_datay]     ; *snake1_head_y
    xor     ah, ah
    mov     al, [di]
    xor     bh, bh
    mov     bl, [si]

    mov     [oldhead1x], bl
    mov     [oldhead1y], al
    call    move_step1  ; TODO: direction cases
    mov     [new1x], al
    mov     [new1y], bl

    mov     bx, [head2]
    lea     di, [bx + snake2_datax]     ; *snake1_head_x
    lea     si, [bx + snake2_datay]     ; *snake1_head_y
    xor     ah, ah
    mov     al, [di]
    xor     bh, bh
    mov     bl, [si]

    mov     [oldhead2x], bl
    mov     [oldhead2y], al
    call    move_step2
    mov     [new2x], al
    mov     [new2y], bl


    mov     di, [head1] ; TODO: check overflow
    inc     di
    
    cmp     di, 21 * 34
    jnz     ovf2
    mov     di, 0
    ovf2:
    
    mov     [head1], di
    mov     al, [new1x]
    mov     [snake1_datax + di], al  
    mov     al, [new1y]
    mov     [snake1_datay + di], al
    
    mov     di, [head2] ; TODO: check overflow
    inc     di

    cmp     di, 21 * 34
    jnz     ovf3
    mov     di, 0
    ovf3:

    mov     [head2], di
    mov     al, [new2x]
    mov     [snake2_datax + di], al
    mov     al, [new2y]
    mov     [snake2_datay + di], al
    
    mov     al, [new1y]
    mov     bl, [new1x]
    call    get_table
    cmp     cl, 4
    jnz     mh1
    add     [apple], byte 1
    call    add_tail1
    
    mh1:
    mov     al, [new2y]
    mov     bl, [new2x]
    call    get_table
    cmp     cl, 4
    jnz     mh2
    add     [apple], byte 2
    call    add_tail2

    mh2:
    mov     al, [new1y]
    mov     bl, [new1x]
    mov     cl, 2
    call    set_table

    mov     al, [new2y]
    mov     bl, [new2x]
    mov     cl, 3
    call    set_table



    ret

endgame:
    call dbg_table
    call sleep
    ret

put_apples: ; not safe
    pa_begin:

    mov     al, [apple]
    cmp     al, 1
    jz      pa_exit

    call    get_time
    mov     bl, al
    xor     bl, ah
    pal1:
        sub     bl, byte 36
        jnb     pal1
    add     bl, 36 + 2 ; [0, 36)
    mov     dl, bl

    call    get_time
    mov     bl, al
    xor     bl, ah
    pal2:
        sub     bl, byte 19
        jnb     pal2
    add     bl, 19 + 4 ; [0, 19)
    mov     dh, bl

    xor     ah, ah
    xor     bh, bh
    mov     bl, dl
    mov     al, dh
    
    call    get_table
    test    cl, cl
    jnz     pa_begin

    xor     ah, ah
    xor     bh, bh
    mov     bl, dl
    mov     al, dh
    lea     cx, [apple_tex] ; TODO: apple tex
    mov     [apple], byte 1
    call    draw_block

    mov     cl, byte 4
    call    set_table
    pa_exit:

    ret


upd_field: ; not safe
    ;call    sleep
    call    put_apples
    
    call    move_tails
    ; old[12][xy]

    call    move_heads


    ; new[12][xy]    
    ; oldhead[12][xy]
    
    ; TODO: check death & apple

    ; TODO: apple returns tail

    ; TODO: same next values
    
    ; Everything ok?
    
    call endgame
    
    ret

upd_video:
    ; TODO: case game over
    ; TODO: case apple
    mov     ah, [apple] 
    cmp     ah, 2
    jz      uv1   
    
    xor     ah, ah
    mov     al, [old1x]
    xor     bh, bh
    mov     bl, [old1y]
    lea     cx, [empty_block_tex]
    call    draw_block
    
    uv1:
    mov     ah, [apple] 
    cmp     ah, 3
    jz      uv2

    xor     ah, ah
    mov     al, [old2x]
    xor     bh, bh
    mov     bl, [old2y]
    lea     cx, [empty_block_tex]
    call    draw_block

    uv2:
    xor     ah, ah
    mov     al, [oldhead1x]
    xor     bh, bh
    mov     bl, [oldhead1y]
    lea     cx, [snake1_tex]
    call    draw_block

    xor     ah, ah
    mov     al, [oldhead2x]
    xor     bh, bh
    mov     bl, [oldhead2y]
    lea     cx, [snake2_tex]
    call    draw_block              


    xor     ah, ah
    mov     al, [new1y]
    xor     bh, bh
    mov     bl, [new1x]
    lea     cx, [snake1_head_tex]
    call    draw_block

    xor     ah, ah
    mov     al, [new2y]
    xor     bh, bh
    mov     bl, [new2x]
    lea     cx, [snake2_head_tex]
    call    draw_block

    ret

dbg_table: ; not safe
    mov     di, 23
    stl1:
        mov     si, 38
        stl2:
            mov     ax, di
            mov     bx, si
            mov     dh, al
            mov     dl, bl
            xor     al, al
            mov     ah, 02h
            int     10h

            mov     ax, 40
            mul     di
            add     ax, si
            mov     bx, ax
            lea     bx, [bx + table]

            mov     al, byte [bx]
            add     al, '0'

            call    draw_letter

          
            dec     si
            cmp     si, 0
            jnz     stl2
        dec     di
        cmp     di, 2
        jnz     stl1
    ret

read_char:  ; ret: al -> key code, zf -> result, ax not safe
    mov     ah, 01h
    int     16h
    ret

upd_dirs:   ; ax not safe
    call    read_char
    jz      ud_exit
    call    sleep
    
    cmp     al, 119
    jz      ud_w

    cmp     al, 115
    jz      ud_s

    cmp     al, 97
    jz      ud_a

    cmp     al, 100
    jz      ud_d

    jmp     ud_p2

    ud_w:
    mov     [dir1], byte 0
    jmp     ud_exit
    
    ud_a:
    mov     [dir1], byte 3
    jmp     ud_exit
    
    ud_s:
    mov     [dir1], byte 2
    jmp     ud_exit

    ud_d:
    mov     [dir1], byte 1
    jmp     ud_exit

    ud_p2:
    cmp     al, 56
    jz      ud_8

    cmp     al, 52
    jz      ud_4

    cmp     al, 54
    jz      ud_6

    cmp     al, 53
    jz      ud_5

    cmp     al, 32
    jz      ud_space

    jmp     ud_exit

    ud_8:
    mov     [dir2], byte 0
    jmp     ud_exit
    
    ud_4:
    mov     [dir2], byte 3
    jmp     ud_exit
    
    ud_5:
    mov     [dir2], byte 2
    jmp     ud_exit

    ud_6:
    mov     [dir2], byte 1
    jmp     ud_exit

    ud_space:
    call    sleep

    ud_exit:
    ret


ini_field: ; not safe
    lea     di, [snake1_datax]
    lea     si, [snake1_datay]
    lea     cx, [snake1_tex]

    mov     [di], byte 2
    mov     [si], byte 4
    xor     ax, ax
    mov     al, [si]
    xor     bx, bx
    mov     bl, [di]
    call    draw_block

    inc     si
    inc     di
    mov     [di], byte 3
    mov     [si], byte 4
    xor     ax, ax
    mov     al, [si]
    xor     bx, bx
    mov     bl, [di]
    call    draw_block

    inc     si
    inc     di
    mov     [di], byte 4
    mov     [si], byte 4
    xor     ax, ax
    mov     al, [si]
    xor     bx, bx
    mov     bl, [di]
    call    draw_block

    lea     cx, [snake1_head_tex] 
    inc     si
    inc     di
    mov     [di], byte 5
    mov     [si], byte 4
    xor     ax, ax
    mov     al, [si]
    xor     bx, bx
    mov     bl, [di]
    call    draw_block

    lea     di, [snake2_datax]
    lea     si, [snake2_datay]
    lea     cx, [snake2_tex]

    mov     [di], byte 37
    mov     [si], byte 22
    xor     ax, ax
    mov     al, [si]
    xor     bx, bx
    mov     bl, [di]
    call    draw_block

    inc     si
    inc     di
    mov     [di], byte 36
    mov     [si], byte 22
    xor     ax, ax
    mov     al, [si]
    xor     bx, bx
    mov     bl, [di]
    call    draw_block

    inc     si
    inc     di
    mov     [di], byte 35
    mov     [si], byte 22
    xor     ax, ax
    mov     al, [si]
    xor     bx, bx
    mov     bl, [di]
    call    draw_block

    lea     cx, [snake2_head_tex] 
    inc     si
    inc     di
    mov     [di], byte 34
    mov     [si], byte 22
    xor     ax, ax
    mov     al, [si]
    xor     bx, bx
    mov     bl, [di]
    call    draw_block


    mov     di, 23
    ifl1:
        mov     si, 38
        ifl2:
            mov     ax, 40
            mul     di
            add     ax, si
            mov     bx, ax
            lea     bx, [bx + table]

            mov     [bx], byte 1 
          
            dec     si
            cmp     si, 0
            jnz     ifl2
        dec     di
        cmp     di, 2
        jnz     ifl1

    mov     di, 22
    ifl3:
        mov     si, 37
        ifl4:
            mov     ax, 40
            mul     di
            add     ax, si
            mov     bx, ax
            lea     bx, [bx + table]

            mov     [bx], byte 0 
          
            dec     si
            cmp     si, 1
            jnz     ifl4
        dec     di
        cmp     di, 3
        jnz     ifl3
    

    mov     cx, 320
    mov     [table + 40 * 22 + 34], byte 3
    mov     [table + 40 * 22 + 35], byte 3
    mov     [table + 40 * 22 + 36], byte 3
    mov     [table + 40 * 22 + 37], byte 3
    mov     [table + 40 * 4 + 2], byte 2
    mov     [table + 40 * 4 + 3], byte 2
    mov     [table + 40 * 4 + 4], byte 2
    mov     [table + 40 * 4 + 5], byte 2


    mov     cx, 40

    mov     [tail1], word 0
    mov     [tail2], word 0
    mov     [head1], word 3
    mov     [head2], word 3

    mov     [dir1], byte 1
    mov     [dir2], byte 3

    mov     [game_over], byte 0
    mov     [score], word 0    
    ret


section      .data
snake_str:
    db      'SANEK II', 0
player1_score_str: 
    db      'Player 1: ', 0
player2_score_str:
    db      'Player 2: ', 0
hiscore:
    db      0
brick:
    db      06h, 0xa1, 06h, 06h, 06h, 0xa1, 06h, 06h,
    db      72h, 0xa1, 72h, 72h, 72h, 0xa1, 72h, 72h,
    db      06h, 06h, 06h, 0xa1, 06h, 06h, 06h, 0xa1,
    db      72h, 72h, 72h, 0xa1, 72h, 72h, 72h, 0xa1,
    db      06h, 0xa1, 06h, 06h, 06h, 0xa1, 06h, 06h,
    db      72h, 0xa1, 72h, 72h, 72h, 0xa1, 72h, 72h,
    db      06h, 06h, 06h, 0xa1, 06h, 06h, 06h, 0xa1,
    db      72h, 72h, 72h, 0xa1, 72h, 72h, 72h, 0xa1

snake1_tex:
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 9fh, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 9fh, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 9fh, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch

snake2_tex:
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 9fh, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 9fh, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 9fh, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah

snake1_head_tex:
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 00h, 00h, 00h, 00h, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 00h, 00h, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch

snake2_head_tex:
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 00h, 00h, 00h, 00h, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 00h, 00h, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah
apple_tex:
    db      00h, 00h, 0eh, 0eh, 02h, 02h, 0eh, 00h,
    db      00h, 0eh, 0eh, 0eh, 02h, 0eh, 0eh, 0eh,
    db      0eh, 0eh, 0eh, 0eh, 0eh, 0eh, 0eh, 0eh,
    db      0eh, 0eh, 0eh, 0eh, 0eh, 0eh, 0eh, 0eh,
    db      0eh, 0eh, 0eh, 0eh, 0eh, 0eh, 0eh, 0eh,
    db      0eh, 0eh, 0eh, 0eh, 0eh, 0eh, 0eh, 0eh,
    db      00h, 0eh, 0eh, 0eh, 0eh, 0eh, 0eh, 00h,
    db      00h, 00h, 0eh, 0eh, 0eh, 00h, 00h, 00h
section     .bss
empty_block_tex:
    resb    8 * 8
snake1_datax:
    resb    21 * 34
snake1_datay:
    resb    21 * 34
snake2_datax:
    resb    21 * 34
snake2_datay:
    resb    21 * 34
table:
    resb    25 * 40
dir1:
    resb    1
dir2:
    resb    1
head1:
    resw    1
head2:
    resw    1
tail1:
    resw    1
tail2:
    resw    1
game_over:
    resb    1
score:
    resb    1
old1x:
    resw    1
old2x:
    resw    1
old1y:
    resw    1
old2y:
    resw    1
new1x:
    resw    1
new2x:
    resw    1
new1y:
    resw    1
new2y:
    resw    1
oldhead1x:
    resw    1
oldhead2x:
    resw    1
oldhead1y:
    resw    1
oldhead2y:
    resw    1
apple:
    resb    1