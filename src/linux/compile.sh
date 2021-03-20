#!/bin/sh

if test -e "*.o"; then
	rm *.o
fi
g++ -O2 -W -c ../zma.cpp                  -o zma.o                 
g++ -O2 -W -c ../zma_information.cpp      -o zma_information.o     
g++ -O2 -W -c ../zma_parse.cpp            -o zma_parse.o           
g++ -O2 -W -c ../zma_parse_expression.cpp -o zma_parse_expression.o
g++ -O2 -W -c ../zma_parse_process.cpp    -o zma_parse_process.o   
g++ -O2 -W -c ../zma_text.cpp             -o zma_text.o            
g++ -O2 *.o -o zma
