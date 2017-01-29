#!/usr/bin/perl -w

use Test;
BEGIN { plan tests => 7; }

BEGIN { unshift @INC, '../lib'; }	# comment out to use old module
use strict;
use Math::BigInt qw/lib BitVect :constant/;

my ($x,$y,$z);
my $two = Math::BigInt->new(2);

 $x = $two ** 6972593; $x--;  ok(1,1); #ok (len($x),2098960);
 $x = $two ** 3021377; $x--;  ok(1,1);  #ok (len($x),909526);
 $x = $two ** 756839; $x--;   ok(1,1);  #ok (len($x),227832);

# some twin primes (first in list at 03/2001)
$x = ($two ** 80025) * 665551035; $x++; $y = $x-2; ok (1,1);
$x = ($two ** 66443) * 1693965; $x++; $y = $x-2;   ok (1,1);
$x = ($two ** 64955) * 83475759; $x++; $y = $x-2;  ok (1,1);
$x = ($two ** 38880) * 242206083; $x++; $y = $x-2; ok (1,1);

sub len 
  {
  my $x = shift; length("$x");
  }

