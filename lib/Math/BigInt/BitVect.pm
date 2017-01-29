###############################################################################
# core math lib for BigInt, representing big numbers by Bit::Vector's

package Math::BigInt::BitVect;

use 5.005;
use strict;
# use warnings; # dont use warnings for older Perls

require Exporter;

use vars qw/@ISA $VERSION/;
@ISA = qw(Exporter);

$VERSION = '1.08';

use Bit::Vector;

##############################################################################
# global constants, flags and accessory
 
my $bits 	= 32;				# make new numbers this wide
my $chunk	= 32;				# keep size a multiple of this

# for is_* functions
my $zero_ = Bit::Vector->new_Dec($bits,0);
my $one_  = Bit::Vector->new_Dec($bits,1);

##############################################################################
# create objects from various representations

sub _new
  {
  shift;				# remove class name
  # (string) return ref to num
  my $d = shift;

  my $b = (10*length($$d) / 3);		# 1000 => 10 bits, 1000000 => 20
  $b = (int($b / $chunk) + 1) * $chunk; # chunked

  my $u = Bit::Vector->new_Dec($b,$$d);
  __reduce($u) if $b > $bits;
  $u;
  }                                                                             

sub _from_hex
  {
  my $h = $_[1];

  $$h =~ s/^[+-]?0x//;
  my $bits = length($$h)*4+4;			# 0x1234 => 4*4+4 => 20 bits
  $bits = (int($bits / $chunk) + 1) * $chunk;
  #print "new hex $bits\n";
  return Bit::Vector->new_Hex($bits,$$h);
  }

sub _from_bin
  {
  my $b = $_[1];

  $$b =~ s/^[+-]?0b//;
  my $bits = length($$b)+4;			# 0x1234 => 4*4+4 => 20 bits
  $bits = (int($bits / $chunk) + 1) * $chunk;
  #print "new bin $bits\n";
  Bit::Vector->new_Bin($bits,$$b);
  }

sub _zero
  {
  Bit::Vector->new_Dec($bits,0);
  }

sub _one
  {
  Bit::Vector->new_Dec($bits,1);
  }

sub _copy
  {
  $_[1]->Clone();
  }

sub max
  {
  # helper function: maximum of 2 values
  my ($m,$n) = @_;
  $m = $n if $n > $m;
  $m;
  } 

# catch and throw away
sub import { }

##############################################################################
# convert back to string and number

sub _str
  {
  # make string
  my $x = $_[1]->to_Dec(); 
  \$x;
  }                                                                             

sub _num
  {
  # make a number
  # let Perl's atoi() handle this one
  my $x = $_[1]->to_Dec();
  return $x;
  }

sub _as_hex
  {
  my $x = $_[1]->to_Hex();
  $x =~ s/^[0]+//;
  $x = '0x' . $x;
  \$x;
  }

sub _as_bin
  {
  my $x = $_[1]->to_Bin();
  $x =~ s/^[0]+//;
  $x = '0b' . $x;
  \$x;
  }

##############################################################################
# actual math code

sub _add
  {
  my ($c,$x,$y) = @_;

  # sizes must match!
  my $xs = $x->Size(); my $ys = $y->Size();
  my $ns = max($xs,$ys) + 2;	# reserve 2 bit, so never overflow
  $ns = (int($ns / $chunk)+1)*$chunk;
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;
  $x->add($x,$y,0);
  # then reduce again
  __reduce($x) if $ns != $xs;
  __reduce($y) if $ns != $ys;
  $x;
  }                                                                             

sub _sub
  {
  # $x is always larger than $y! So overflow/underflow can not happen here
  my ($c,$x,$y,$z) = @_;
 
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
  return $x unless $z;
  $y;
  }                                                                             

sub _mul
  {
  my ($c,$x,$y) = @_;

  # sizes must match!
  my $xs = $x->Size(); my $ys = $y->Size();
  # reserve some bits (and +2), so we never overflow
  my $ns = $xs + $ys + 2;		# 2^12 * 2^8 = 2^20 (so we take 22)
  $ns = (int($ns / $chunk)+1)*$chunk;	# and chunk the size
  $x->Resize($ns) if $xs != $ns;
  $y->Resize($ns) if $ys != $ns;

  # then mul
  $x->Multiply($x,$y);
  # then reduce again
  __reduce($y) if $ns != $ys;
  __reduce($x) if $ns != $xs;
  $x;
  }                                                                             

sub _div
  {
  my ($c,$x,$y) = @_;
  
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
  $r = Bit::Vector->new_Hex($chunk,0);	# x < y => 0
  return wantarray ? ($r,$x) : $r;	# (0,x) or 0
  }                                                                             

sub _inc
  {
  my ($x) = $_[1];

  # an overflow can only occur if the leftmost bit and the rightmost bit are
  # both 1 (we don't bother to look at the other bits)
  
  my $xs = $x->Size();
  if ($x->bit_test($xs-1) & $x->bit_test(0))
    {
    $x->Resize($xs + $chunk);	# make one bigger
    $x->increment();
    __reduce($x);		# in case no overflow occured
    }
  else
    {
    $x->increment();		# can't overflow, so no resize/reduce necc.
    }
  $x;
  }

sub _dec
  {
  # input is >= 1
  my ($x) = $_[1];

  $x->decrement(); 	# will only get smaller, so reduce afterwards
  __reduce($x);
  }

sub _and
  {
  # bit-wise AND of two numbers
  my ($c,$x,$y) = @_;

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
  my ($c,$x,$y) = @_;

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
  my ($c,$x,$y) = @_;

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
  my ($c,$x,$y) = @_;

  # test un-resized for zero
  return __reduce($x->Clone()) if _is_zero($c,$y);
  return __reduce($y->Clone()) if _is_zero($c,$x);

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
  my ($c,$x, $y) = @_;

  my $xm = $x->Max(); my $ym = $y->Max();
  my $diff = ($xm - $ym);
  return -1 if $diff < 0;
  return 1 if $diff > 0;

  # used sizes are the same, so no need for Resizing/reducing
#  my $xs = $x->Size(); my $ys = $y->Size();
#  my $ns = max($xs,$ys);
#  $ns = (int($ns / $chunk)+1)*$chunk;
#  $x->Resize($ns) if $xs != $ns;
#  $y->Resize($ns) if $ys != $ns;
  $x->Lexicompare($y);
  }

sub _len_bits
  {
  # should find out if it returns the length-1 (f.i between 32 and 99 it will
  # be off by -1, meaning that between 32 and 128 it should use _len, otherwise
  # it can return the shortcut)
  return int($_[1]->Max() * 0.3 * 1.004 + 0.5)+1;
  }

sub _len
  {
  # return length, aka digits in decmial, costly!!
  return length($_[1]->to_Dec());
  }

sub _digit
  {
  # return the nth digit, negative values count backward; this is costly!
  my ($c,$x,$n) = @_;

  $n++; return substr($x->to_Dec(),-$n,1);
  }

sub _fac
  {
  # factorial of $x
  my ($c,$x) = @_;

  my $n = _copy($c,$x);
  $x = _one();			# not $one_ since we need a copy/or new object!
  while (!_is_one($c,$n))
    {  
#    print " x ",${_str($c,$x)}," n ",${_str($c,$n)},"\n";
    _mul($c,$x,$n); _dec($c,$n);
    }
  $x; 			# no __reduce() since only getting bigger
  }

sub _pow
  {
  # return power
  my ($c,$x,$y) = @_;

  # new size is appr. exponent-size * powersize
  my $xs = $x->Max()+1; my $ys = $y->to_Dec();
  if (($xs == 2) && ($x->bit_test(0) == 0))
    {
    # Bit::Vector v6.0 is O(N*N) for 2 ** x :-(
    # so cheat
    my $ns = $ys+2; 				# one bit more for unsigned
    $ns = (int($ns / $chunk) + 1) * $chunk;	# chunked
    $x->Resize($ns);
    #$x->Empty();
    $x->Bit_Off(1);				# clear the only bit set 
    $x->Bit_On($ys);				# and set this    
    return $x;					# no __reduce() neccessary
    }
  my $ns = $ys * $xs + 1;
  $ns = (int($ns / $chunk)+1)*$chunk;
  # print ${_str($x)}, " ", ${_str($y)}," max:$xs val:$ys => $ns\n";
  $x->Resize($ns) if $xs != $ns;
  $y = $y->Clone() if ($y == $x);	# BitVect does not like self_pow
					# use ref() == ref() to compare addr.
  $x->Power($x,$y);
  __reduce($x) if $xs != $ns;
  }

###############################################################################
# shifting

sub _rsft
  {
  my ($c,$x,$y,$n) = @_;

  if ($n != 2)
    {
    $n = _new($c,\$n); return _div($c,$x, _pow($c,$n,$y));
    }
  $x->Move_Right(_num($c,$y));		# must be scalar - ugh
  __reduce($x);
  }

sub _lsft
  {
  my ($c,$x,$y,$n) = @_;

  if ($n != 2)
    {
    $n = _new($c,\$n); return _mul($c,$x, _pow($c,$n,$y));
    }
  $y = _num($c,$y);			# need scalar for Resize/Move_Left - ugh
  my $size = $x->Size() + 1 + $y;	# y and one more
  $x->Resize($size);
  $x->Move_Left($y);
  __reduce($x);				# to minimum size
  }

##############################################################################
# _is_* routines

sub _is_zero
  {
  # return true if arg is zero
  my ($x) = $_[1];

  return 0 if $x->Size() != $bits;	# if size mismatch
  return $x->equal($zero_);
  }

sub _is_one
  {
  # return true if arg is one
  my ($x) = $_[1];

  return 0 if $x->Size() != $bits;	# if size mismatch
  return $x->equal($one_);
  }

sub _is_even
  {
  # return true if arg is even
  my ($x) = $_[1];
  return (!$x->bit_test(0))||0;
  }

sub _is_odd
  {
  # return true if arg is odd
  my ($x) = $_[1];
  return $x->bit_test(0) || 0;
  }

###############################################################################
# check routine to test internal state of corruptions

sub _check
  {
  # no checks yet, pull it out from the test suite
  my ($x) = $_[1];
  return "$x is not a reference to Bit::Vector" if ref($x) ne 'Bit::Vector';
  return 0;
  }

sub __reduce
  { 
  # internal reduction to make minimum size
  my ($bv) = @_;

  # print "reduce: ",$bv->Size()," max: ",$bv->Max(),"\n";
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
#    print "Resize $size => $new_size (by ",
#     $size-$new_size, " bits or ",int(10000-10000*$new_size/$size)/100,"%)\n";
    $bv->Resize($new_size) if $new_size != $size;
    }
  return $bv;
  }

1;
__END__

=head1 NAME

Math::BigInt::BitVect - Use Bit::Vector for Math::BigInt routines

=head1 SYNOPSIS

Provides support for big integer calculations via means of Bit::Vector, a
fast C library by Steffen Beier.

See the section PERFORMANCE in L<Math::BigInt> for when to use this module and
when not.

=head1 LICENSE
 
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. 

=head1 AUTHOR

Tels http://bloodgate.com in 2001.
The used module Bit::Vector is by Steffen Beyer. Thanx!

=head1 SEE ALSO

L<Math::BigInt>, L<Math::BigInt::Calc>, L<Bit::Vector>.

=cut
