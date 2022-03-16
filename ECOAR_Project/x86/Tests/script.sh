#!/bin/bash
echo -e "3.bmp"
./out 3.bmp

echo -e "\nempty.bmp"
./out empty.bmp

echo -e "\ninvalid_checksum.bmp"
./out invalid_checksum.bmp

echo -e "\ninvalid_code.bmp"
./out invalid_code.bmp

echo -e "\ntoo_thick.bmp"
./out too_thick.bmp

echo -e "\ninvalid_height.bmp"
./out invalid_height.bmp

echo -e "\ninvalid_width.bmp"
./out invalid_width.bmp

echo -e "\ninvalid_depth.bmp"
./out invalid_depth.bmp

echo -e "\nsome_text_file.txt"
./out some_text_file.txt
