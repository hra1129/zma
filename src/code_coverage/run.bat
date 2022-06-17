wsl rm *.gcda

cd ..
wsl python3 gcc_run.py
cd code_coverage

wsl rm gcov/*.gcov 2>&1
rem wsl gcov -b *.gcda
wsl gcov *.gcda
wsl mv zma*.gcov gcov/ 2>&1
wsl rm *.gcov 2>&1
pause
