#!perl
use 5.008;

use strict;
use warnings;
use utf8;

binmode(STDOUT,":encoding(UTF-8)");
binmode(STDERR,":encoding(UTF-8)");

use lib qw(
../lib/
./lib/
);

use Test::More;
use Test::More::UTF8;

use Levenshtein::Simple;
use Text::Levenshtein qw(distance);

my $examples1 = [
  [ '', ''],
  [ 'a', ''],
  [ '', 'b'],
  [ 'b', 'b'],
  ['ttatc__cg',
   '__agcaact'],
  ['abcabba_',
   'cb_ab_ac'],
   ['yqabc_',
    'zq__cb'],
  [ 'rrp',
    'rep'],
  [ 'a',
    'b' ],
  [ 'aa',
    'a_' ],
  [ 'abb',
    '_b_' ],
  [ 'a_',
    'aa' ],
  [ '_b_',
    'abb' ],
  [ 'ab',
    'cd' ],
  [ 'ab',
    '_b' ],
  [ 'ab_',
    '_bc' ],
  [ 'abcdef',
    '_bc___' ],
  [ 'abcdef',
    '_bcg__' ],
  [ 'xabcdef',
    'y_bc___' ],
  [ 'öabcdef',
    'ü§bc___' ],
  [ 'o__horens',
    'ontho__no'],
  [ 'Jo__horensis',
    'Jontho__nota'],
  [ 'horen',
    'ho__n'],
  [ 'Chrerrplzon',
    'Choereph_on'],
  [ 'Chrerr',
    'Choere'],
  [ 'rr',
    're'],
  [ 'abcdefg_',
    '_bcdefgh'],

  [ 'aabbcc',
    'abc'],
  [ 'aaaabbbbcccc',
    'abc'],
  [ 'aaaabbcc',
    'abc'],
];


my $examples2 = [
    [ 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVY_', # l=52
      '_bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVYZ'],
    [ 'abcdefghijklmnopqrstuvwxyz0123456789!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVY_',
      '_bcdefghijklmnopqrstuvwxyz0123456789!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ'],
    [ 'abcdefghijklmnopqrstuvwxyz0123456789"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVY_',
      '!'],
    [ '!',
      'abcdefghijklmnopqrstuvwxyz0123456789"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVY_'],
    [ 'abcdefghijklmnopqrstuvwxyz012345678!9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ',
      'abcdefghijklmnopqrstuvwxyz012345678_9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ'],
    [ 'abcdefghijklmnopqrstuvwxyz012345678_9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ',
      'abcdefghijklmnopqrstuvwxyz012345678!9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZ'],
    [ 'aaabcdefghijklmnopqrstuvwxyz012345678_9!"$%&/()=?ABCDEFGHIJKLMNOPQRSTUVYZZZ',
      'a!Z'],
];

# prefix/suffix optimisation
my $examples3 = [
    [ 'a',
      'a', ],
    [ 'aa',
      'aa', ],
    [ 'a_',
      'aa', ],
    [ 'aa',
      'a_', ],
    [ '_b_',
      'abb', ],
    [ 'abb',
      '_b_', ],
];



for my $examples ($examples1, $examples2, $examples3) {
    for my $example (@$examples) {
        my ($s1, $s2, $x, $y, $X, $Y, $m, $n) = prepare($example);

        my $distance = distance( $x, $y );

        is(
            Levenshtein::Simple->distance( $X, $Y ),
            $distance,
            "[$s1] m: $m, [$s2] n: $n -> D: " . $distance
        );
    }
}

# test prefix-suffix optimization
if (1) {
    my $prefix = 'a';
    my $infix  = 'b';
    my $suffix = 'c';

    my $max_length = 2;

    my @a_strings;

    for my $prefix_length1 (0..$max_length) {
        for my $infix_length1 (0..$max_length) {
            for my $suffix_length1 (0..$max_length) {
                my $a = $prefix x $prefix_length1
                    . $infix x $infix_length1
                    . $suffix x $suffix_length1;
                push @a_strings, $a;
            }
        }
    }

    for my $a (@a_strings) {
        for my $b (@a_strings) {
            my @a = split(//,$a);
            my $m = scalar @a;
            my @b = split(//,$b);
            my $n = scalar @b;
            my $A = join('',@a);
            my $B = join('',@b);

            my $distance = distance($A,$B);

            is(
                Levenshtein::Simple->distance(\@a,\@b),
                $distance,
                "[$a] m: $m, [$b] n: $n -> D: " . $distance
            );
        }
    }
}

# HINDI for testing combining characters
if (1) {
    my $string1 = 'राज्य';
    my $string2 = 'उसकी';
    my @base_lengths = (16);

    for my $base_length1 (@base_lengths) {
        my $mult1 = int($base_length1/length($string1)) + 1;
        my @a = split(//,$string1 x $mult1);
        my $m = scalar @a;
        for my $base_length2 (@base_lengths) {
            my $mult2 = int($base_length2/length($string2)) + 1;
            my @b = split(//,$string2 x $mult2);
            my $n = scalar @b;

            my $A = join('',@a);
            my $B = join('',@b);

            is(
                Levenshtein::Simple->distance(\@a,\@b),
                distance($A, $B),
                "[$string1 x $mult1] m: $m, [$string2 x $mult2] n: $n -> "
                    . distance($A, $B)
            );
        }
    }
}

# MEROITIC HIEROGLYPHIC LETTERs
if (1) {
    my $string1 = "\x{10980}\x{10981}\x{10983}";
    my $string2 = "\x{10981}\x{10980}\x{10983}\x{10982}";
    my @base_lengths = (16);

    for my $base_length1 (@base_lengths) {
        my $mult1 = int($base_length1/length($string1)) + 1;
        my @a = split(//,$string1 x $mult1);
        my $m = scalar @a;
        for my $base_length2 (@base_lengths) {
            my $mult2 = int($base_length2/length($string2)) + 1;
            my @b = split(//,$string2 x $mult2);
            my $n = scalar @b;

            my $A = join('',@a);
            my $B = join('',@b);

            is(
                Levenshtein::Simple->distance(\@a,\@b),
                distance($A, $B),
                "[$string1 x $mult1] m: $m, [$string2 x $mult2] n: $n -> "
                    . distance($A, $B)
            );
        }
    }
}

if (0) {
    my $a = [qw/a b d/ x 50];
    my $b = [qw/b a d c/ x 50];
    my $A = join('',$a);
    my $B = join('',$b);

    is(
        Levenshtein::Simple->distance($a, $b),
        distance($A, $B),
        '[qw/a b d/ x 50], [qw/b a d c/ x 50] -> ' . distance($A, $B)
    );
}

sub prepare {
    my ($example) = @_;

    my $s1 = $example->[0];
    my $s2 = $example->[1];
    my $x = $s1;
    $x =~ s/_//g;
    my $y = $s2;
    $y =~ s/_//g;

    my $X = [ split(//,$x) ];
    my $m = scalar @$X;
    my $Y = [ split(//,$y) ];
    my $n = scalar @$Y;

    return ($s1, $s2, $x, $y, $X, $Y, $m, $n);
}


done_testing;
