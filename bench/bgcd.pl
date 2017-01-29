#!/usr/bin/perl -w

use strict;

# benchmark Euklid against binarybgcd() algorithmn
use lib '../lib';

#use Math::BigInt;
use Math::BigInt lib => 'BitVect';
use Math::BigFloat;
use Math::Big;

use Benchmark;

my $digits = shift || 100;
my $fibo = shift || 100;
my $c = 2000;

# takes longest when $x and $y are consecutive fibonacci numbers
my $x = Math::Big::fibonacci($fibo);
my $y = Math::Big::fibonacci($fibo+1);
my $z; my $u = ''; my $v = '';
while (length($u))
  {
  $u .= int(rand(10000));
  }
while (length($u))
  {
  $v .= int(rand(10000));
  }

$u = Math::BigInt->new($u);
$v = Math::BigInt->new($v);

print "timing bgcd() with $fibo\'th fibonacci and $digits rand digits:\n\n";

timethese ( $c, 
  {
  bgcd_fibu => sub { $z = $x->bgcd($y); },
  bgcd_rand => sub { $z = $u->bgcd($v); }
  } );
