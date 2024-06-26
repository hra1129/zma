#!/usr/bin/python3
# -*- coding: utf-8 -*-
# -----------------------------------------------------------------------------

import os
import sys
import subprocess
import re

# -----------------------------------------------------------------------------
def execute_test( file_name, log ):
	if os.path.exists( 'run_' + file_name + '.sh' ):
		subprocess.run( ['bash', 'run_' + file_name + '.sh'], capture_output=True )
	else:
		subprocess.run( ['../../code_coverage/zma', file_name, file_name + '.bin'], capture_output=True )
	if os.path.exists( 'zma.log' ):
		os.rename( 'zma.log', file_name + '.log' )

	s = '  ' + file_name + ' '
	l = len( s )
	s = s + '.' * (40 - l) + ' '

	if os.path.exists( 'ref_' + file_name + '.bin' ):
		result = subprocess.run( ['diff', '-s', file_name + '.bin', 'ref_' + file_name + '.bin'], capture_output=True )
		if result.returncode == 0:
			s = s + 'OK'
		else:
			s = s + 'NG'
	else:
		s = s + '??'

	print( s )
	log.write( s + "\n" )

# -----------------------------------------------------------------------------
def test_bench_main():
	with open( 'coverage_result.txt', 'w' ) as f:
		os.chdir( './test_pattern/' )
		target_dirs = os.listdir( '.' )
		for dir_name in target_dirs:
			if not re.match( r'test.*', dir_name ):
				continue
			os.chdir( dir_name )
			target_files = os.listdir( '.' )
			print( dir_name )
			f.write( dir_name + "\n" )
			for file_name in target_files:
				if not re.match( r'test.*\.asm$', file_name ):
					continue
				execute_test( file_name, f )
			os.chdir( '..' )

# -----------------------------------------------------------------------------
if __name__ == '__main__':
	test_bench_main()
