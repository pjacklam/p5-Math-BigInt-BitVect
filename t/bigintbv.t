#!/usr/bin/perl -w

use strict;
use Test;

BEGIN 
  {
  $| = 1;
  # chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 47;
  }

# testing of Math::BigInt::BitVect, primarily for interface/api and not for the
# math functionality

use Math::BigInt::BitVect;

# _new and _str
my $x = _new(\"123"); ok (ref($x),'Bit::Vector');
my $y = _new(\"321");

# _add, _sub, _mul, _div

ok (${_str(_add($x,$y))},444);
ok (${_str(_sub($x,$y))},123);
ok (${_str(_mul($x,$y))},39483);
ok (${_str(_div($x,$y))},123);

ok (${_str(_mul($x,$y))},39483);
ok (${_str($x)},39483);
ok (${_str($y)},321);
my $z = _new(\"2");
ok (${_str(_add($x,$z))},39485);
my ($re,$rr) = _div($x,$y);

ok (${_str($re)},123); ok (${_str($rr)},2);

# is_zero, _is_one, _one, _zero
ok (_is_zero($x),0);
ok (_is_one($x),0);

ok (_is_one(_one()),1); ok (_is_one(_zero()),0);
ok (_is_zero(_zero()),1); ok (_is_zero(_one()),0);

# is_odd, is_even
ok (_is_odd(_one()),1); ok (_is_odd(_zero()),0);
ok (_is_even(_one()),0); ok (_is_even(_zero()),1);

# _digit
$x = _new(\"123456789");
ok (_digit($x,0),9);
ok (_digit($x,1),8);
ok (_digit($x,2),7);
ok (_digit($x,-1),1);
ok (_digit($x,-2),2);
ok (_digit($x,-3),3);

# _acmp
$x = _new(\"123456789");
$y = _new(\"987654321");
ok (_acmp($x,$y),-1);
ok (_acmp($y,$x),1);
ok (_acmp($x,$x),0);
ok (_acmp($y,$y),0);

# _div
$x = _new(\"3333"); $y = _new(\"1111"); ok (${_str(_div($x,$y))},3);
$x = _new(\"33333"); $y = _new(\"1111"); ($x,$y) = _div($x,$y);
ok (${_str($x)},30); ok (${_str($y)},3);
$x = _new(\"123"); $y = _new(\"1111"); 
($x,$y) = _div($x,$y); ok (${_str($x)},0); ok (${_str($y)},123);

# _pow
$x = _new(\"7"); $y = _new(\"7"); ok (${_str(_pow($x,$y))},823543);
$x = _new(\"31"); $y = _new(\"7"); ok (${_str(_pow($x,$y))},27512614111);
$x = _new(\"2"); $y = _new(\"10"); ok (${_str(_pow($x,$y))},1024);

# _and, _xor, _or
$x = _new(\"7"); $y = _new(\"5"); ok (${_str(_and($x,$y))},5);
$x = _new(\"6"); $y = _new(\"1"); ok (${_str(_or($x,$y))},7);
$x = _new(\"9"); $y = _new(\"6"); ok (${_str(_xor($x,$y))},15);

# to check bit-counts
#$x = _new(\"63"); $y = _new(\"7"); ok (${_str(_pow($x,$y))},27512614111);
#$x = _new(\"128"); $y = _new(\"16"); ok (${_str(_pow($x,$y))},27512614111);
#$x = _new(\"255"); $y = _new(\"32"); ok (${_str(_pow($x,$y))},27512614111);
#$x = _new(\"1024"); $y = _new(\"64"); ok (${_str(_pow($x,$y))},27512614111);
#$x = _new(\"1048576"); $y = _new(\"128"); ok (${_str(_pow($x,$y))},27512614111);

# _num
$x = _new(\"12345"); $x = _num($x); ok (ref($x)||'',''); ok ($x,12345);

# _gcd
$x = _new(\"128"); $y = _new(\'96'); $x = _gcd($x,$y); ok (${_str($x)},'32');

# should not happen:
# $x = _new(\"-2"); $y = _new(\"4"); ok (_acmp($x,$y),-1);

# _check
$x = _new(\"123456789");
ok (_check($x),0);
ok (_check(123),'123 is not a reference to Bit::Vector');

# done

1;

