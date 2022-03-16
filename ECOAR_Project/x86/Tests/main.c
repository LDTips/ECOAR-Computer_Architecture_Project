// BATRUCH SŁAWOMIR - INTEL x86 BARCODE TYPE C DECODER

#include <stdio.h> // Basic lib
#include <stdlib.h> // Basic lib
#include <fcntl.h> // Open()
#include <unistd.h> // Read() close()
#include <sys/stat.h> // stat struct

extern int decode128(unsigned char *source_bmp, int scan_line_no, char *text); // ASM function
void catch_err(int err);

int main(int argc, char* argv[]) {
    if(argc != 2) { // We need filename, so 
        fprintf(stderr, "ERR: Filename missing or too many args!\n");
        return 101;
    } 
    // https://www.ibm.com/docs/en/i/7.2?topic=ssw_ibm_i_72/apis/stat.htm - stat functiond documentation
    // It gets information about file size. Needed for allocation info
    struct stat bitmap;
    stat(argv[1], &bitmap); // argv[1] should be <filename>.bmp
    // Store the file bytes
    char* buf = (char*)malloc(bitmap.st_size); // st_size - number of data bytes in the file
    if (buf == NULL) {
        fprintf(stderr, "ERR: Memory allocation failed!\n");
        return 102;
    }
    // https://pubs.opengroup.org/onlinepubs/007904875/functions/open.html
    /* "The open() function shall establish the connection between a file and a file descriptor. 
    It shall create an open file description that refers to a file and a file descriptor that refers to that open file description. 
    The file descriptor is used by other I/O functions to refer to that file. The path argument points to a pathname naming the file." */
    // File descriptor
    int descriptor = open(argv[1], O_RDONLY, 0);
    if (descriptor == -1) { // -1 indicates there was an issue with opening the file
        fprintf(stderr, "ERR: Read only file access failed.\n");
        free(buf);
        return 103;
    }
    // https://pubs.opengroup.org/onlinepubs/009604599/functions/read.html
    /* 'The read() function shall attempt to read nbyte bytes (3rd arg) from the file associated with the open file descriptor (1st arg), into the buffer pointed to by buf (2nd arg).
     The behavior of multiple concurrent reads on the same pipe, FIFO, or terminal device is unspecified.' */
    int mem = read(descriptor, buf, bitmap.st_size); // Buf is changed. File data is loaded into it. Here we use the descriptor
    if (mem < 0) {
        fprintf(stderr, "File read error.\n");
        free(buf);
        return 104;
    }

    short signature = *(short*)(buf); // For checking the .bitmap metadata first two bytes
    if (signature != 0x4d42) { // 4d42
        fprintf(stderr, "ERR: Invalid metadata (first two bytes)!\n");
        free(buf);
        return 105;
    }

    unsigned int data_offset = *(unsigned int*)(buf + 10); // Location of the information about pixel array offset
    int width = *(int*)(buf + 18); // Location of width information
    int height = *(int*)(buf + 22); // Location of height information
    unsigned short depth =  *(unsigned short*)(buf + 28); // Location of bit depth information

    if (width == 600 && height == 50 && depth == 24) {
        printf("%s", "Header check correct. Proceeding...\n");
        unsigned int line = 20; // Line used for decoding
        char decoded[50]; // No longer than 50 character texts I assume...
        int result = decode128(buf + data_offset, line, decoded);
        if (result != 0) {
            catch_err(result);
        } 
        else {
            printf("Decoded text is:\t");
            for (unsigned int i = 0; decoded[i] != '\0'; i++) {
                if (decoded[i] < 10) // We should print a 0 if the code is less than 10
                // Thats how it is in code128 type C
                    printf("0");
                printf("%d", decoded[i]); // %d of a char value will print ASCII val
            }
            printf("\n");
        }
    }
    else {
        fprintf(stderr, "ERR: Invalid dimensions and/or depth!\n");
        free(buf);
        return 106;
    }
    free(buf);
    close(descriptor);
    return 0;
}

void catch_err(int err) {
    switch(err) {
        case 1:
            fprintf(stderr, "ERR: Start character invalid (set A or B)!\n");
            exit(err);
        case 2:
            fprintf(stderr, "ERR: Checksum incorrect!\n");
            exit(err);
        case 3:
            fprintf(stderr, "ERR: Detection failed!\n");
            exit(err);
        case 4:
            fprintf(stderr, "ERR: Bar width too big!\n");
            exit(err);
        default:
            fprintf(stderr, "ERR: Unhandled error\n");
            exit(999);
    }
}