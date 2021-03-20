wsl rm *.gcda

cd ..
wsl bash gcc_run.sh
cd code_coverage

wsl rm gcov/*.gcov
rem wsl gcov -b *.gcda
wsl gcov *.gcda
wsl mv zma*.gcov gcov/
wsl rm *.gcov
pause
