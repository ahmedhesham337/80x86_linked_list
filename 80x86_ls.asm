;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;
;;   A linked list proof of concept written in 80x86 assembly   ;;
;;                                                              ;;
;;              Assembly Language 2023 Course Project           ;;
;;              Ahmed Hesham (1000236438) - section 2           ;;
;;              17/12/2023                                      ;;
;;                                                              ;;
;;              compiles with TASM (Turbo) assembler            ;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;
;
;
;
;
;
;
;
jumps                                                                            ; enable extended jumps
.MODEL SMALL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; DATA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.DATA   
    
    _sym_lin1            db "*********************************************", 0ah, 0dh, '$'
    _sym_lin2            db "*                                           *", 0ah, 0dh, '$'
    _sym_newl            db 0ah, 0dh, '$'
    _sym_arr             db " --> ", '$'
    
    _msg_title           db "* 80x86 Assembly Linked List Implementation *", 0ah, 0dh, '$'
    _msg_lnkl            db 0ah,"List Length: ", '$'
    _msg_opt0            db "Select an option: ", 0ah, 0dh, '$'
    _msg_opt1            db "1. View list", 0ah, 0dh, '$'
    _msg_opt2            db "2. Get element by index", 0ah, 0dh, '$'
    _msg_opt3            db "3. Delete element by index", 0ah, 0dh, '$'
    _msg_opt4            db "4. Insert a new element", 0ah, 0dh, '$'
    _msg_opt5            db "5. Exit", 0ah, 0dh, '$'
    _msg_opt6            db "Option: ", '$'
    _msg_err_op          db 0ah,"Error: Invalid option", 0ah, 0dh, '$'
    _msg_err_em          db 0ah,"Error: List is empty", 0ah, 0dh, '$'
    _msg_err_ix          db 0ah,"Error: Invalid Index", 0ah, 0dh, '$'
    _msg_err_mx          db 0ah,"Error: Maximum size is reached", 0ah, 0dh, '$'
    _msg_op1_1           db 0ah, 0ah, "List: ", '$'
    _msg_op2_1           db "Index (starting from 0): ", '$'
    _msg_op2_2           db "Element: ", '$'
    _msg_op2_3           db "Invalid Index", 0ah, 0dh, '$'
    _msg_op4_1           db "Value (1 char): ", '$'
    
    _lnk_nodes           dw 0000h
    
    _options_jmptable    dw offset _options_opt1, offset _options_opt2, offset _options_opt3, offset _options_opt4 
    
    _lnk_head_ptr        dw offset _lnk_head
    _lnk_tail_ptr        dw offset _lnk_head
    _lnk_head            dw 0000h, 0000h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;
;
;
;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; CODE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.CODE
    
_print_string proc                                                               ; INT 21h / AH=09h - output of a string at DS:DX.
    mov ah, 09h
    int 21h
    ret
_print_string endp

_print_char proc                                                                 ; INT 21h / AH=02h - write character to standard output, DL = character to write.
    mov ah, 02h
    int 21h
    ret
_print_char endp

_read_char proc                                                                  ; INT 21h / AH=01h - read character from standard input, with echo, result is stored in AL.
    mov ah, 01h
    int 21h
    ret
_read_char endp
    
_char_to_int proc                                                                ; ASCII(n) = n + 0x30
    sub dx, 30h
    ret
_char_to_int endp

_char_to_int_2 proc                                                              ; convert a string of two digits to int
    cmp dl, 0dh                                                                  ; check if second digit is a line feed character
    je _char_to_int_2_one_digit                                                  ; if line feed then string is one digit
    _char_to_int_2_two_digits:                                                   ; convert a string of two digits
        sub dl, 30h                                                              ; ASCII(n) = n + 0x30
        sub dh, 30h                                                              ; ASCII(n) = n + 0x30
        cmp dl, 09h                                                              ; make sure both chars are valid digits
        jg _char_to_int_2_error                                                  ; that is for every char converted to int
        cmp dh, 09h                                                              ; 0 <= int <= 9 must be true
        jg _char_to_int_2_error                                                  ; jmp to _char_to_int_2_error
        cmp dl, 00h                                                              ; if one of the chars was not 
        jl _char_to_int_2_error                                                  ; a valid decimal digit
        cmp dh, 00h                                                              ; -
        jl _char_to_int_2_error                                                  ; -
        xor ax, ax                                                               ; zero out ax
        mov al, dh                                                               ; mov first digit to al
        mov cx, 0ah                                                              ; mov 10 to cx
        mov bx, dx                                                               ; save dx in bx (dx will be overwritten after multiplication)
        mul cx                                                                   ; al = al * cx = first digit * 10
        mov dx, bx                                                               ; restore dx
        xor dh, dh                                                               ; zero out dh
        add ax, dx                                                               ; add second digit to ax
        mov dx, ax                                                               ; store result in dx
        ret
    _char_to_int_2_one_digit:                                                    ; convert one char to int
        mov al, dh                                                               ; mov char to al
        sub al, 30h                                                              ; convert to int
        xor ah, ah                                                               ; zero out ah
        mov dx, ax                                                               ; store result in dx
        ret
    _char_to_int_2_error:
        mov dx, 0ffffh                                                           ; mov 0xffff to dx (error flag)
        ret
_char_to_int_2 endp

_int_to_char proc                                                                ; ASCII(n) = n + 0x30
    add dx, 30h
    ret
_int_to_char endp

_int_to_char_2 proc                                                              ; convert int of two digits to a string
    mov ax, dx                                                                   ; mov int to ax
    mov bl, 0ah                                                                  ; mov 10 to bl
    div bl                                                                       ; ax / bl ---> al = ax / bl (first digit), ah = al % bl (second digit)
    mov dh, al                                                                   ; mov first digit to dh
    mov dl, ah                                                                   ; mov second digit to dl
    add dh, 30h                                                                  ; convert to char
    add dl, 30h                                                                  ; convert to char
    ret
_int_to_char_2 endp

_print_banner proc
    lea dx, _sym_lin1                                                            ; load _sym_lin1 address to dx
    call _print_string                                                           ; print "********************************************\n"
    
    lea dx, _msg_title                                                           ; load _msg_title address to dx
    call _print_string                                                           ; print "* 8086 Assembly Linked List Implementation *\n"
    
    lea dx, _sym_lin2                                                            ; load _sym_lin2 address to dx
    call _print_string                                                           ; print "*                                          *\n"
    
    lea dx, _sym_lin1                                                            ; load _sym_lin1 address to dx
    call _print_string                                                           ; print "********************************************\n"
    
    ret
_print_banner endp

_options_opt1 proc                                                               ; view list
    lea dx, _sym_newl                                                            ; load _sym_newl address to dx
    call _print_string                                                           ; print "\n"
    
    mov ax, [_lnk_nodes]                                                         ; load number of nodes to ax
    cmp ax, 00h                                                                  ; check if list is empty
    je _options_opt1_empty_list                                                  ; jmp to _options_opt1_empty_list if list is empty
    _options_opt1_show_list:
        lea dx, _msg_op1_1                                                       ; load _msg_op1_1 address to dx
        call _print_string                                                       ; print "\n\nList:" 
        mov bx, [_lnk_head_ptr]                                                  ; load list head pointer
        mov si, bx                                                               ; into si
        _options_opt1_show_list_traversal_loop:                                  ; traverse the list
            mov dx, [si]                                                         ; load node_ptr->data to dx
            call _print_char                                                     ; print element
            lea dx, _sym_arr                                                     ; load _sym_arr address to dx
            call _print_string                                                   ; print " --> "
            add si, 02h                                                          ; si = node_ptr->next*
            cmp word ptr [si], 00h                                               ; check if node_ptr->next is null
            je _options_opt1_show_list_traversal_loop_exit                       ; if null then reached the end
            mov bx, [si]                                                         ; load node_ptr->next 
            mov si, bx                                                           ; to si
            jmp _options_opt1_show_list_traversal_loop                           ; repeat 
            _options_opt1_show_list_traversal_loop_exit:
                ret
        ret
    _options_opt1_empty_list:                                                    ; print error when list is empty
        lea dx, _msg_err_em                                                      ; load _msg_err_em address to dx
        call _print_string                                                       ; print "\nError: List is empty\n"
        ret
_options_opt1 endp    

_options_opt2 proc                                                               ; get element by index
    lea dx, _sym_newl                                                            ; load _sym_newl address to dx
    call _print_string                                                           ; print "\n"
    
    mov ax, [_lnk_nodes]                                                         ; load number of nodes to ax
    cmp ax, 00h                                                                  ; check if list is empty
    je _options_opt2_empty_list                                                  ; jmp to _options_opt2_empty_list if list is empty
    _options_opt2_get_element:
        lea dx, _msg_op2_1                                                       ; load _msg_op2_1 address to dx
        call _print_string                                                       ; print "Index (starting from 0): "
        call _read_char                                                          ; read index from user (first digit)
        xor dx, dx                                                               ; zero out dx
        mov dh, al                                                               ; mov read char to dh
        call _read_char                                                          ; read index from user (second digit)
        mov dl, al                                                               ; mov read char to dl
        call _char_to_int_2                                                      ; convert string to int
        cmp dx, 0ffffh                                                           ; test for error flag
        je _options_opt2_invalid_idx                                             ; jmp to _options_opt2_invalid_idx if index is invalid
        mov ax, [_lnk_nodes]                                                     ; load number of nodes to ax
        sub ax, 01h                                                              ; subtract 1 from number of nodes to match index
        cmp dx, ax                                                               ; make sure 0 <= idx <= list size
        jg _options_opt2_invalid_idx                                             ; -
        cmp dx, 0000h                                                            ; jmp to _options_opt2_invalid_idx if index is out of bounds
        jl _options_opt2_invalid_idx                                             ; -
        mov cx, dx                                                               ; load loop counter with given index
        inc cx                                                                   ; increment loop counter to loop correct number of times
        lea dx, _sym_newl                                                        ; load _sym_newl address to dx
        call _print_string                                                       ; print "\n"
        lea dx, _msg_op2_2                                                       ; load _msg_op2_2 address to dx
        call _print_string                                                       ; print "Element: "
        mov bx, [_lnk_head_ptr]                                                  ; load list head pointer
        mov si, bx                                                               ; to si
        jmp _options_opt2_get_element_traversal_loop_init                        ; jmp to loop instruction
        _options_opt2_get_element_traversal_loop:                                ; traverse the list
            add si, 02h                                                          ; si = node_ptr->next*
            mov bx, [si]                                                         ; bx = node_ptr->next
            mov si, bx                                                           ; si = node_ptr->next
        _options_opt2_get_element_traversal_loop_init:
            loop _options_opt2_get_element_traversal_loop                        ; repeat until desired element is reached
        mov dx, [si]                                                             ; dx = node_ptr->data
        call _print_char                                                         ; print node_ptr->data
        lea dx, _sym_newl                                                        ; load _sym_newl address to dx
        call _print_string                                                       ; print "\n"
        ret
            
    _options_opt2_empty_list:                                                    ; print error when list is empty
        lea dx, _msg_err_em                                                      ; load _msg_err_em address to dx
        call _print_string                                                       ; print "\nError: List is empty\n"
        ret
    _options_opt2_invalid_idx:                                                   ; print error when index is invalid
        lea dx, _sym_newl                                                        ; load _sym_newl address to dx
        call _print_string                                                       ; print "\n"
        lea dx, _msg_err_ix                                                      ; load _msg_err_ix address to dx
        call _print_string                                                       ; print "\nError: Invalid Index\n"
        ret
_options_opt2 endp

_options_opt3 proc                                                               ; delete element by index
    lea dx, _sym_newl                                                            ; load _sym_newl address to dx
    call _print_string                                                           ; print "\n"
    
    mov ax, [_lnk_nodes]                                                         ; load number of nodes to ax
    cmp ax, 00h                                                                  ; check if list is empty
    je _options_opt3_empty_list                                                  ; jmp to _options_opt3_empty_list if list is empty
    _options_opt3_delete_element:
        lea dx, _msg_op2_1                                                       ; load _msg_op2_1 address to dx
        call _print_string                                                       ; print "Index (starting from 0): "
        call _read_char                                                          ; read index from user (first digit)
        xor dx, dx                                                               ; zero out dx
        mov dh, al                                                               ; mov read char to dh
        call _read_char                                                          ; read index from user (second digit)
        mov dl, al                                                               ; mov read char to dl
        call _char_to_int_2                                                      ; convert to int
        cmp dx, 0ffffh                                                           ; test for error flag
        je _options_opt3_invalid_idx                                             ; jmp to _options_opt3_invalid_idx if invalid index
        mov ax, [_lnk_nodes]                                                     ; load number of nodes to ax
        sub ax, 01h                                                              ; subtract 1 from number of nodes to match index
        cmp dx, 0000h                                                            ; check if given index <= 0
        jl _options_opt3_invalid_idx                                             ; jmp to _options_opt3_invalid_idx if index is less than 0
        je _options_opt3_delete_element_delete_head                              ; jmp to _options_opt3_delete_element_delete_head if index is 0
        cmp dx, ax                                                               ; check if given index >= number of nodes
        jg _options_opt3_invalid_idx                                             ; jmp to _options_opt3_invalid_idx if index is out of bounds
        jne _options_opt3_delete_element_delete_mid                              ; jmp to _options_opt3_delete_element_delete_mid if index != last index
        _options_opt3_delete_element_delete_tail:                                ; handle special case 1 of deleting the list tail
            mov bp, 0ffffh                                                       ; set bp to 0xffff, used as a flag further in the code
        _options_opt3_delete_element_delete_mid:                                 ; handle regular case of deleting a mid node
            mov cx, dx                                                           ; load loop counter with given index
            inc cx                                                               ; increment loop counter to loop correct number of times
            mov bx, [_lnk_head_ptr]                                              ; load list head pointer
            mov si, bx                                                           ; to si
            jmp _options_opt3_delete_element_traversal_loop_init                 ; jmp to loop controller
            _options_opt3_delete_element_traversal_loop:                         ; traverse the list
                add si, 02h                                                      ; si = node_ptr->next*
                mov bx, [si]                                                     ; bx = node_ptr->next
                mov si, bx                                                       ; si = node_ptr->next
            _options_opt3_delete_element_traversal_loop_init:                    ; loop controller
                cmp cx, 02h                                                      ; check if current node is the one before the one to be deleted
                jne _options_opt3_delete_element_traversal_loop_cont             ; if it's not then continue
                mov di, si                                                       ; load the node pointer to di
                _options_opt3_delete_element_traversal_loop_cont:                ; invoke the loop instruction
                    loop _options_opt3_delete_element_traversal_loop             ; repeat
                                                                                 ; after loop finishes:
                                                                                 ; di = prev
                                                                                 ; si = node to be deleted (dnode)
                                                                                 ; should assign prev->next to dnode->next
            add si, 02h                                                          ; si = dnode->next*
            mov ax, [si]                                                         ; ax = dnode->next
            add di, 02h                                                          ; di = prev->next*
            mov [di], ax                                                         ; prev->next = dnode->next
            cmp bp, 0ffffh                                                       ; check if special case 1 (list tail deletion) flag is set
            jne _options_opt3_delete_element_delete_mid_fin                      ; if not set jmp to _options_opt3_delete_element_delete_mid_fin
            _options_opt3_delete_element_delete_mid_adjust_tail:                 ; handle special case 1 (list tail deletion)
                sub di, 02h                                                      ; di = prev*
                lea bx, _lnk_tail_ptr                                            ; load (list tail pointer)* to bx
                mov [bx], di                                                     ; set tail pointer to correct last node
                xor bp, bp                                                       ; zero out bp
            _options_opt3_delete_element_delete_mid_fin:                         ; perform finish tasks
                lea dx, _sym_newl                                                ; load _sym_newl address to dx
                call _print_string                                               ; print "\n"
                mov dx, [_lnk_nodes]                                             ; load number of nodes to dx
                dec dx                                                           ; decrement dx to reflect the deleted node result
                mov [_lnk_nodes], dx                                             ; update number of nodes
                cmp dx, 00h                                                      ; check if the new number of nodes is 0
                je _options_opt3_delete_element_delete_mid_fin_cleanup           ; jmp to _options_opt3_delete_element_delete_mid_fin_cleanup if zero
                ret
                _options_opt3_delete_element_delete_mid_fin_cleanup:             ; reset data to its initial state
                    lea bx, _lnk_head                                            ; load address of list head to bx
                    lea di, _lnk_head_ptr                                        ; load address of list head pointer to di
                    mov [di], bx                                                 ; set list head pointer to address of list head
                    lea di, _lnk_tail_ptr                                        ; load address to list tail pointer to di
                    mov [di], bx                                                 ; set list tail pointer to address of list head
                    mov word ptr [bx], 0000h                                     ; set data of list head to 0
                    add bx, 02h                                                  ; set bx to list_head->next*
                    mov word ptr [bx], 0000h                                     ; set list_head->next to null
                    ret
        _options_opt3_delete_element_delete_head:                                ; handle special case 2 of deleting list head
            mov bx, [_lnk_head_ptr]                                              ; load list head pointer
            mov si, bx                                                           ; to si
            add si, 02h                                                          ; si = list_head->next*
            mov di, [si]                                                         ; di = list_head->next
            lea bx, _lnk_head_ptr                                                ; load address of list head pointer to bx
            mov [bx], di                                                         ; set the list head pointer to list_head->next
            jmp _options_opt3_delete_element_delete_mid_fin                      ; jmp to _options_opt3_delete_element_delete_mid_fin
            ret          
    _options_opt3_empty_list:                                                    ; print error when list is empty
        lea dx, _msg_err_em                                                      ; load _msg_err_em address to dx
        call _print_string                                                       ; print "\nError: List is empty\n"
        ret                                                                      
    _options_opt3_invalid_idx:                                                   ; print error when index is invalid
        lea dx, _sym_newl                                                        ; load address of _sym_newl to dx
        call _print_string                                                       ; print "\n"
        lea dx, _msg_err_ix                                                      ; load address of _msg_err_ix to dx
        call _print_string                                                       ; print "\nError: Invalid Index\n"
        ret
_options_opt3 endp

_options_opt4 proc                                                               ; insert a new element
    lea dx, _sym_newl                                                            ; load address of _sym_newl to dx
    call _print_string                                                           ; print "\n"
    mov ax, [_lnk_nodes]                                                         ; load number of nodes to ax
    cmp ax, 32h                                                                  ; check if number of nodes reached the maximum of 50 nodes
    je _options_opt4_err_max                                                     ; jmp to _options_opt4_err_max if max is reached
    lea dx, _msg_op4_1                                                           ; load address of _msg_op4_1 to dx
    call _print_string                                                           ; print "Value (1 char): "
    call _read_char                                                              ; read character from user
    xor dx, dx                                                                   ; zero out dx
    mov dl, al                                                                   ; mov read character to dl                                                            ; convert to int
    mov ax, [_lnk_nodes]                                                         ; load number of nodes to ax
    cmp ax, 0000h                                                                ; check if number of nodes is zero
    je _options_opt4_first_node                                                  ; jump to _options_opt4_first_node if zero
    _options_opt4_not_first_node:                                                ; add a new node to an already existing list
        mov bx, [_lnk_tail_ptr]                                                  ; load address of list tail 
        mov si, bx                                                               ; to si
        add bx, 02h                                                              ; bx = list_tail-next*
        add si, 04h                                                              ; si = pointer to undefined data (new node address)
        mov [bx], si                                                             ; list_tail->next = new_node*
        mov _lnk_tail_ptr, si                                                    ; list_tail* = new_node*
        mov [si], dx                                                             ; new_node->data = dx
        mov word ptr [si+2], 00h                                                 ; new_node->next = null
        mov dx, [_lnk_nodes]                                                     ; load number of nodes to dx
        inc dx                                                                   ; increment dx to reflect the new number of nodes
        mov [_lnk_nodes], dx                                                     ; update number of nodes
        ret
        
    _options_opt4_first_node:                                                    ; handle special case of initializing an empty list
        mov [_lnk_head], dx                                                      ; reserved_link_head->data = dx
        mov dx, [_lnk_nodes]                                                     ; load number of nodes to dx
        inc dx                                                                   ; increment dx to reflect the new number of nodes
        mov [_lnk_nodes], dx                                                     ; update number of nodes
        ret
    _options_opt4_err_max:
        lea dx, _msg_err_mx
        call _print_string
        ret
_options_opt4 endp
    
_options_menu proc                                                               ; display options and wait for user input
    lea dx, _sym_newl                                                            ; load address of _sym_newl to dx
    call _print_string                                                           ; print "\n"
    
    lea dx, _msg_lnkl                                                            ; load address of _msg_lnkl to dx
    call _print_string                                                           ; print "List Length: "
    
    mov dx, [_lnk_nodes]                                                         ; load number of nodes to dx
    call _int_to_char_2                                                          ; convert to string
    mov bx, dx                                                                   ; mov string to bx
    mov dl, bh                                                                   ; mov first char to dl
    call _print_char                                                             ; print char
    mov dl, bl                                                                   ; mov second char to dl
    xor bx, bx                                                                   ; zero out bx 
    call _print_char                                                             ; print second char
    
    lea dx, _sym_newl                                                            ; load address of _sym_newl to dx
    call _print_string                                                           ; print "\n"
    
    lea dx, _msg_opt0                                                            ; load address of _msg_opt0 to dx
    call _print_string                                                           ; print "Select an option: \n"
    
    lea dx, _msg_opt1                                                            ; load address of _msg_opt1 to dx
    call _print_string                                                           ; print "1. View list\n"
    
    lea dx, _msg_opt2                                                            ; load address of _msg_opt2 to dx
    call _print_string                                                           ; print "2. Get element by index\n"
    
    lea dx, _msg_opt3                                                            ; load address of _msg_opt3 to dx
    call _print_string                                                           ; print "3. Delete element by index\n"
    
    lea dx, _msg_opt4                                                            ; load address of _msg_opt4 to dx
    call _print_string                                                           ; print "4. Insert a new element\n"
    
    lea dx, _msg_opt5                                                            ; load address of _msg_opt5 to dx
    call _print_string                                                           ; print "5. Exit\n"
    
    lea dx, _msg_opt6                                                            ; load address of _msg_opt6 to dx
    call _print_string                                                           ; print "Option: \n"
    
    call _read_char                                                              ; read character from user
    xor dx, dx                                                                   ; zero out dx
    mov dl, al                                                                   ; mov read char to dl
    call _char_to_int                                                            ; convert to int
    
    cmp dl, 05h                                                                  ; check if read option <= 5 
    jg _options_menu_err                                                         ; jmp to _options_menu_err if > 5
    je _options_menu_exit                                                        ; handle exit

    cmp dl, 01h                                                                  ; check if read option > 1
    jl _options_menu_err                                                         ; jmp to _options_menu_err if < 1
    
    
    _options_menu_call_option:                                                   ; handle option
        sub dl, 01h                                                              ; decrement option number
        shl dx, 01h                                                              ; multiply option number by 2 (serves as idx*scale)
        lea si, _options_jmptable                                                ; load address of jump table to si
        mov bp, dx                                                               ; mov idx*scale to bp
        add si, bp                                                               ; add idx*scale to base (jump table) in si to calculate function pointer pointer
        mov ax, [si]                                                             ; dereference pointer
        call ax                                                                  ; call function
    
        jmp _options_menu                                                        ; start over
    
    _options_menu_err:                                                           ; handle invalid option number
        lea dx, _sym_newl                                                        ; load address of _sym_newl to dx
        call _print_string                                                       ; print "\n"
        lea dx, _msg_err_op                                                      ; load address of _msg_err_op to dx
        call _print_string                                                       ; print
        
        jmp _options_menu                                                        ; start over
    
    _options_menu_exit:
        ret
_options_menu endp
    

_main_menu proc
    call _print_banner
    call _options_menu
    ret
_main_menu endp

start proc far
    .STARTUP
    call _main_menu
    .EXIT
start endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end start                                                                        ; set entrypoint to start