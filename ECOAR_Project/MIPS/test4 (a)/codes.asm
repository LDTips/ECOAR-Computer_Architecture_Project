# These are the binary values of the codes converted into hexadecimal
# look on the comments after every code
# I hope this "simple" workaround for the remark saying that binary values of codes can't be stored is allowed
.data
code_arr:			  # pattern:
code0: .word 0x6CC # 11 0 11 00 11 00
code1: .word 0x66C # 11 00 11 0 11 00
code2: .word 0x666 # 11 00 11 00 11 0
code3: .word 0x498 # 1 00 1 00 11 000
code4: .word 0x48C # 1 00 1 000 11 00
code5: .word 0x44C # 1 000 1 00 11 00
code6: .word 0x4C8 # 1 00 11 00 1 000
code7: .word 0x4C4 # 1 00 11 000 1 00
code8: .word 0x464 # 1 000 11 00 1 00
code9: .word 0x648 # 11 00 1 00 1 000
code10: .word 0x644 # 11 00 1 000 1 00
code11: .word 0x624 # 11 000 1 00 1 00
code12: .word 0x59C # 1 0 11 00 111 00
code13: .word 0x4DC # 1 00 11 0 111 00
code14: .word 0x4CE # 1 00 11 00 111 0
code15: .word 0x5CC # 1 0 111 00 11 00
code16: .word 0x4EC # 1 00 111 0 11 00
code17: .word 0x4E6 # 1 00 111 00 11 0
code18: .word 0x672 # 11 00 111 00 1 0
code19: .word 0x65C # 11 00 1 0 111 00
code20: .word 0x64E # 11 00 1 00 111 0
code21: .word 0x6E4 # 11 0 111 00 1 00
code22: .word 0x674 # 11 00 111 0 1 00
code23: .word 0x76E # 111 0 11 0 111 0
code24: .word 0x74C # 111 0 1 00 11 00
code25: .word 0x72C # 111 00 1 0 11 00
code26: .word 0x726 # 111 00 1 00 11 0
code27: .word 0x764 # 111 0 11 00 1 00
code28: .word 0x734 # 111 00 11 0 1 00
code29: .word 0x732 # 111 00 11 00 1 0
code30: .word 0x6D8 # 11 0 11 0 11 000
code31: .word 0x6C6 # 11 0 11 000 11 0
code32: .word 0x636 # 11 000 11 0 11 0
code33: .word 0x518 # 1 0 1 000 11 000
code34: .word 0x458 # 1 000 1 0 11 000
code35: .word 0x446 # 1 000 1 000 11 0
code36: .word 0x588 # 1 0 11 000 1 000
code37: .word 0x468 # 1 000 11 0 1 000
code38: .word 0x462 # 1 000 11 000 1 0
code39: .word 0x688 # 11 0 1 000 1 000
code40: .word 0x628 # 11 000 1 0 1 000
code41: .word 0x622 # 11 000 1 000 1 0
code42: .word 0x5B8 # 1 0 11 0 111 000
code43: .word 0x58E # 1 0 11 000 111 0
code44: .word 0x46E # 1 000 11 0 111 0
code45: .word 0x5D8 # 1 0 111 0 11 000
code46: .word 0x5C6 # 1 0 111 000 11 0
code47: .word 0x476 # 1 000 111 0 11 0
code48: .word 0x776 # 111 0 111 0 11 0
code49: .word 0x68E # 11 0 1 000 111 0
code50: .word 0x62E # 11 000 1 0 111 0
code51: .word 0x6E8 # 11 0 111 0 1 000
code52: .word 0x6E2 # 11 0 111 000 1 0
code53: .word 0x6EE # 11 0 111 0 111 0
code54: .word 0x758 # 111 0 1 0 11 000
code55: .word 0x746 # 111 0 1 000 11 0
code56: .word 0x716 # 111 000 1 0 11 0
code57: .word 0x768 # 111 0 11 0 1 000
code58: .word 0x762 # 111 0 11 000 1 0
code59: .word 0x71A # 111 000 11 0 1 0
# sequences containing widths of 4
code60: .word 0x77A # 111 0 1111 0 1 0
code61: .word 0x642 # 11 00 1 0000 1 0
code62: .word 0x78A # 1111 000 1 0 1 0
code63: .word 0x530 # 1 0 1 00 11 0000
code64: .word 0x50C # 1 0 1 0000 11 00
code65: .word 0x4B0 # 1 00 1 0 11 0000
code66: .word 0x486 # 1 00 1 0000 11 0
code67: .word 0x42C # 1 0000 1 0 11 00
code68: .word 0x426 # 1 0000 1 00 11 0
code69: .word 0x590 # 1 0 11 00 1 0000
code70: .word 0x584 # 1 0 11 0000 1 00
code71: .word 0x4D0 # 1 00 11 0 1 0000
code72: .word 0x4C2 # 1 00 11 0000 1 0
code73: .word 0x434 # 1 0000 11 0 1 00
code74: .word 0x432 # 1 0000 11 00 1 0
code75: .word 0x612 # 11 0000 1 00 1 0
code76: .word 0x650 # 11 00 1 0 1 0000
code77: .word 0x7BA # 1111 0 111 0 1 0
code78: .word 0x614 # 11 0000 1 0 1 00
code79: .word 0x47A # 1 000 1111 0 1 0
code80: .word 0x53C # 1 0 1 00 1111 00
code81: .word 0x4BC # 1 00 1 0 1111 00
code82: .word 0x49E # 1 00 1 00 1111 0
code83: .word 0x5E4 # 1 0 1111 00 1 00
code84: .word 0x4F4 # 1 00 1111 0 1 00
code85: .word 0x4F2 # 1 00 1111 00 1 0
code86: .word 0x7A4 # 1111 0 1 00 1 00
code87: .word 0x794 # 1111 00 1 0 1 00
code88: .word 0x792 # 1111 00 1 00 1 0
code89: .word 0x6DE # 11 0 11 0 1111 0
code90: .word 0x6F6 # 11 0 1111 0 11 0
code91: .word 0x7B6 # 1111 0 11 0 11 0
code92: .word 0x578 # 1 0 1 0 1111 000
code93: .word 0x51E # 1 0 1 000 1111 0
code94: .word 0x45E # 1 000 1 0 1111 0
code95: .word 0x5E8 # 1 0 1111 0 1 000
code96: .word 0x5E2 # 1 0 1111 000 1 0
code97: .word 0x7A8 # 1111 0 1 0 1 000
code98: .word 0x7A2 # 1111 0 1 000 1 0
code99: .word 0x5DE # 1 0 111 0 1111 0
# "Special" symbols
code100: .word 0x5EE # 1 0 1111 0 111 0 # Code B 
code101: .word 0x75E # 111 0 1 0 1111 0 # Code A
code102: .word 0x7AE # 1111 0 1 0 111 0 # FNC 1
code103: .word 0x684 # 11 0 1 0000 1 00 # Start code A
code104: .word 0x690 # 11 0 1 00 1 0000 # Start code B
code105: .word 0x69C # 11 0 1 00 111 00 # Start code C
# Below is a stop pattern, not a stop symbol. Stop pattern is stop symbol + 2 bars after 
code106: .word 0x18EB # 11 000 111 0 1 0 11
