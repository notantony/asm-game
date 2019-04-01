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


    call draw_interface ; not safe
    call ini_field ; not safe
    

    call sleep


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
    ret

dbg:
    push    ax
    in      al, 0x40          ; al = low byte of count
	mov     ah, al           ; ah = low byte of count
	in      al, 0x40          ; al = high byte of count
	rol     ax, 8    
    call    printnum
    pop     ax
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

sleep: ; Wait for key press
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
        int     10h         ; set pointer, DH = row, DL = column

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
    mov     dl, 22          ; column
    lea     cx, [score_str] ; data_ptr
    call    draw_word       ; dh = row, dl = column, cx = data_ptr 

    mov     dh, 1           ; row
    mov     dl, 20          ; column
    lea     cx, [hiscore_str] ; data_ptr
    call    draw_word       ; dh = row, dl = column, cx = data_ptr 

    lea     cx, [brick]
    mov     di, 24
    dil1:
        mov     si, 39
        dil2:
            mov     ax, di
            mov     bx, si
            call    draw_block      ; ax = row, bx = column, cx = data_ptr, everything dead, except si, di
            dec     si
            mov     dx, -1
            cmp     si, dx
            jnz     dil2
        dec     di
        mov     dx, 1
        cmp     di, dx
        jnz     dil1

    lea     cx, [empty_block]
    mov     di, 22
    dil3:
        mov     si, 37
        dil4:
            mov     ax, di
            mov     bx, si
            call    draw_block      ; ax = row, bx = column, cx = data_ptr, everything dead, except si, di
            dec     si
            mov     dx, 1
            cmp     si, dx
            jnz     dil4
        dec     di
        mov     dx, 3
        cmp     di, dx
        jnz     dil3

    ret

upd_field:
    

ini_field: ; not safe
    ; TODO: check overflow
    lea     di, [snake1_datax]
    lea     si, [snake1_datay]
    lea     cx, [snake1]

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

    lea     cx, [snake1_head] 
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
    lea     cx, [snake2]

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

    lea     cx, [snake2_head] 
    inc     si
    inc     di
    mov     [di], byte 34
    mov     [si], byte 22
    xor     ax, ax
    mov     al, [si]
    xor     bx, bx
    mov     bl, [di]
    call    draw_block

    mov     [tail1], word 0
    mov     [tail2], word 0
    mov     [head1], word 3
    mov     [head2], word 3

    mov     [dir1], byte 1
    mov     [dir2], byte 3

    mov     [button1], byte 0
    mov     [button2], byte 0

    mov     [game_over], byte 0
    mov     [score], word 0

    
    ret    


all:
    xor     di, di
    mov     bx, 320 * 75

    draw_first_purple_block:
        ;call    sleep
        mov     [es:di], byte 100
        add     di, 1
        sub     bx, 1
        jnz     draw_first_purple_block
        

    mov     bx, 320 * 25

    draw_second_purple_block:
        mov     [ es:di ], byte 101
        add     di, 1
        sub     bx, 1
        jnz     draw_second_purple_block


    mov     bx, 1
    mov     di, 320 * 65 + 40

    draw_triangle:
        cmp     bx, 33
        je      triangle_done

        mov     cx, bx

        draw_triangle_inner:
            mov     [ es:di ], byte 102
            add     di, 1
            sub     cx, 1
            jnz     draw_triangle_inner

        add     bx, 2
        add     di, 320

        mov     ax, bx
        sub     ax, 1

        sub     di, ax

        jmp     draw_triangle

    triangle_done:

    ; Write letter B to bottom right corner
    ; DH = row, DL = column
    mov     dh, 49
    mov     dl, 30
    xor     bh, bh
    mov     ah, 02h
    int     10h

    ; BL = color, AL = letter (66 = B)
    xor     bh, bh
    mov     bl, 102
    mov     ah, 0eh
    mov     al, 66
    int     10h


    mov     di, 320 * 190 + 10

    ; BL runs between 0..63
    ; CL contains animation direction
    xor     bl, bl
    mov     cl, 1

    ; Draws a red gradient line animation in top left corner
    main_loop:
        ; VGA input status
        mov     dx, 03dah

        ; Wait for vertical retrace start
        wait_vr_start:
            in      al, dx
            test    al, 8
            jnz     wait_vr_start

        ; Wait for vertical retrace finish
        wait_vr_finish:
            in      al, dx,
            test    al, 8
            jz      wait_vr_finish

        mov     [ es:di ], byte bl
        cmp     cl, 1
        je      to_right

        ; To left
        sub     di, 1
        add     bl, 1

        cmp     bl, 63
        jl      end

        xor     bl, bl
        mov     cl, 1
        jmp     end

        to_right:
            add     di, 1
            add     bl, 1

            cmp     bl, 63
            jl      end

            xor     bl, bl
            xor     cl, cl

        end:

        ; Checks to see if a key is available in the keyboard buffer
        mov     ah, 1
        int     16h
        jz      main_loop

    ret



section      .data
score_str: 
    db      'score: ', 0
hiscore_str:
    db      'hiscore: ', 0
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

snake1:
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 9fh, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 9fh, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 9fh, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch

snake2:
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 9fh, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 9fh, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 9fh, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah

snake1_head:
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 00h, 00h, 00h, 00h, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 00h, 00h, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db      0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch

snake2_head:
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 00h, 00h, 00h, 00h, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 00h, 00h, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db      0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah


section     .bss
empty_block:
    resb    8 * 8
snake1_datax:
    resb    34 * 21
snake1_datay:
    resb    34 * 21
snake2_datax:
    resb    34 * 21
snake2_datay:
    resb    34 * 21
button1:
    resb    1
dir1:
    resb    1
button2:
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
