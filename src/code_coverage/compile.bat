wsl rm *.gcno
wsl rm *.o
wsl g++ -O2 -std=c++17 -fprofile-arcs -ftest-coverage -W -c -I.. -I../sub ../sub/*.cpp
wsl g++ -O2 -std=c++17 -fprofile-arcs -ftest-coverage -W -c -I.. -I../sub ../zma.cpp                  -o zma.o                 
wsl g++ -O2 -std=c++17 -fprofile-arcs -ftest-coverage -W -c -I.. -I../sub ../zma_information.cpp      -o zma_information.o     
wsl g++ -O2 -std=c++17 -fprofile-arcs -ftest-coverage -W -c -I.. -I../sub ../zma_parse.cpp            -o zma_parse.o           
wsl g++ -O2 -std=c++17 -fprofile-arcs -ftest-coverage -W -c -I.. -I../sub ../zma_parse_expression.cpp -o zma_parse_expression.o
wsl g++ -O2 -std=c++17 -fprofile-arcs -ftest-coverage -W -c -I.. -I../sub ../zma_parse_process.cpp    -o zma_parse_process.o   
wsl g++ -O2 -std=c++17 -fprofile-arcs -ftest-coverage -W -c -I.. -I../sub ../zma_text.cpp             -o zma_text.o            
wsl g++ -O2 -std=c++17 -fprofile-arcs -ftest-coverage -W -c -I.. -I../sub ../zma_logger.cpp           -o zma_logger.o          
wsl g++ -O2 -fprofile-arcs -ftest-coverage *.o -o zma
pause
