wsl rm *.gcno
wsl rm *.o
wsl g++ -std=c++14           -c ../zma.cpp                  -o zma.o                 
wsl g++ -std=c++14 -coverage -c ../zma_information.cpp      -o zma_information.o     
wsl g++ -std=c++14 -coverage -c ../zma_parse.cpp            -o zma_parse.o           
wsl g++ -std=c++14 -coverage -c ../zma_parse_expression.cpp -o zma_parse_expression.o
wsl g++ -std=c++14 -coverage -c ../zma_parse_process.cpp    -o zma_parse_process.o   
wsl g++ -std=c++14 -coverage -c ../zma_text.cpp             -o zma_text.o            
wsl g++ -std=c++14 -fprofile-arcs *.o -o zma
