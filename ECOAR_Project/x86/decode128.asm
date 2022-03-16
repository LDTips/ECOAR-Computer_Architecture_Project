; Sławomir Batruch - ECOAR Code 128 type C decoder
; index 303827

; General principle of operation is similar to the one from the MIPS project
section .data:
    codes:  dd  0x6CC, 0x66C, 0x666, 0x498, 0x48C, 0x44C, 0x4C8, 0x4C4,
            dd  0x464, 0x648, 0x644, 0x624, 0x59C, 0x4DC, 0x4Ce, 0x5CC,
            dd  0x4EC, 0x4E6, 0x672, 0x65C, 0x64E, 0x6E4, 0x674, 0x76E, 
            dd  0x74C, 0x72C, 0x726, 0x764, 0x734, 0x732, 0x6D8, 0x6C6, 
            dd  0x636, 0x518, 0x458, 0x446, 0x588, 0x468, 0x462, 0x688,
            dd  0x628, 0x622, 0x5B8, 0x58E, 0x46E, 0x5D8, 0x5C6, 0x476, 
            dd  0x776, 0x68E, 0x62E, 0x6E8, 0x6E2, 0x6EE, 0x758, 0x746, 
            dd  0x716, 0x768, 0x762, 0x71A, 0x77A, 0x642, 0x78A, 0x530, 
            dd  0x50C, 0x4B0, 0x486, 0x42C, 0x426, 0x590, 0x584, 0x4D0, 
            dd  0x4C2, 0x434, 0x432, 0x612, 0x650, 0x7BA, 0x614, 0x47A,
            dd  0x53C, 0x4BC, 0x49E, 0x5E4, 0x4F4, 0x4F2, 0x7A4, 0x794, 
            dd  0x792, 0x6DE, 0x6F6, 0x7B6, 0x578, 0x51E, 0x45E, 0x5E8, 
            dd  0x5E2, 0x7A8, 0x7A2, 0x5DE, 0x5EE, 0x75E, 0x7AE, 0x684, 
            dd  0x690, 0x69C, 0x18EB
; Same solution as for the MIPS project - list of values that correspond to the pattern

    %DEFINE starting_black_bar [EBP-4] ; Address of the first black pixel we start reading from ()
    %DEFINE bar_width [EBP-8] ; Stores the width of the smallest bar
    %DEFINE line [EBP-12] ; Stores our function argument regarding line to read 
    %DEFINE bytes_until_data [EBP-16] ; Offset for the data start of the line to read

    %DEFINE curr_pattern [EBP-20] ; Tracks current processed pattern to compare it to the code table
    %DEFINE processed_bar_shifts [EBP-24] ; Counts amount of bars processed

    %DEFINE processed_chars [EBP-28] ; Counter of processed chars. Used for arithmetic checksum ops
    %DEFINE prev_char [EBP-32] ; Used for arithmatic ops related to checksum (character multiplying)

    %DEFINE curr_checksum_elem [EBP-36] ; Used for arithmetic ops related to checksum
    %DEFINE prev_checksum_elem [EBP-40]

    %DEFINE decoded [EBP-44] ; Array of the decoded chars

    %DEFINE pix_address_holder [EBP-48] ; Used to store the address of pixel array
    ; Because at some point ESI register is needed, we use this var to store the address
section .text:
global decode128

decode128:
    ; Neccessary prologue stack and frame pointer manipulation
    ; Establish a stack frame
    PUSH EBP
    MOV EBP, ESP ; Set frame to stack pointer
    SUB ESP, 48 ; Set stack pointer to address holder (last elem) @ EBP-48
    ; Push and clear registers I will use
    PUSH ECX
    PUSH EBX
    PUSH EAX
    XOR ECX, ECX
    XOR EBX, EBX
    XOR EAX, EAX

    PUSH ESI
    PUSH EDI
    XOR ESI, ESI
    XOR EDI, EDI
    ; Zero defined variables on frame (unsure whether is needed)
    MOV starting_black_bar, EAX
    MOV bar_width, EAX
    MOV line, EAX
    MOV decoded, EAX
    MOV bytes_until_data, EAX
    MOV curr_pattern, EAX
    MOV processed_bar_shifts, EAX
    MOV processed_chars, EAX
    MOV prev_char, EAX
    MOV prev_checksum_elem, EAX
    MOV curr_checksum_elem, EAX
    MOV pix_address_holder, EAX

    ; Func call specification and modification.
    ; extern int decode128(unsigned char *source_bitmap, int scan_line_no, char *text);
    ; EBP+4 - Ret address (dont touch)
    ; EBP+8 - unsigned char* source_bitmap
    ; EBP+12 - int scan_line_no
    ; EBP+16 - char *text (arr we modify, OUTPUT)
    MOV ESI, [EBP+8] ; (1st arg)
    MOV EAX, [EBP+12] ; (2nd arg)
    MOV line, EAX ; Set our 2nd argument as line variable
    MOV EAX, [EBP+16] ; Our char array we will change (3rd arg)
    MOV decoded, EAX ; Set our decoded arr as decoded variable
move_to_line: ; This code snippets moves us to the line we will read from
    MOV EBX, line ; Used for MUL purposes
    MOV EAX, 1800 ; Bits of pixel data per line, 600 (width) * 3 (R/G/B)
    MUL EBX ; 1800 * line
    MOV bytes_until_data, EAX ; Store obtained data offset
    ADD ESI, bytes_until_data ; We have the line we're interested in. Offset is added into ESI
look_for_first_black:
    CMP BYTE [ESI], 0 ; If we found BYTE == 0, we found first black bar (pixel)
        JE first_black_found ; Jump
    CMP ECX, 599
        JE err_barcode_not_found ; If we traversed whole line (599 pixels) and didnt find a black pixel
    ADD ESI, 3 ; Pixel iterator. Each pixel has 3 bytes, hence +3
    INC ECX ; Bump pixel iterator
    JMP look_for_first_black ; Iterate until we find a black pixel
first_black_found:
    MOV starting_black_bar, ESI ; esi has the pixel offset
    XOR ECX, ECX ; Clear EBX used for iteration
find_smallest_bar:
    CMP BYTE [ESI], 0 ; FF is white. Finding white means end of bar
        JNE smallest_bar_found
    INC ECX ; Iterator for bar width
    CMP ECX, 15 ; If the bar is at least 15 pixels wide, that probably means...
    ; The whole barcode won't fit
        JE err_too_wide
    ADD ESI, 3 ; Progress into next pixel data
    JMP find_smallest_bar ; Iterate
smallest_bar_found:
    MOV EAX, ECX ; Prepare for division. We get the bar width from EBX
    MOV ECX, 2
    DIV ECX ; (div 2)
    ; After first bar, for every start code (which we checked), 
    ; there is a space, then a bar. 
    ; This bar and space are two times smaller than the first bar.
    ; Hence EAX will have the width of the smallest bar, according to abovementioned
    MOV bar_width, EAX
    MOV ESI, starting_black_bar ;
; Real stuff below - Reading the symbols
start_setup:
    XOR EAX, EAX ; Zero EAX reg
    MOV curr_pattern, EAX ; We reset the said vars... It matters for iterations, but not for the beginning
    MOV processed_bar_shifts, EAX
setup_bar:
    XOR ECX, ECX ; Zero ECX reg
    MOVZX EAX, BYTE[ESI] ; Move with zero extended so that shifting/OR works properly later on...
read_bar:
    MOVZX EAX, BYTE[ESI] ; fetch one byte to read
    INC ECX ; Iterate pixels processed count
    ADD ESI, 3 ; Iterate for pixel data.
    CMP ECX, bar_width
        JE determine_color ; If we have a bar equal to the smallest bar width
    JMP read_bar ; Iterate
determine_color:
    CMP EAX, 0x00000000 ; BLACK HEX
        JE found_black_bar
    ; Else it goes below to process a white bar
found_white_bar:
    MOV EAX, curr_pattern
    OR EAX, 0 ; As opposed to the way pixel data is stored...
    ; We indicate for the purpose of decoding the opposite way...
    ; 1 is black, and 0 is white. hence we OR with '0', because we process white
    MOV curr_pattern, EAX ; We update the pattern after processing it

    MOV EAX, processed_bar_shifts ; Move to EAX for processing 
    INC EAX ; Bump shift amount
    CMP EAX, 11 ; 11 is the width of a single character (amount of bars for a single char)
        JE found_full_pattern ; If we processed 11 bars, we got a full pattern
    MOV processed_bar_shifts, EAX ; Restore processed_bar_shifts

    MOV EAX, curr_pattern ; Move to EAX for processing
    SHL EAX, 1 ; We make place for a new bit by shifting to left by 1
    MOV curr_pattern, EAX ; Restore curr_pattern

    JMP setup_bar
; Below func. is similar to above. It's copy & paste with minor change
; The change is In the OR EAX instruction. We OR with 1 instead of 0 because...
; We process black bar this time
found_black_bar:
    MOV EAX, curr_pattern
    OR EAX, 1 ; As opposed to the way pixel data is stored...
    ; We indicate for the purpose of decoding the opposite way...
    ; 1 is black, and 0 is black. hence we OR with '1', because we process black
    MOV curr_pattern, EAX ; We update the pattern after processing it

    MOV EAX, processed_bar_shifts ; Move to EAX for processing 
    INC EAX ; Bump shift amount
    CMP EAX, 11 ; 11 is the width of a single character (amount of bars for a single char)
        JE found_full_pattern ; If we processed 11 bars, we got a full pattern
    MOV processed_bar_shifts, EAX ; Restore processed_bar_shifts

    MOV EAX, curr_pattern ; Move to EAX for processing
    SHL EAX, 1 ; We make place for a new bit by shifting to left by 1
    MOV curr_pattern, EAX ; Restore curr_pattern

    JMP setup_bar ; Iterate, process new bar
found_full_pattern:
    MOV processed_bar_shifts, EAX ; Restore processed_bar_shifts after doing the jump
    ; After Comparison that caused the jump...
    MOV pix_address_holder, ESI ; Since there is only one ESI reg, we need to store...
    ; Current pixel address. This is because we use ESI for something else below
    XOR ECX, ECX ; Zero ECX reg
    ; Setup for symbol finding:
    MOV ESI, codes ; Code arr into ESI
    MOV EAX, curr_pattern ; Curr_pattern into EAX for comparison
compare_pattern:
    MOV EBX, [ESI + ECX * 4]
    ; symbol to compare EBX, [Code array ESI + code_offset ECX * size of a single code (4 bytes)]
    CMP EBX, EAX ; Comparison...
        JNE code_not_eq
code_eq:
    ; Part 1 of the func. - checking if the character is a start character
    CMP ECX, 105 ; Our start character for code C
        JE start_code
    CMP ECX, 104 ; Invalid start code detected!
        JE err_invalid_set
    CMP ECX, 103 ; Invalid start code detected!
        JE err_invalid_set
    
    ; Part 2 - Checksum calculations
    ; (Start_symbol + (for every i(sum i * data_val[i])) mod 103. From ecoar project .pdf
    MOV EAX, processed_chars ; Move processed_chars into EAX for operations
    INC EAX ; Bump our 'i' for checksum calculations
    MOV processed_chars, EAX ; Restore...

    MOV prev_char, ECX
    MUL ECX ; Look formula above

    MOV prev_checksum_elem, EAX ; Store calculated i * data_val[i] into a variable...
    ADD EAX, curr_checksum_elem ; Add it to a curr_checksum_elem...
    MOV curr_checksum_elem, EAX ; And store it

    ; Part 3 - Adding our character to the decoded array
    MOV EAX, prev_char ; Prev_char into EAX for processing (adding into EDI arr)
    MOV EDI, decoded ; We will be filling decoded as array
    MOV [EDI], EAX ; Use EDI (decoded) as array, insert EAX (prev_char) into it
    INC EDI ; Increment index of array
    MOV decoded, EDI ; Restore (modify the decoded)
    MOV ESI, pix_address_holder ; Restore our address of pixel array place
    JMP start_setup ; Jump to the very start
code_not_eq:
    INC ECX ; Move the iterator
    CMP ECX, 106 ; 106 is a stop sign, so if we didnt find any code that would match...
    ; That means that we most likely encountered a stop sign
        JE stop_sign
    JMP compare_pattern ; Iterate and compare next pattern...
start_code:
    ; Add Start_symbol to the checksum var
    MOV curr_checksum_elem, ECX ; We add the current character value (start sign) to our checksum
    ; Could also be a hardcoded add 105
    MOV ESI, pix_address_holder ; Restore our address of pixel arr. place
    JMP start_setup
; As said in line 206 - CMP ECX, 106
; We need to handle stop sign behavior
stop_sign:
    XOR EAX, EAX ; Zero EAX reg
    MOV processed_bar_shifts, EAX ; Zero the shift amount
    MOV ESI, pix_address_holder ; Restore address of pixel arr. place
; Fetch 2 additional bars to determine correctness of the stop sign
; Note - most comments ommited due to very high similarity to the previous...
; Functions related to bar fetching. Some of them are even copied...
; But with some small changes
extra_setup_bar:
    MOVZX EAX, BYTE[ESI] 
    XOR ECX, ECX ; Clear iterator register
extra_read_bar:
    MOVZX EAX, BYTE[ESI]
    INC ECX
    ADD ESI, 3
    CMP ECX, bar_width
        JE extra_determine_color
    JMP extra_read_bar
extra_determine_color:
    CMP EAX, 0x00000000 ; BLACK HEX
        JE extra_found_black_bar
extra_found_white_bar:
    MOV EAX, curr_pattern
    SHL EAX, 1 ; We make place for a new bit by shifting to left by 1
    ; Here it needs to be done earlier because we already have a pattern being processed
    ; Whereas for the start of "OR" operations, at least one bit already exists...
    OR EAX, 0 ; As opposed to the way pixel data is stored...
    ; We indicate for the purpose of decoding the opposite way...
    ; 1 is black, and 0 is white. hence we OR with '0', because we process white
    MOV curr_pattern, EAX ; We update the pattern after processing it

    MOV EAX, processed_bar_shifts ; Move to EAX for processing 
    INC EAX ; Bump shift amount
    CMP EAX, 2 ; 2 is the amount of extra bars we need to process for the stop sign
        JE extra_found_full_pattern ; If we processed 2 bars, we got the extra stop sign bars
    MOV processed_bar_shifts, EAX ; Restore processed_bar_shifts

    JMP extra_setup_bar
; Below func. is similar to above. It's copy & paste with minor change
; The change is In the OR EAX instruction. We OR with 1 instead of 0 because...
; We process black bar this time
extra_found_black_bar:
    MOV EAX, curr_pattern
    SHL EAX, 1 ; We make place for a new bit by shifting to left by 1.
    ; Here it needs to be done earlier because we already have a pattern being processed
    ; Whereas for the start of "OR" operations, at least one bit already exists...
    OR EAX, 1 ; As opposed to the way pixel data is stored...
    ; We indicate for the purpose of decoding the opposite way...
    ; 1 is black, and 0 is black. hence we OR with '1', because we process black
    MOV curr_pattern, EAX ; We update the pattern after processing it

    MOV EAX, processed_bar_shifts ; Move to EAX for processing 
    INC EAX ; Bump shift amount
    CMP EAX, 2 ; 2 is the amount of extra bars we need to process for the stop sign
        JE extra_found_full_pattern ; If we processed 2 bars, we got the extra stop sign bars
    MOV processed_bar_shifts, EAX ; Restore processed_bar_shifts

    JMP extra_setup_bar ; Iterate, process new bar
; We check the corectness of the stop code
extra_found_full_pattern:
    MOV pix_address_holder, ESI ; Store the pixel array current address into a var
    MOV ESI, codes
    MOV ECX, 106
    MOV EBX, [ESI + ECX * 4] ; Address of stop sign
    ; Addressing explained at line 191

    MOV EAX, curr_pattern
    CMP EAX, EBX ; We check corectness of the stop sign from barcode
        JE code_correct
err_checksum_invalid:
    MOV EAX, 2
    JMP quit
    ; Return 2 and quit. The same for all err functions
code_correct:
    MOV EAX, curr_checksum_elem
    MOV EBX, prev_checksum_elem
    SUB EAX, EBX ; We dont want a check symbol in our checksum calculations...
    ; Hence we substract prev_checksum_elem, as the check symbol is stored there
    MOV EBX, 103
    DIV EBX ; EAX Modulo 103
    CMP EDX, prev_char ; Prev_char is our check symbol. EDX stores the remainder from division
        JE quit_correct
err_invalid_set:
    MOV EAX, 1
    JMP quit
err_barcode_not_found:
    MOV EAX, 3
    JMP quit
err_too_wide:
    MOV EAX, 4
    JMP quit
quit_correct:
    MOV EDI, decoded
    DEC EDI ; We moved the pointer to the next place, but in the end no character was inserted...
    ; Hence we decrement the pointer by 1 place
    MOV BYTE[EDI], 0 ; And also the last char is check char which we dont want to print (NULL) 
    XOR EAX, EAX ; Prepare to return 0 (correct return code)
quit:
    ; Pop used registers
    POP ECX
    POP EBX

    POP EDI
    POP ESI
    ; Epilogue frame and stack pointer manipulation
    MOV ESP, EBP ; Restore frame onto stack
    POP EBP ; Pop frame
    RET ; Return