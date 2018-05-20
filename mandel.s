global countMandelbrotAsm

section .text

countMandelbrotAsm:
        push    rbp
        mov     rbp, rsp

.putOnStack:
        movss   DWORD [rbp-68], xmm0    ; imageWidth
        movss   DWORD [rbp-72], xmm1    ; imageHeight
        movss   DWORD [rbp-76], xmm2    ; startX
        movss   DWORD [rbp-80], xmm3    ; endX
        movss   DWORD [rbp-84], xmm4    ; startY
        movss   DWORD [rbp-88], xmm5    ; endY
        mov     QWORD [rbp-96], rdi     ; *pixels

        movss   xmm0, DWORD [rbp-80]
        subss   xmm0, DWORD [rbp-76]
        divss   xmm0, DWORD [rbp-68]
        movss   DWORD [rbp-24], xmm0 ; ratioX = (endX - startX) / imageWidth;

        movss   xmm0, DWORD [rbp-88]
        subss   xmm0, DWORD [rbp-84]
        divss   xmm0, DWORD [rbp-72]
        movss   DWORD [rbp-28], xmm0 ; ratioY = (endY - startY) / imageHeight;

        mov     DWORD [rbp-4], 0 ; x = 0 <- columnCounter
.doNextColumn:
        cvtsi2ss        xmm0, DWORD [rbp-4]
        movss   xmm1, DWORD [rbp-68]
        ucomiss xmm1, xmm0
        jna     .end    ; if out of width, then end function

        cvtsi2ss        xmm0, DWORD [rbp-4]
        mulss   xmm0, DWORD [rbp-24]
        movss   xmm1, DWORD [rbp-76]
        addss   xmm0, xmm1
        movss   DWORD [rbp-32], xmm0    ; p_re = x*ratioX + startX

        mov     DWORD [rbp-8], 0 ; y = 0 <- pixelCounter
.doNextPixel:
        cvtsi2ss        xmm0, DWORD [rbp-8]
        movss   xmm1, DWORD [rbp-72]
        ucomiss xmm1, xmm0      ; if out of height, do another column
        jbe     .nextColumn

        cvtsi2ss        xmm0, DWORD [rbp-8]
        mulss   xmm0, DWORD [rbp-28]
        movss   xmm1, DWORD [rbp-84]
        addss   xmm0, xmm1
        movss   DWORD [rbp-36], xmm0 ; p_im = y*ratioY + startY;

        pxor    xmm0, xmm0
        movss   DWORD [rbp-12], xmm0 ; z_re = 0;
        pxor    xmm0, xmm0
        movss   DWORD [rbp-16], xmm0 ; z_im = 0;
        pxor    xmm0, xmm0
        movss   DWORD [rbp-40], xmm0 ; tmp_re = 0;
        pxor    xmm0, xmm0
        movss   DWORD [rbp-44], xmm0 ; tmp_im = 0;

        mov     DWORD [rbp-20], 0 ; iterations = 0
        mov     DWORD [rbp-48], 4 ; limit = 4
.iterationsLoop:
        movss   xmm0, DWORD [rbp-12]
        mulss   xmm0, xmm0      ; z_re*z_re

        movss   xmm1, DWORD [rbp-16]
        mulss   xmm1, xmm1      ; z_im*z_im

        subss   xmm0, xmm1      ; z_re^2 - z_im^2

        movss   xmm1, DWORD [rbp-32]
        addss   xmm0, xmm1      ; z_re*z_re - z_im*z_im + p_re

        movss   DWORD [rbp-40], xmm0 ; tmp_re = z_re*z_re - z_im*z_im + p_re

        movss   xmm0, DWORD [rbp-12]
        addss   xmm0, xmm0      ; 2*z_re
        mulss   xmm0, DWORD [rbp-16]    ; 2*z_re*z_im
        addss   xmm0, DWORD [rbp-36]    ; 2*z_re*z_im + p_im
        movss   DWORD [rbp-44], xmm0    ; tmp_im = 2*z_re*z_im + p_im
        
        movss   xmm0, DWORD [rbp-44]
        movss   DWORD [rbp-16], xmm0    ; z_im = tmp_im

        movss   xmm0, DWORD [rbp-40]
        movss   DWORD [rbp-12], xmm0    ; z_re = tmp_re

        add     DWORD [rbp-20], 1       ; iterations++

        mulss   xmm0, xmm0
        movss   xmm1, DWORD [rbp-16]
        mulss   xmm1, xmm1
        addss   xmm1, xmm0      ; z_re^2 + z_im^2

        cvtsi2ss        xmm0, DWORD [rbp-48]    ; limit goes as float to xmm0
        ucomiss xmm0, xmm1      ; limit > z_re^2 + z_im^2
        
        seta    al              ; if xmm0 > xmm1 set 1 to al
        xor     al, 1           ; if al == 1 then it will be 0
        test    al, al          ; if al == 0, then ZF = 1 (zero flag)
        jne     .startColoring  ; jump if ZF == 0, carry on if ZF == 1

        cmp     DWORD [rbp-20], 99      ; iterations < 100
        jg      .startColoring

        jmp     .iterationsLoop
.startColoring:
        cvtsi2ss        xmm0, DWORD [rbp-8]     ; convert pixelCounter to float
        mulss   xmm0, DWORD [rbp-68]            ; pixelCounter*imageWidth
        cvtsi2ss        xmm1, DWORD [rbp-4]     ; convert lineCounter to float
        addss   xmm0, xmm1                      ; pixelCounter*imageWidth + lineCounter
        cvttss2si       eax, xmm0               ; convert back to int
        cdqe                                    ; expand to rax
        lea     rdx, [0+rax*4]                  ; offset for array in rax and *4 cause unsigned int is 4 bytes in size
        mov     rax, QWORD [rbp-96]             ; load address of the beginning of array of pixels
        add     rax, rdx                        ; get pixel to color = address of array + offset

        cmp     DWORD [rbp-20], 1       ; iterations < 2
        jg      .colorOne
        mov     DWORD [rax], 0xFFFFFFFFFFF0A202
        jmp     .nextPixel

.colorOne:
        cmp     DWORD [rbp-20], 4       ; iterations <5
        jg      .colorTwo
        mov     DWORD [rax], 0xFFFFFFFFFFF18805
        jmp     .nextPixel
.colorTwo:
        cmp     DWORD [rbp-20], 7       ; iterations<8
        jg      .colorThree
        mov     DWORD [rax], 0xFFFFFFFFFFD95D39
        jmp     .nextPixel
.colorThree:
        cmp     DWORD [rbp-20], 11      ; iterations<12
        jg      .greyColor
        mov     DWORD [rax], 0xFFFFFFFFFF8D6A9F
        jmp     .nextPixel
.greyColor:
        cmp     DWORD [rbp-20], 99      ; iterations>=100 so the pixel is inside Mandelbrot Set
        jle     .colorFour
        mov     DWORD [rax], 0xFFFFFFFFFF222222
        jmp     .nextPixel
.colorFour:
        mov     DWORD [rax], 0xFFFFFFFFFF88958D
.nextPixel:
        add     DWORD [rbp-8], 1        ; pixelCounter++
        jmp     .doNextPixel
.nextColumn:
        add     DWORD [rbp-4], 1        ; columnCounter++
        jmp     .doNextColumn
.end:
        pop     rbp
        ret