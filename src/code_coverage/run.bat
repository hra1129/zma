wsl rm *.gcda
wsl rm gcov/*.gcov 2>&1

cd ..
wsl python3 gcc_run.py
cd code_coverage

wsl gcov zma*.gcda
wsl mv zma*.gcov gcov/ 2>&1
wsl rm *.gcov 2>&1
pause
