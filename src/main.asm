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


    ;call draw_interface
    call ini_field
    
    call upd_video

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

draw_interface: ; http://www.codenet.ru/progr/dos/int_0009.php    
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
    ret
    
ini_field:
    push    di
    
    lea     di, [field1]
    mov     [di], byte 2
    mov     [di + 1], byte 2
    mov     [di + 2], byte 2
    mov     [di + 3], byte 1

    pop     di
    ret    



upd_video:
    ; TODO: mul into shl
    ; TODO: check state
    push    ax
    push    cx
    push    di

    lea     di, [field1]

    mov     cx, 21
    uvl1:
        push    cx
        mov     ax, cx
        mov     cx, 34
        uvl2:
            push    cx
            mov     bx, cx
            
            mov     cx, di
            
            call    draw_block      ; ax = row, bx = column, cx = data_ptr
            

            pop     cx
            loop    uvl2

        pop     cx
        loop    uvl1


    pop     di
    pop     cx
    pop     ax
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
state:
    db      0
score_str: 
    db      'score: ', 0
hiscore_str:
    db      'hiscore: ', 0
game_over:
    db      0
score:
    db      0
hiscore:
    db      0
button_1:
    db      0
dir_1:
    db      0
button_2:
    db      0
dir_2:
    db      0
brick:
    db 06h, 0xa1, 06h, 06h, 06h, 0xa1, 06h, 06h,
    db 72h, 0xa1, 72h, 72h, 72h, 0xa1, 72h, 72h,
    db 06h, 06h, 06h, 0xa1, 06h, 06h, 06h, 0xa1,
    db 72h, 72h, 72h, 0xa1, 72h, 72h, 72h, 0xa1,
    db 06h, 0xa1, 06h, 06h, 06h, 0xa1, 06h, 06h,
    db 72h, 0xa1, 72h, 72h, 72h, 0xa1, 72h, 72h,
    db 06h, 06h, 06h, 0xa1, 06h, 06h, 06h, 0xa1,
    db 72h, 72h, 72h, 0xa1, 72h, 72h, 72h, 0xa1

snake1:
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 9fh, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 9fh, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 9fh, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch

snake2:
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 9fh, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 9fh, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 9fh, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah

snake1_head:
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 00h, 00h, 00h, 00h, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 00h, 00h, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch,
    db 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch, 0ch

snake2_head:
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 00h, 00h, 00h, 00h, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 00h, 00h, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah,
    db 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah, 0ah


section     .bss
field1:
    resb      34 * 21
field2:
    resb      34 * 21