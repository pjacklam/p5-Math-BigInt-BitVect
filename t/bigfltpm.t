#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib'; # for running manually
  # chdir 't' if -d 't';
  plan tests => 983;
  }

use Math::BigInt lib => 'BitVect';
use Math::BigFloat;

my ($x,$y,$f,@args,$ans,$try,$ans1,$ans1_str,$setup);
while (<DATA>)
  {
  chop;
  $_ =~ s/#.*$//;	# remove comments
  $_ =~ s/\s+$//;	# trailing spaces
  next if /^$/;		# skip empty lines & comments
  if (s/^&//)
    {
    $f = $_;
    }
  elsif (/^\$/)
    {
    $setup = $_; $setup =~ s/^\$/\$Math::BigFloat::/;	# rnd_mode, div_scale 
    # print "$setup\n";
    }
  else
    {
    if (m|^(.*?):(/.+)$|)
      {
      $ans = $2;
      @args = split(/:/,$1,99);
      }
    else
      {
      @args = split(/:/,$_,99); $ans = pop(@args);
      }
    $try = "\$x = new Math::BigFloat \"$args[0]\";";
    if ($f eq "fnorm")
      {
        $try .= "\$x;";
      } elsif ($f eq "binf") {
        $try .= "\$x->binf('$args[1]');";
      } elsif ($f eq "bnan") {
        $try .= "\$x->bnan();";
      } elsif ($f eq "bone") {
        $try .= "\$x->bone('$args[1]');";
      } elsif ($f eq "bsstr") {
        $try .= "\$x->bsstr();";
      } elsif ($f eq "fneg") {
        $try .= "-\$x;";
      } elsif ($f eq "bfloor") {
        $try .= "\$x->bfloor();";
      } elsif ($f eq "bceil") {
        $try .= "\$x->bceil();";
      } elsif ($f eq "is_zero") {
        $try .= "\$x->is_zero()+0;";
      } elsif ($f eq "is_one") {
        $try .= "\$x->is_one()+0;";
      } elsif ($f eq "is_odd") {
        $try .= "\$x->is_odd()+0;";
      } elsif ($f eq "is_even") {
        $try .= "\$x->is_even()+0;";
      } elsif ($f eq "as_number") {
        $try .= "\$x->as_number();";
      } elsif ($f eq "fabs") {
        $try .= "abs \$x;";
      }elsif ($f eq "fround") {
        $try .= "$setup; \$x->fround($args[1]);";
      } elsif ($f eq "ffround") {
        $try .= "$setup; \$x->ffround($args[1]);";
      } elsif ($f eq "fsqrt") {
        $try .= "$setup; \$x->fsqrt();";
      }
    else
      {
      $try .= "\$y = new Math::BigFloat \"$args[1]\";";
      if ($f eq "fcmp") {
        $try .= "\$x <=> \$y;";
      } elsif ($f eq "fpow") {
        $try .= "\$x ** \$y;";
      } elsif ($f eq "fadd") {
        $try .= "\$x + \$y;";
      } elsif ($f eq "fsub") {
        $try .= "\$x - \$y;";
      } elsif ($f eq "fmul") {
        $try .= "\$x * \$y;";
      } elsif ($f eq "fdiv") {
        $try .= "$setup; \$x / \$y;";
      } elsif ($f eq "fmod") {
        $try .= "\$x % \$y;";
      } else { warn "Unknown op '$f'"; }
    }
    $ans1 = eval $try;
    if ($ans =~ m|^/(.*)$|)
      {
      my $pat = $1;
      if ($ans1 =~ /$pat/)
        {
        ok (1,1);
        }
      else
        {
        print "# '$try' expected: /$pat/ got: '$ans1'\n" if !ok(1,0);
        }
      }
    else
      {
      if ($ans eq "")
        {
        ok_undef ($ans1);
        }
      else
        {
        print "# Tried: '$try'\n" if !ok ($ans1, $ans);
        if (ref($ans1) eq 'Math::BigFloat')
	  {
	  #print $ans1->_trailing_zeros(),"\n";
          print "# Has trailing zeros after '$try'\n" 
	   if !ok ($ans1->{_m}->_trailing_zeros(), 0);
	  }
        } 
      } # end pattern or string
    }
  } # end while

# check whether new() for BigInts destroys them ($y == 12 in this case)
$x = Math::BigInt->new(1200); $y = Math::BigFloat->new($x);
ok ($y,1200); ok ($x,1200);

# all done

###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef
  {
  my $x = shift;

  ok (1,1) and return if !defined $x;
  ok ($x,'undef');
  }
   
__END__
&as_number
0:0
1:1
1.2:1
2.345:2
-2:-2
-123.456:-123
-200:-200
&binf
1:+:+inf
2:-:-inf
3:abc:+inf
&bnan
abc:NaN
2:NaN
-2:NaN
0:NaN
&bone
2:+:1
-2:-:-1
-2:+:1
2:-:-1
0::1
-2::1
abc::1
2:abc:1
&bsstr
+inf:+inf
-inf:-inf
abc:NaN
&fnorm
+inf:+inf
-inf:-inf
+infinity:NaN
+-inf:NaN
abc:NaN
   1 a:NaN
1bcd2:NaN
11111b:NaN
+1z:NaN
-1z:NaN
0:0
+0:0
+00:0
+0_0_0:0
000000_0000000_00000:0
-0:0
-0000:0
+1:1
+01:1
+001:1
+00000100000:100000
123456789:123456789
-1:-1
-01:-1
-001:-1
-123456789:-123456789
-00000100000:-100000
123.456a:NaN
123.456:123.456
0.01:0.01
.002:0.002
+.2:0.2
-0.0003:-0.0003
-.0000000004:-0.0000000004
123456E2:12345600
123456E-2:1234.56
-123456E2:-12345600
-123456E-2:-1234.56
1e1:10
2e-11:0.00000000002
# excercise _split
  .02e-1:0.002
   000001:1
   -00001:-1
   -1:-1
  000.01:0.01
   -000.0023:-0.0023
  1.1e1:11
-3e111:-3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-4e-1111:-0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
&fpow
2:2:4
1:2:1
1:3:1
-1:2:1
-1:3:-1
123.456:2:15241.383936
2:-2:0.25
2:-3:0.125
128:-2:0.00006103515625
abc:123.456:NaN
123.456:abc:NaN
+inf:123.45:+inf
-inf:123.45:-inf
+inf:-123.45:+inf
-inf:-123.45:-inf
&fneg
abc:NaN
+0:0
+1:-1
-1:1
+123456789:-123456789
-123456789:123456789
+123.456789:-123.456789
-123456.789:123456.789
&fabs
abc:NaN
+0:0
+1:1
-1:1
+123456789:123456789
-123456789:123456789
+123.456789:123.456789
-123456.789:123456.789
&fround
$rnd_mode = "trunc"
+10123456789:5:10123000000
-10123456789:5:-10123000000
+10123456789.123:5:10123000000
-10123456789.123:5:-10123000000
+10123456789:9:10123456700
-10123456789:9:-10123456700
+101234500:6:101234000
-101234500:6:-101234000
$rnd_mode = "zero"
+20123456789:5:20123000000
-20123456789:5:-20123000000
+20123456789.123:5:20123000000
-20123456789.123:5:-20123000000
+20123456789:9:20123456800
-20123456789:9:-20123456800
+201234500:6:201234000
-201234500:6:-201234000
$rnd_mode = "+inf"
+30123456789:5:30123000000
-30123456789:5:-30123000000
+30123456789.123:5:30123000000
-30123456789.123:5:-30123000000
+30123456789:9:30123456800
-30123456789:9:-30123456800
+301234500:6:301235000
-301234500:6:-301234000
$rnd_mode = "-inf"
+40123456789:5:40123000000
-40123456789:5:-40123000000
+40123456789.123:5:40123000000
-40123456789.123:5:-40123000000
+40123456789:9:40123456800
-40123456789:9:-40123456800
+401234500:6:401234000
-401234500:6:-401235000
$rnd_mode = "odd"
+50123456789:5:50123000000
-50123456789:5:-50123000000
+50123456789.123:5:50123000000
-50123456789.123:5:-50123000000
+50123456789:9:50123456800
-50123456789:9:-50123456800
+501234500:6:501235000
-501234500:6:-501235000
$rnd_mode = "even"
+60123456789:5:60123000000
-60123456789:5:-60123000000
+60123456789:9:60123456800
-60123456789:9:-60123456800
+601234500:6:601234000
-601234500:6:-601234000
+60123456789.0123:5:60123000000
-60123456789.0123:5:-60123000000
&ffround
$rnd_mode = "trunc"
+1.23:-1:1.2
+1.234:-1:1.2
+1.2345:-1:1.2
+1.23:-2:1.23
+1.234:-2:1.23
+1.2345:-2:1.23
+1.23:-3:1.23
+1.234:-3:1.234
+1.2345:-3:1.234
-1.23:-1:-1.2
+1.27:-1:1.2
-1.27:-1:-1.2
+1.25:-1:1.2
-1.25:-1:-1.2
+1.35:-1:1.3
-1.35:-1:-1.3
-0.0061234567890:-1:0
-0.0061:-1:0
-0.00612:-1:0
-0.00612:-2:0
-0.006:-1:0
-0.006:-2:0
-0.0006:-2:0
-0.0006:-3:0
-0.0065:-3:/-0\.006|-6e-03
-0.0065:-4:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
-0.0065:-5:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
0.05:0:0
0.5:0:0
0.51:0:0
0.41:0:0
$rnd_mode = "zero"
+2.23:-1:/2.2(?:0{5}\d+)?
-2.23:-1:/-2.2(?:0{5}\d+)?
+2.27:-1:/2.(?:3|29{5}\d+)
-2.27:-1:/-2.(?:3|29{5}\d+)
+2.25:-1:/2.2(?:0{5}\d+)?
-2.25:-1:/-2.2(?:0{5}\d+)?
+2.35:-1:/2.(?:3|29{5}\d+)
-2.35:-1:/-2.(?:3|29{5}\d+)
-0.0065:-1:0
-0.0065:-2:/-0\.01|-1e-02
-0.0065:-3:/-0\.006|-6e-03
-0.0065:-4:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
-0.0065:-5:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
0.05:0:0
0.5:0:0
0.51:0:1
0.41:0:0
$rnd_mode = "+inf"
+3.23:-1:/3.2(?:0{5}\d+)?
-3.23:-1:/-3.2(?:0{5}\d+)?
+3.27:-1:/3.(?:3|29{5}\d+)
-3.27:-1:/-3.(?:3|29{5}\d+)
+3.25:-1:/3.(?:3|29{5}\d+)
-3.25:-1:/-3.2(?:0{5}\d+)?
+3.35:-1:/3.(?:4|39{5}\d+)
-3.35:-1:/-3.(?:3|29{5}\d+)
-0.0065:-1:0
-0.0065:-2:/-0\.01|-1e-02
-0.0065:-3:/-0\.006|-6e-03
-0.0065:-4:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
-0.0065:-5:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
0.05:0:0
0.5:0:1
0.51:0:1
0.41:0:0
$rnd_mode = "-inf"
+4.23:-1:/4.2(?:0{5}\d+)?
-4.23:-1:/-4.2(?:0{5}\d+)?
+4.27:-1:/4.(?:3|29{5}\d+)
-4.27:-1:/-4.(?:3|29{5}\d+)
+4.25:-1:/4.2(?:0{5}\d+)?
-4.25:-1:/-4.(?:3|29{5}\d+)
+4.35:-1:/4.(?:3|29{5}\d+)
-4.35:-1:/-4.(?:4|39{5}\d+)
-0.0065:-1:0
-0.0065:-2:/-0\.01|-1e-02
-0.0065:-3:/-0\.007|-7e-03
-0.0065:-4:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
-0.0065:-5:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
0.05:0:0
0.5:0:0
0.51:0:1
0.41:0:0
$rnd_mode = "odd"
+5.23:-1:/5.2(?:0{5}\d+)?
-5.23:-1:/-5.2(?:0{5}\d+)?
+5.27:-1:/5.(?:3|29{5}\d+)
-5.27:-1:/-5.(?:3|29{5}\d+)
+5.25:-1:/5.(?:3|29{5}\d+)
-5.25:-1:/-5.(?:3|29{5}\d+)
+5.35:-1:/5.(?:3|29{5}\d+)
-5.35:-1:/-5.(?:3|29{5}\d+)
-0.0065:-1:0
-0.0065:-2:/-0\.01|-1e-02
-0.0065:-3:/-0\.007|-7e-03
-0.0065:-4:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
-0.0065:-5:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
0.05:0:0
0.5:0:1
0.51:0:1
0.41:0:0
$rnd_mode = "even"
+6.23:-1:/6.2(?:0{5}\d+)?
-6.23:-1:/-6.2(?:0{5}\d+)?
+6.27:-1:/6.(?:3|29{5}\d+)
-6.27:-1:/-6.(?:3|29{5}\d+)
+6.25:-1:/6.(?:2(?:0{5}\d+)?|29{5}\d+)
-6.25:-1:/-6.(?:2(?:0{5}\d+)?|29{5}\d+)
+6.35:-1:/6.(?:4|39{5}\d+|29{8}\d+)
-6.35:-1:/-6.(?:4|39{5}\d+|29{8}\d+)
-0.0065:-1:0
-0.0065:-2:/-0\.01|-1e-02
-0.0065:-3:/-0\.006|-7e-03
-0.0065:-4:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
-0.0065:-5:/-0\.006(?:5|49{5}\d+)|-6\.5e-03
0.05:0:0
0.5:0:0
0.51:0:1
0.41:0:0
0.01234567:-3:0.012
0.01234567:-4:0.0123
0.01234567:-5:0.01235
0.01234567:-6:0.012346
0.01234567:-7:0.0123457
0.01234567:-8:0.01234567
0.01234567:-9:0.01234567
0.01234567:-12:0.01234567
&fcmp
abc:abc:
abc:+0:
+0:abc:
+0:+0:0
-1:+0:-1
+0:-1:1
+1:+0:1
+0:+1:-1
-1:+1:-1
+1:-1:1
-1:-1:0
+1:+1:0
-1.1:0:-1
+0:-1.1:1
+1.1:+0:1
+0:+1.1:-1
+123:+123:0
+123:+12:1
+12:+123:-1
-123:-123:0
-123:-12:-1
-12:-123:1
+123:+124:-1
+124:+123:1
-123:-124:1
-124:-123:-1
0:0.01:-1
0:0.0001:-1
0:-0.0001:1
0:-0.1:1
0.1:0:1
0.00001:0:1
-0.0001:0:-1
-0.1:0:-1
0:0.0001234:-1
0:-0.0001234:1
0.0001234:0:1
-0.0001234:0:-1
0.0001:0.0005:-1
0.0005:0.0001:1
0.005:0.0001:1
0.001:0.0005:1
0.000001:0.0005:-2	# <0, but can't test this
0.00000123:0.0005:-2	# <0, but can't test this
0.00512:0.0001:1
0.005:0.000112:1
0.00123:0.0005:1
# infinity
-inf:5432112345:-1
+inf:5432112345:1
-inf:-5432112345:-1
+inf:-5432112345:1
-inf:54321.12345:-1
+inf:54321.12345:1
-inf:-54321.12345:-1
+inf:-54321.12345:1
+inf:+inf:0
-inf:-inf:0
# return undef
+inf:NaN:
NaN:+inf:
-inf:NaN:
NaN:-inf:
&fadd
abc:abc:NaN
abc:+0:NaN
+0:abc:NaN
+0:+0:0
+1:+0:1
+0:+1:1
+1:+1:2
-1:+0:-1
+0:-1:-1
-1:-1:-2
-1:+1:0
+1:-1:0
+9:+1:10
+99:+1:100
+999:+1:1000
+9999:+1:10000
+99999:+1:100000
+999999:+1:1000000
+9999999:+1:10000000
+99999999:+1:100000000
+999999999:+1:1000000000
+9999999999:+1:10000000000
+99999999999:+1:100000000000
+10:-1:9
+100:-1:99
+1000:-1:999
+10000:-1:9999
+100000:-1:99999
+1000000:-1:999999
+10000000:-1:9999999
+100000000:-1:99999999
+1000000000:-1:999999999
+10000000000:-1:9999999999
+123456789:+987654321:1111111110
-123456789:+987654321:864197532
-123456789:-987654321:-1111111110
+123456789:-987654321:-864197532
0.001234:0.0001234:0.0013574
&fsub
abc:abc:NaN
abc:+0:NaN
+0:abc:NaN
+0:+0:0
+1:+0:1
+0:+1:-1
+1:+1:0
-1:+0:-1
+0:-1:1
-1:-1:0
-1:+1:-2
+1:-1:2
+9:+1:8
+99:+1:98
+999:+1:998
+9999:+1:9998
+99999:+1:99998
+999999:+1:999998
+9999999:+1:9999998
+99999999:+1:99999998
+999999999:+1:999999998
+9999999999:+1:9999999998
+99999999999:+1:99999999998
+10:-1:11
+100:-1:101
+1000:-1:1001
+10000:-1:10001
+100000:-1:100001
+1000000:-1:1000001
+10000000:-1:10000001
+100000000:-1:100000001
+1000000000:-1:1000000001
+10000000000:-1:10000000001
+123456789:+987654321:-864197532
-123456789:+987654321:-1111111110
-123456789:-987654321:864197532
+123456789:-987654321:1111111110
&fmul
abc:abc:NaN
abc:+0:NaN
+0:abc:NaN
+0:+0:0
+0:+1:0
+1:+0:0
+0:-1:0
-1:+0:0
+123456789123456789:+0:0
+0:+123456789123456789:0
-1:-1:1
-1:+1:-1
+1:-1:-1
+1:+1:1
+2:+3:6
-2:+3:-6
+2:-3:-6
-2:-3:6
+111:+111:12321
+10101:+10101:102030201
+1001001:+1001001:1002003002001
+100010001:+100010001:10002000300020001
+10000100001:+10000100001:100002000030000200001
+11111111111:+9:99999999999
+22222222222:+9:199999999998
+33333333333:+9:299999999997
+44444444444:+9:399999999996
+55555555555:+9:499999999995
+66666666666:+9:599999999994
+77777777777:+9:699999999993
+88888888888:+9:799999999992
+99999999999:+9:899999999991
6:120:720
10:10000:100000
&fdiv
$div_scale = 40; $Math::BigFloat::rnd_mode = 'even'
abc:abc:NaN
abc:+1:abc:NaN
+1:abc:NaN
+0:+0:NaN
+0:+1:0
+1:+0:NaN
+0:-1:0
-1:+0:NaN
+1:+1:1
-1:-1:1
+1:-1:-1
-1:+1:-1
+1:+2:0.5
+2:+1:2
+10:+5:2
+100:+4:25
+1000:+8:125
+10000:+16:625
+10000:-16:-625
+999999999999:+9:111111111111
+999999999999:+99:10101010101
+999999999999:+999:1001001001
+999999999999:+9999:100010001
+999999999999999:+99999:10000100001
+1000000000:+9:111111111.1111111111111111111111111111111
+2000000000:+9:222222222.2222222222222222222222222222222
+3000000000:+9:333333333.3333333333333333333333333333333
+4000000000:+9:444444444.4444444444444444444444444444444
+5000000000:+9:555555555.5555555555555555555555555555556
+6000000000:+9:666666666.6666666666666666666666666666667
+7000000000:+9:777777777.7777777777777777777777777777778
+8000000000:+9:888888888.8888888888888888888888888888889
+9000000000:+9:1000000000
+35500000:+113:314159.2920353982300884955752212389380531
+71000000:+226:314159.2920353982300884955752212389380531
+106500000:+339:314159.2920353982300884955752212389380531
+1000000000:+3:333333333.3333333333333333333333333333333
2:25.024996000799840031993601279744051189762:0.07992009269196593320152084692285869265447
$div_scale = 20
+1000000000:+9:111111111.11111111111
+2000000000:+9:222222222.22222222222
+3000000000:+9:333333333.33333333333
+4000000000:+9:444444444.44444444444
+5000000000:+9:555555555.55555555556
+6000000000:+9:666666666.66666666667
+7000000000:+9:777777777.77777777778
+8000000000:+9:888888888.88888888889
+9000000000:+9:1000000000
1:10:0.1
1:100:0.01
1:1000:0.001
1:10000:0.0001
1:504:0.001984126984126984127
2:1.987654321:1.0062111801179738436
# the next two cases are the "old" behaviour, but are now (>v0.01) different
#+35500000:+113:314159.292035398230088
#+71000000:+226:314159.292035398230088
+35500000:+113:314159.29203539823009
+71000000:+226:314159.29203539823009
+106500000:+339:314159.29203539823009
+1000000000:+3:333333333.33333333333
$div_scale = 1
# round to accuracy 1 after bdiv
+124:+3:40
# reset scale for further tests
$div_scale = 40
&fmod
+0:0:NaN
+0:1:0
+3:1:0
#+5:2:1
#+9:4:1
#+9:5:4
#+9000:56:40
#+56:9000:56
&fsqrt
+0:0
-1:NaN
-2:NaN
-16:NaN
-123.45:NaN
nanfsqrt:NaN
+inf:+inf
-inf:NaN
+1:1
+2:1.41421356237309504880168872420969807857
+4:2
+16:4
+100:10
+123.456:11.11107555549866648462149404118219234119
+15241.38393:123.4559999756998444766131352122991626468
+1.44:1.2
&is_odd
abc:0
0:0
-1:1
-3:1
1:1
3:1
1000001:1
1000002:0
+inf:0
-inf:0
123.45:0
-123.45:0
2:0
&is_even
abc:0
0:1
-1:0
-3:0
1:0
3:0
1000001:0
1000002:1
2:1
+inf:0
-inf:0
123.456:0
-123.456:0
&is_zero
NaNzero:0
0:1
-1:0
1:0
&is_one
0:0
2:0
1:1
-1:0
-2:0
&bfloor
0:0
abc:NaN
+inf:+inf
-inf:-inf
1:1
-51:-51
-51.2:-52
12.2:12
&bceil
0:0
abc:NaN
+inf:+inf
-inf:-inf
1:1
-51:-51
-51.2:-51
12.2:13
