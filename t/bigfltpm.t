#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib'; # for running manually
  my $location = $0; $location =~ s/bigfltpm.t//;
  unshift @INC, $location; # to locate the testing files
  # chdir 't' if -d 't';
  plan tests => 1585;
  }

use Math::BigInt lib => 'BitVect';
use Math::BigFloat;

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup $CL);
$class = "Math::BigFloat";
$CL = "Math::BigInt::BitVect";
   
require 'bigfltpm.inc';	# all tests here for sharing
