###############################################################################
# core math lib for BigInt, representing big numbers by Bit::Vector's

package Math::BigInt::BitVect;

use 5.005;
use strict;
use warnings;

require Exporter;

use vars qw/ @ISA @EXPORT $VERSION/;
@ISA = qw(Exporter);

@EXPORT = qw(
        _add _mul _div _mod _sub
        _new _from_hex _from_bin
        _str _num _acmp _len
        _digit
        _is_zero _is_one
        _is_even _is_odd
        _check _zero _one _copy _len
	_pow _dec _inc _gcd
	_and _or _xor
);
$VERSION = '1.01';

use Bit::Vector;

##############################################################################
# global constants, flags and accessory
 
# constants for easier life
my $nan = 'NaN';
my $bits 	= 32;				# make new numbers this wide
my $chunk	= 32;				# keep size a multiple of this

# for is_* functions
my $zero_ = Bit::Vector->new_Dec($bits,0);
my $one_ = Bit::Vector->new_Dec($bits,1);

##############################################################################
# create objects from various representations

sub _new
  {
  shift;				# remove class name
  # (string) return ref to num
  my $d = shift;

  my $bits = (10*length($$d) / 3);	# 1000 => 10 bits, 1000000 => 20
  $bits = (int($bits / $chunk) + 1) * $chunk;
 
  my $u = Bit::Vector->new_Dec($bits,$$d);
  return __reduce($u);
  }                                                                             

sub _from_hex
  {
  shift;				# remove class name
  my $h = shift;
  $$h =~ s/^[+-]?0x//;

  my $bits = length($$h)*4+4;			# 0x1234 => 4*4+4 => 20 bits
  $bits = (int($bits / $chunk) + 1) * $chunk;
  #print "new hex $bits\n";
  return Bit::Vector->new_Hex($bits,$$h);
  }

sub _from_bin
  {
  shift;				# remove class name
  my $b = shift;

  $$b =~ s/^[+-]?0b//;
  my $bits = length($$b)+4;			# 0x1234 => 4*4+4 => 20 bits
  $bits = (int($bits / $chunk) + 1) * $chunk;
  #print "new bin $bits\n";
  return Bit::Vector->new_Bin($bits,$$b);
  }

sub _zero
  {
  return Bit::Vector->new_Dec($bits,0);
  }

sub _one
  {
  return Bit::Vector->new_Dec($bits,1);
  }

sub _copy
  {
  shift @_ if $_[0] eq __PACKAGE__;
  my $x = shift;
  return $x->Clone();
  }

sub max
  {
  # maximum from 2 values
  my ($m,$n) = @_;
  $m = $n if $n > $m;
  return $m;
  } 

##############################################################################
# convert back to string and number

sub _str
  {
  # make string
  shift @_ if $_[0] eq __PACKAGE__;
  my $ar = shift;

  my $x = $ar->to_Dec(); 
#  warn ("$x is negative!") if $x =~ /^[-]/;	# spurious '-'
  return \$x;
  }                                                                             

sub _num
  {
  # make a number
  shift @_ if $_[0] eq __PACKAGE__;
  my $ar = shift;
  
  # let Perl's atoi() handle this one
  my $x = $ar->to_Dec();
  #$x =~ s/^[-]//;		# only positives, which should not happen
  return $x;
  }


##############################################################################
# actual math code

sub _add
  {
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$y) = @_;

  # sizes must match!
  my $xs = $x->Size(); my $ys = $y->Size();
  my $ns = max($xs,$ys) + 2;	# reserve 2 bit, so never overflow
  $ns = (int($ns / $chunk)+1)*$chunk;
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;

  $x->add($x,$y,0);
  # then reduce again
  __reduce($y) if $ns != $ys;
  __reduce($x) if $ns != $xs;
  return $x;
  }                                                                             

sub _sub
  {
  # $x is always larger than $y! So overflow/underflow can not happen here
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$y,$z) = @_;
 
  # sizes must match!
  my $xs = $x->Size(); my $ys = $y->Size();
  my $ns = max($xs,$ys);	# no reserve, since no overflow
  $ns = (int($ns / $chunk)+1)*$chunk;
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;
  if ($z)
    {
    $y->sub($x,$y,0);
    }
  else
    {
    $x->sub($x,$y,0);
    }
  # then reduce again
  __reduce($y) if $ns != $ys;
  __reduce($x) if $ns != $xs;
  return $x;
  }                                                                             

sub _mul
  {
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$y) = @_;

  # sizes must match!
  my $xs = $x->Size(); my $ys = $y->Size();
  my $ns = max($xs,$ys)*2 + 2;	# reserve some bits (and +2), so never overflow
  $ns = (int($ns / $chunk)+1)*$chunk;
  #print "$xs $ys $ns\n";
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;

  # then mul
  $x->Multiply($x,$y);
  # then reduce again
  __reduce($y) if $ns != $ys;
  __reduce($x) if $ns != $xs;
  return $x;
  }                                                                             

sub _div
  {
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$y) = @_;
  
  my $r;
  # sizes must match!
  my $xs = $x->Max()+1; my $ys = $y->Max()+1;
  if ($xs >= $ys)
    {
    # actually, if $ys > $xs, result will be zero, anyway...
    my $ns = $xs+2;			# for overflow, relly necc.?
    $ns = (int($ns / $chunk)+1)*$chunk;
    $x->Resize($ns) if $xs != $ns;
    $y->Resize($ns) if $ys != $ns;
    $r = Bit::Vector->new_Hex($ns,0);
    $x->Divide($x,$y,$r);
    __reduce($y) if $ns != $ys;
    __reduce($x) if $ns != $xs;
    return wantarray ? ($x,__reduce($r)) : $x;
    }    
  else
    {
    $r = Bit::Vector->new_Hex($chunk,0);	# x > y => 0
    return wantarray ? ($r,$x) : $r;		# (0,x) or 0
    }
  }                                                                             

sub _inc
  {
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x) = @_;
  my $xs = $x->Max()+1; my $ns = $xs+1;
  $ns = (int($ns / $chunk)+1)*$chunk;
  $x->Resize($ns) if $xs != $ns;
  $x->increment();
  __reduce($x);
  }

sub _dec
  {
  # overflow into negative!
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x) = @_;

  # will only get smaller
  $x->decrement() if $x->Max() > 0;	# negative Max => x == 0
  __reduce($x);
  }

sub _and
  {
  # bit-wise AND of two numbers
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$y) = @_;

  # sizes must match!
  my $xs = $x->Size(); my $ys = $y->Size();
  my $ns = max($xs,$ys);	# highest bits in $x,$y are zero
  $ns = (int($ns / $chunk)+1)*$chunk;
  #print "and $xs $ys $ns\n";
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;
 
  $x->And($x,$y); 
  __reduce($y) if $ns != $xs;
  __reduce($x) if $ns != $xs;
  $x;
  }

sub _xor
  {
  # bit-wise XOR of two numbers
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$y) = @_;

  # sizes must match!
  my $xs = $x->Size(); my $ys = $y->Size();
  my $ns = max($xs,$ys);	# highest bits in $x,$y are zero
  $ns = (int($ns / $chunk)+1)*$chunk;
  #print "xor $xs $ys $ns\n";
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;
 
  $x->Xor($x,$y); 
  __reduce($y) if $ns != $xs;
  __reduce($x) if $ns != $xs;
  $x;
  }

sub _or
  {
  # bit-wise OR of two numbers
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$y) = @_;

  # sizes must match!
  my $xs = $x->Size(); my $ys = $y->Size();
  my $ns = max($xs,$ys);	# highest bits in $x,$y are zero
  $ns = (int($ns / $chunk)+1)*$chunk;
  #print "or $xs $ys $ns\n";
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;
 
  $x->Or($x,$y); 
  __reduce($y) if $ns != $xs;
  __reduce($x) if $ns != $xs;
  $x;
  }

sub _gcd
  {
  # Greatest Common Divisior
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$y) = @_;

  # test un-resized for zero
  return __reduce($x->Clone()) if _is_zero($y);
  return __reduce($y->Clone()) if _is_zero($x);

  # Original, Bit::Vectors Euklid algorithmn
  # sizes must match!
  my $xs = $x->Size(); my $ys = $y->Size();
  my $ns = max($xs,$ys);	# highest bits in $x,$y are zero
  $ns = (int($ns / $chunk)+1)*$chunk;
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;
  #my $w = $x->Shadow();
  $x->GCD($x,$y); __reduce($y) if $ns != $xs; __reduce($x) if $ns != $xs;
  return $x;

  # Algorithmn B, Binary method after Knuth, Vol. 2, Third Edition, pp 338
  # one of $x,$y must != 0
  # not used yet since buggy

  # variables 
  my ($z,$t,$s);		# z: flag to avoid copying u,v => t
  my $u = $x->Clone(); 		# s: amount of shfts
  my $v = $x->Clone(); 		# t: temporary variable

  # B1: find power of 2
  my $k = 0; $k++ while (($u->bit_test($k) & $v->bit_test($k)) == 1);
 
  # B1: and divide by 2 ** $k
  $u->shift_right($k); $v->shift_right($k);

  # B2: initialize
  if ($u->bit_test(0) == 1)		# u is odd?
    {
    $z = -1; $t = $v->Clone();		# use -v
    }
  else
    {
    $z = 1; $t = $u->Clone();
    }
  while ($t->Max() > 0)			# Max() < 0 if $t == 0
    {
    # B3, B4: halve $t as long as it is even
    $s = 0; $s ++ while ($t->bit_test(0) == 0);
    if ($s > 0)
      {
      $t->shift_right($s);		# halve and 
      __reduce($t);			# make smaller
      }
    # B5 reset max(u,v)
    if ($z == 1)
      {
      $u = $t->Clone();
      }
    else
      {
      $v = $t->Clone();
      }
    if (_acmp($u,$v) > 0)		# u > v?
      {
      $z = 1; $t = $u->Clone(); _sub($t,$v);
      }
    else
      {
      $z = -1; $t = $v->Clone(); _sub($t,$u);
      }
    } # end while $t == 0
  
  # $t == 0, output is $u * (2 ** $k) 
  $u->shift_left($k);
  return __reduce($u);
 
  #__reduce($y) if $ns != $xs;
  #__reduce($x) if $ns != $xs;
  }


##############################################################################
# testing

sub _acmp
  {
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x, $y) = @_;

  my $xm = $x->Max(); my $ym = $y->Max();
  my $diff = ($xm - $ym);
  return -1 if $diff < 0;
  return 1 if $diff > 0;

  # used sizes are the same
  my $xs = $x->Size(); my $ys = $y->Size();
  my $ns = max($xs,$ys);
  $ns = (int($ns / $chunk)+1)*$chunk;
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;
  return $x->Lexicompare($y);
  }

sub _len
  {
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x) = @_;
  # return length, aka digits in decmial, costly!!
  return length($x->to_Dec());
  }

sub _digit
  {
  # return the nth digit, negative values count backward; this is costly!
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$n) = @_;

  $n++; return substr($x->to_Dec(),-$n,1);
  }

sub _pow
  {
  # return power
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x,$y) = @_;

  # new size is appr. exponent-size * powersize
  my $xs = $x->Max()+1; my $ys = $y->to_Dec();
  if (($xs == 2) && ($x->bit_test(0) == 0))
    {
    # Bit::Vector v6.0 is O(N*N) for 2 ** x :-(
    # so cheat
    my $ns = $ys+2; 	# one bit more for unsigned
    $x->Resize($ys+2);
    $x->Empty();
    $x->Bit_On($ns-2);    
    # halve time for 2 ** $x as long as BV is O(N*N) there :/
    #$xs -- if (($x->bit_test(0) == 0) && ($x->bit_test(1) == 1))
    return $x;	# no __reduce necc.
    }
  my $ns = $ys * $xs + 1;
  $ns = (int($ns / $chunk)+1)*$chunk;
  # print ${_str($x)}, " ", ${_str($y)}," max:$xs val:$ys => $ns\n";
  $x->Resize($ns) if $xs != $ns;
  $y = $y->Clone() if ($y eq $x);	# BitVect does not like self_pow
  $x->Power($x,$y);
  __reduce($x) if $xs != $ns;
  }

##############################################################################
# _is_* routines

sub _is_zero
  {
  # return true if arg is zero
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x) = shift;

  return 0 if $x->Size() != $bits;	# if size mismatch
  return $x->equal($zero_);
  }

sub _is_one
  {
  # return true if arg is one
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x) = shift;

  return 0 if $x->Size() != $bits;	# if size mismatch
  return $x->equal($one_);
  }

sub _is_even
  {
  # return true if arg is even
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x) = shift;
  return (!$x->bit_test(0))||0;
  }

sub _is_odd
  {
  # return true if arg is odd
  shift @_ if $_[0] eq __PACKAGE__;
  my ($x) = shift;
  return $x->bit_test(0) || 0;
  }

###############################################################################
# check routine to test internal state of corruptions

sub _check
  {
  # no checks yet, pull it out from the test suite
  shift @_ if $_[0] eq __PACKAGE__;

  my ($x) = shift;
  return "$x is not a reference to Bit::Vector" if ref($x) ne 'Bit::Vector';
  return 0;
  }

sub __reduce
  { 
  # internal reduction to make minimum size
  my ($bv) = @_;

  #print "reduce: ",$bv->Size()," max: ",$bv->Max(),"\n";
  my $size = $bv->Size();
  return $bv if $size <= $chunk;			# not smaller

  # one more to prevent negatives
  my $real_size = $bv->Max()+1;
  if ($real_size < 0)
    {
    $bv->Resize($chunk);	# is bigger than chunk
    }
  # need to make smaller? (real_size =-inf if $bv == 0!)
  elsif (($size - $real_size) > $chunk)
    {
    #print "r $real_size $size\n";	
    my $new_size = $size;
    $new_size = (int($real_size / $chunk) + 1) * $chunk;
    #print "Resize $size => $new_size\n";
    $bv->Resize($new_size) if $new_size != $size;
    }
  return $bv;
  }

1;
__END__

=head1 NAME

Math::BigInt::BitVect - Perl module to use Bit::Vector for Math::BigInt

=head1 SYNOPSIS

Provides support for big integer calculations via means of Bit::Vector, a
fast C library by Steffen Beier.

=head1 LICENSE
 
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. 

=head1 AUTHOR

Tels http://bloodgate.com in 2001.
The used module Bit::Vector is by Steffen Beyer. Thanx!

=head1 SEE ALSO

L<Math::BigInt>, L<Math::BigInt::Calc>, L<Bit::Vector>.

=cut
