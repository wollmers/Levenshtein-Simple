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
use Test::Deep;

use Levenshtein::Simple;

my $examples1 = [
    [ '', ''],
    [ 'a', ''],
    [ '', 'b'],
    [ 'b', 'b'],
    ['ttatccg',
     'agcaact'],
    ['abcabba_',
     'cbabac'],
    ['yqabc',
     'zqcb'],
    [ 'rrp',
      'rep'],
    [ 'a',
      'b' ],
    [ 'aa',
      'a' ],
    [ 'abb',
      'b' ],
    [ 'a',
      'aa' ],
    [ 'b',
      'abb' ],
    [ 'ab',
      'cd' ],
    [ 'ab',
      '_b' ],
    [ 'b_',
      'bc' ],
    [ 'abcdef',
      'bc' ],
    [ 'abcdef',
      'bcg' ],
    [ 'xabcdef',
      'ybc' ],
    [ 'öabcdef',
      'ü§bc' ],
    [ 'ohorens',
      'onthono'],
    [ 'Johorensis',
      'Jonthonota'],
    [ 'horen',
      'hon'],
    [ 'Chrerrplzon',
      'Choerephon'],
    [ 'Chrerr',
      'Choere'],
    [ 'rr',
      're'],
    [ 'abcdefg_',
      '_bcdefgh'],
    [ 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVY_',
      '_bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVYZ'],
];

my $examples2 = [
    [ 'gehe oder nachfolge; und gerade hiedurch iſt die Möglichkeit geboten, den',
      'gehe oder nachſolge; und gerade hiedur_h iſt die Wöglicht_it geboten, den'],
    [ 'Indem ich nun auch für dieſe zweite Auflage eine wohlwollende Auf⸗',
      'Inden ich nun auch für wuſlge ene wohlvolende Auſ⸗'],
    [ ' wohlwollende Auf⸗',
      ' wohlvo_lende Auſ⸗'],
];

my $examples3 = [
    ['isnt',
     'hint'],
    ['sue',
     'use'],
    ['gold',
     'glow'],
    ['eonnnnnicaio',
     'communicato'],
    ['Choerephon',
     'Chrerrplzon'],
    ['Algorithm',
     'Altruistic'],
    ['ABCABBA',
     'CBABAC'],
    ['ttatccg',
     'agcaact'],
];

my $lev = Levenshtein::Simple->new();

for my $examples ( $examples1, $examples3 )  {
    for my $example ( @$examples ) {

        my ($s1, $s2, $x, $y, $X, $Y, $m, $n) = prepare( $example );

        my $length_ses = scalar @{ $lev->ses( $X, $Y ) };
        my $solutions  = scalar @{ $lev->all_ses( $X, $Y ) };

        cmp_deeply(
            $lev->ses( $X ,$Y ),
            any( @{ $lev->all_ses($X, $Y) } ),
            "[$s1] m: $m, [$s2] n: $n -> lses: $length_ses solutions: $solutions"
        );
    }
}

for my $examples ( $examples3 )  {
    for my $example ( @$examples ) {

        my ($s1, $s2, $x, $y, $X, $Y, $m, $n) = prepare( $example );

        my $print = $lev->format_matrix( $X, $Y );
        my @lines = split(/\n/, $print);
        is( scalar @lines, $m + 5,
            "[$s1] m: $m, [$s2] n: $n -> print_matrix: " . scalar(@lines)
        );

        if (0) {
            print $print;
        }

        $print = $lev->format_alignment_path( $X, $Y );
        my @hunks = split(/\],\[/, $print);
        is( scalar @hunks, scalar @{ $lev->ses( $X, $Y ) },
            "[$s1] m: $m, [$s2] n: $n -> print_alignment_path: " . scalar(@hunks)
        );

        if (0) { print 'Path: ', $print, "\n"; }

        my $solutions  = $lev->all_ses( $X, $Y ) ;
        my $solution_count = 0;
        for my $solution (@$solutions) {
            $solution_count++;
            $print = $lev->_format_alignment_path( $X, $Y, $solution );
            @hunks = split(/\],\[/, $print);
            is( scalar @hunks, scalar @{ $solution },
            "[$s1] m: $m, [$s2] n: $n -> solution $solution_count: " . scalar(@hunks)
            );

            if (0) { print $print, "\n"; }

        }

        for my $gap_char (' ', undef) {
            $print = $lev->format_alignment( $X, $Y, $gap_char );
            my @lines = split(/\n/, $print);
            is( length($lines[0]), scalar @{ $lev->ses( $X, $Y ) },
                "[$s1] m: $m, [$s2] n: $n -> print_alignment: " . length($lines[0])
            );

            if (0) { print $print, "\n"; }
        }


        $print = $lev->ses2align( $X, $Y, $lev->ses( $X, $Y ) );
        is( scalar(@$print), scalar @{ $lev->ses( $X, $Y ) },
            "[$s1] m: $m, [$s2] n: $n -> ses2align: " . scalar(@$print)
        );

        for my $gap_char (' ', undef) {
            $print = $lev->align2strings(
                $lev->ses2align( $X, $Y,
                    $lev->ses( $X, $Y )
                ), $gap_char
            );
            is( length($print->[0]), scalar @{ $lev->ses( $X, $Y ) },
                "[$s1] m: $m, [$s2] n: $n -> align2strings: " . length($print->[0])
            );

            if (0) {
                print join("\n", @$print), "\n";
            }
        }

        my $metrics = $lev->metrics( $X, $Y );
        is( $metrics->{'distance'}, $lev->distance( $X, $Y ),
            "[$s1] m: $m, [$s2] n: $n -> metrics-distance: " . $metrics->{'distance'}
        );

        is( scalar @{$lev->ses2none( $lev->ses( $X, $Y ) )},
            scalar @{ $lev->ses( $X, $Y ) },
            "[$s1] m: $m, [$s2] n: $n -> ses2none: " . scalar(@{ $lev->ses( $X, $Y ) })
        );

        my $compact = $lev->ses2compact( $lev->ses( $X, $Y ) );
        is( length( $compact ),
            scalar @{ $lev->ses( $X, $Y ) },
            "[$s1] m: $m, [$s2] n: $n -> ses2compact: " . length( $compact )
        );
    }
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
