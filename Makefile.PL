#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'               => 'Math-BigInt-BitVect',
   'VERSION_FROM'       => 'lib/Math/BigInt/BitVect.pm',
   'AUTHOR'             => 'Peter John Acklam <pjacklam@gmail.com>',


   # A hash of modules that are required to run Makefile.PL itself, but not to
   # run the distribution.

   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => 6.58,
                           },

   # A hash of modules that are needed to build the module but not run it.

   'BUILD_REQUIRES'     => {},

   # A hash of modules that are needed to run the module.

   'PREREQ_PM'          => {
                            'Math::BigInt'        => 1.999812,
                            'Bit::Vector'         => 0,
                           },

   # A hash of modules that are needed to test the module but not run or build
   # it.

   'TEST_REQUIRES'      => {
                            'Test::More'          => 0.88,
                           },

   'LICENSE'            => 'perl_5',
   'LIBS'               => [''],          # e.g., '-lm'
   'DEFINE'             => '',            # e.g., '-DHAVE_SOMETHING'
   'INC'                => '',            # e.g., '-I/usr/include/other'
   'SIGN'               => 1,
  );