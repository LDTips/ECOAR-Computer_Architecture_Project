# Slawomir Batruch - MIPS ECOAR project (Semester 2021L)
# Barcode 128 type C decoder

# General principle of the barcode reading is that the program reads a code bar by bar. If there is a black bar, it stores binary 1. For white, it stores 0
# Then after obtaining 11 bars (the length of a single code), it compared the obtained bars to every code in the table.
# This process is repeated, but if a stop character is detected (if the bars dont match any other character),
# Then two additional bars are read

.data
.include "codes.asm"
.align 4
buffer: .space 2
header: .space 54 # allocate header size from bmp file (metadata)
width: .word 600 # width of the .bmp file
height: .word 50 # height of the .bmp file
bits_pixel: .byte 24 # bits/pixel of the .bmp file
output: .word 200 # output arr

# stop_sequence: .word 0x18EB # Hardcoded comparison was implemented due to issues
# memory for the whole file is allocated later (based on the filesize shown in the .bmp file header)
# ---
# error handling strings:
descriptor_err: .asciiz "Descriptor invalid!"
metadata_filetype_err: .asciiz "File is not of .bmp type!" 
metadata_format_err: .asciiz "File is not 24-bit!" 
metadata_res_err: .asciiz "Invalid file resolution!" 
picture_barcode_err: .asciiz "No barcode found in the .bmp!"
picture_start_err: .asciiz "Invalid start character (A or B type barcode)!"
picture_finish_err: .asciiz "Invalid stop character!"
picture_checksum_err: .asciiz "Invalid barcode checksum!"
 
decoded_succesful: .asciiz "Decoding is complete. Decoded text:\n"
# Bmp file should be in the same folder as this sourcecode. Change name of it here
path: .asciiz "2.bmp" # 2018
# --- 
.text
open_file:
	li $v0, 13 # open file code for syscall
	la $a0, path # address of the file loaded into $a0
	li $a1, 0 # flags set to 0
	li $a2, 0 # mode also 0
	syscall # execute v0 instruction
	
	bltz $v0, descriptor_error # if v0 is < 0, there was a file descriptor error.
	move $s0, $v0 # move file descriptor to s0 register (otherwise line below will overwrite content from $v0 that we need)
	
	# checking the metadata from the .bmp file header:
	li $v0, 14 # read from file (code 14 syscall)
	move $a0, $s0 # load the file descriptor into the 1st argument of the syscall
	la $a1, header # load header address into a1
	li $a2, 54 # size of header
	syscall
	
	lhu $t0, header # .bmp file descriptor is 2 bytes, hence I use lhu (half-word is 2 bytes)
	la $s1, 0x4D42 # The value that the first two bytes should be in EVERY .bmp file. Hardcoded
	# note: I had issues with reading from predefined value in the program. Had to hardcode to avoid this issue
	bne $t0, $s1, metadata_filetype_error # compares the header of the file to the header of .bmp filetype. If they dont match, there is an header error
	
	# here we check width and height of the file
	
	lw $s1, header+18 # location where width of the file should be
	lw $t0, width # 600 pixels
	bne $t0, $s1, metadata_res_error # if width doesnt match, there is a file resolution error
	lw $s1, header+22 # location for height. Rest is analogical to width check
	lw $t0, height
	bne $t0, $s1, metadata_res_error
	# note - we check width and heigh one after another instead of immediately, because it can optimise program
	# If width is bad, the height won't be checked at all
	
	# check the format (bits per pixel). Should be 24
	lb $s1, header+28 # lb because this info is one byte
	lb $t0, bits_pixel # bits per pixel value the file should have
	bne $t0, $s1, metadata_format_error # if the bits/pixel is invalid, there is an error
	
	# memory allocation for the file:
	lw $s1, header+34 # location where the file size is stored in the bmp header
	# Theoretically this size could be stored as a constant value in the code, but fetching it from the file is ok too
	li $v0, 9 # allocate heap memory (sbrk) - syscall 9
	move $a0, $s1 # first argument - number of bytes to allocate will be the file size from the .bmp header
	syscall # execute $v0 instruction (allocate heap)
	move $s2, $v0 # move the address of the allocated memory to the s2 register. Is needed later when reading pixel data
	
	# reading pixel bytes from file
	li $v0, 14 # read from file - syscall 14
	move $a0, $s0 # File descriptor we saved earlier
	move $a1, $s2 # Address of the memory (the one we saved earlier from syscall 9)
	move $a2, $s1 # file size (we set $s4 to header+34 earlier - the size of file in bytes)
	syscall
	
close_file: # We close the file because we already got the data into our program memory
	li $v0, 16 # close file - syscall 16
	move $a0, $s0 # $s0 is the file descriptor to close - we pass it as first arg
	syscall


# Reading pixels from the file
move_pointer__setup:
	move $t9, $s2 # s2 is the memory address of the allocated heap
	li $t0, 20 # row to read
	li $t1, 1800 # 600 width * 3 (amount of bytes per pixel - R/G/B)
	li $t8, 0 # Used to check if we are at the end of the row
	mul $t0, $t0, $t1 # the place where we will start reading bytes
	addu $t9, $t9, $t0 # We move the memory pointer into the place where we want to read our bytes (we add offset to the address)
	# For even more future use (this was added after already writing code below)
	# I realised I need to do the following thing as well:
	la $a3, output # a3 will be used for output processing
	
search_black_pixel:
	lb $t0, ($t9) # Load one byte (pixel) into t0
	beqz $t0, black_pixel_found # black pixel has 00 00 00. White pixels have FF FF FF

	addiu $t9, $t9, 3 # Progress 3 bytes (1 pixel)
	addiu $t8, $8, 1 # Used to track the pixel we're at in a given row.
	beq $t8, 599, picture_barcode_error # If we didnt finy any black pixel after traversing whole row, then we can safely assume there is no barcode
	j search_black_pixel # Iterate
	
black_pixel_found:
	li $t1, 1 # Width tracker (starts at 1 because we already got one black bar)
	la $t7, ($t9) # Store the byte number where the black pixel is
	li $t8, 30 # Maximum lenght of a bar
	
find_bar_width:
	addiu $t7, $t7, 3 # we progress one pixel (we know first pixel is black)
	lb $t0, ($t7) # load current byte
	bnez $t0, bar_end # if the first byte of color is not 00, then the end of the black bar has been reached
	addiu $t1, $t1, 1 # Add 1 to the width
	
	beq $t1, $t8, picture_barcode_error # If max bar width exceeded
	j find_bar_width # Iterate
	
bar_end:
	divu $t8, $t1, 2 # After first bar, for every start code, there is a space, then a bar. This bar and space are two times smaller than the first bar.
	# So t8 has the value of the smallest bar
	
# "more serious" part below. Reading the whole barcode:

start_setup:
	li $s0, 0 # Used to indicate white
	li $s1, 1 # Used to indicate black
	xor $s2, $s2, $s2 # Used for tracking how many bars have been processed
	xor $s3, $s3, $s3 # Used for storing the pattern
	
iteration_setup:
	li $t1, 0 # Used for iteration purposes. Every different iteration it's reset to 0
	
fetch_bar:
	lb $t0, ($t9) # Load byte for analysis
	addiu $t1, $t1, 1 # Bump t1 by 1 to denote current surveyed column of the barcode
	addiu $t9, $t9, 3 # Move to the next color byte
	beq $t1, $t8, bar_found # Found 1 bar!
	j fetch_bar # iterate
	
bar_found:
	beq $t0, 0x00000000, black # hex for black
	# If it's not black, it branches to white below
	
white: 
	or $s3, $s3, $s0 # We use s3 for tracking the pattern. For this or, nothing is changed. White is denoted as 0
	addiu $s2, $s2, 1 # used for tracking the number of bits already processed for a symbol.
	beq $s2, 11, symbol_obtained # If there are 11 bits processed, then it's a symbol!
	sll $s3, $s3, 1 # We shift to left to "save" the already processed bit, in this case binary 0
	j iteration_setup # Iterate
	
black: # Same working principles as white function
	or $s3, $s3, $s1 # So in this case, LSB will change to 1
	addiu $s2, $s2, 1
	beq $s2, 11, symbol_obtained
	sll $s3, $s3, 1 # More important in this case - we need to save the binary 1.
	j iteration_setup # Iterate
	
symbol_obtained:
	li $t1, 0 # Reset iteration var. This time we use it to match the code
	la $t2, code_arr # Load the array of codes

# Symbol searching:
symbol_compare:
	lw $t3, ($t2) # Load a single code from the code_arr
	bne $s3, $t3, symbol_not_equal # If the codes mismatch. Remember - s3 is our binary symbol of length 11
	# If they dont, go below:
	
symbol_equal:
	# Check start symbols first
	beq $t1, 103, picture_start_error # Code A start symbol - invalid
	beq $t1, 104, picture_start_error # Code B start symbol - invalid
	beq $t1, 105, start # Code C start symbol - perfectly fine
	# Checksum calculations:
	# (Start_symbol + (for every i(sum i * data_val[i])) mod 103. Look ecoar project .pdf
	addiu $s4, $s4, 1 # "i", used for checksum calculations
	move $s5, $t1 # Fetch current symbol into s5 for arithemic op. purposes. last symbol fetched into s5 will be check symbol. Stop symbol processing is separate
	mulu $s6, $s4, $s5 # data_val[i] * i, store into s6
	addu $s7, $s7, $s6 # add it to $s7 which should be empty at the start (sum up)
	
	sb $t1, ($a3) # a3 used as array. Move t1 into 0-th index
	addiu $a3, $a3, 1 # Increment index for next value
	
	j start_setup # Scan a new symbol, start anew
	
start:
	addu $s7, $s7, $t1 # Add start symbol value to the checksum variable
	j start_setup # Scan a new symbol, start anew

symbol_not_equal:
	addiu $t1, $t1, 1 # Progress one code further in comparison
	beq $t1, 106, stop_detected # If all symbols are passed, then this symbol is a stop. stop has two extra bytes processed below in separate func.
	addiu $t2, $t2, 4 # Iterate to the next word in the array i.e. add offset (word is 4 bytes)
	j symbol_compare

stop_detected:
	xor $s2, $s2, $s2 # Same usage as in normal, previous bar merging (counting bars processed)
# Similar way of working to earlier setup functions. The names are extra_<Name of similar function>. Some comments ommited due to similarity

extra_setup:
	li $t1, 0

extra_fetch_bar:
	# Literally copied fetch_bar function, but with a change to function branches and jumps
	lb $t0, ($t9) # Load byte for analysis
	addiu $t1, $t1, 1 # Bump t1 by 1 to denote current surveyed column of the barcode
	addiu $t9, $t9, 3 # Move to the next color byte
	beq $t1, $t8, extra_bar_found # Found 1 bar!
	j extra_fetch_bar # iterate

extra_bar_found:
	beq $t0, 0x00000000, extra_black

extra_white:
	sll $s3, $s3, 1 # "Make place" For the additional bit
	or $s3, $s3, $s0 # So in this case, LSB will stay 0
	addiu $s2, $s2, 1 # Count bars
	beq $s2, 2, finish # we need to process two (additional) bytes for the stop sign
	j extra_setup # Iterate

extra_black: # Has the same principle as extra_white. Some comments ommited
	sll $s3, $s3, 1
	or $s3, $s3, $s1 # LSB here will change to 1
	addiu $s2, $s2, 1
	beq $s2, 2, finish
	j extra_setup # Iterate
	
# Finishing up, stop symbol check, checksum calculate, reading for printing out result

finish:
	# We check the closing symbol
	# xor $a1, $a1, $a1 # This doesn't help either
	# xor $a2, $a2, $a2 # Neither this
	# la $a1, stop_sequence # Load address of stop_sequence
	# lw $a2, ($a1) # Load word address a1 points to...
	# stop_sequence: .word 0x18EB
	# And somehow in debugging, a2 is not 18eb ??
	# Hence the program here branches to an error:
	# bne $s3, $a2, picture_finish_error # THIS DOESN'T WORK, except it should... Branches to error when it shouldnt
	bne $s3, 0x18eb, picture_finish_error # THIS WORKS. Direct, hardcoded compare

check_checksum:
	subu $s7, $s7, $s6 # Last symbol we've read before special reading of "stop", was a check symbol and s6 stores result of a sum i * data_val[i].
	# We don't want this result in our checksum calculations. Check symbol is not considered
	# s7 has a sum of i * data_val[i]
	li $t0, 103 # ... mod 103
	divu $s7, $t0 # result we're interested in will be stored in hi register
	xor $t0, $t0, $t0 # We clear to fetch the result from hi
	mfhi $t0 # Fetch remainder
	bne $t0, $s5, picture_checksum_error # Last value saved into s5 was the check symbol. We compare it to the value that it should be equal to, according to the checksum formula

close_up:
	subiu $a3, $a3, 1 # Move back the ptr by 1 (it was moved by 1 earlier for the next character, but no character was inserted after)
	li $t0, '\0' # We will be putting NUL at the end of the arr
	sb $t0, ($a3) # Replace the last symbol (check symbol) by null, so that we know when the code ends (neccessary to stop printing the code at the correct point)
	j print_exit

# --- errors:
# error handling strings:
# descriptor_err: .asciiz "Descriptor invalid!" # Fatal error, mostly file corruption or nonexistence
# metadata_filetype_err: .asciiz "File is not of .bmp type!" 
# metadata_format_err: .asciiz "File is not 24-bit!" # Not 24 bit depth
# metadata_res_err: .asciiz "Invalid file resolution!" # Invalid dimensions
# picture_barcode_err: .asciiz "No barcode found in the .bmp!"
# picture_start_err: .asciiz "Invalid start character (A or B type barcode)!"
# picture_finish_err: .asciiz "Invalid stop character!"
# picture_checksum_err: .asciiz "Invalid barcode checksum!"
descriptor_error:
	li $v0, 4 # print string - syscall 4
	la $a0, descriptor_err # load address of the predefined string to inform about error
	syscall # execute v0 instruction
	j exit # jumps to exit function
# error messages functions are the same as the function shown above. Comments are not written to not repeat info

metadata_filetype_error:
	li $v0, 4
	la $a0, metadata_filetype_err
	syscall
	j exit

metadata_format_error:
	li $v0, 4
	la $a0, metadata_format_err
	syscall
	j exit

metadata_res_error:
	li $v0, 4
	la $a0, metadata_res_err
	syscall
	j exit

picture_barcode_error:
	li $v0, 4
	la $a0, picture_barcode_err
	syscall
	j exit

picture_start_error:
	li $v0, 4
	la $a0, picture_start_err
	syscall
	j exit

picture_finish_error:
	li $v0, 4
	la $a0, picture_finish_err
	syscall
	j exit

picture_checksum_error:
	li $v0, 4
	la $a0, picture_checksum_err
	syscall
	j exit
# Exit
print_exit:
	li $v0, 4
	la $a0, decoded_succesful
	syscall

check_zero_start: # If there is a zero at the start, the syscall 1 won't print it. We have to do it manually
	lb $a0, output($t0)
	bgt $a0, 10, print_bytes # If the first digit doesn't begin with 0, skip 0 printing
	# Because for digits <10, they look like 01, 02, 03...
	# And the program won't print the first 0, hence this function exists to do this manually
	li $v0, 1 # Print integer
	la $a0, ($zero) # Load the zero
	syscall

print_bytes:
	lb $a0, output($t0) # Load ($t0)-th element from output arr
	beq $a0, '\0', exit # If the element is 0, that means we're at the end of the data we're interested in.
	li $v0, 1 # Print integer syscall
	syscall
	addiu $t0, $t0, 1 # Iterator++ - Progress in the output arr
	j print_bytes # Iterate

exit:
	li $v0, 10 # exit - syscall 10
	syscall # ends the program
