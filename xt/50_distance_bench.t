#!perl
use 5.006;

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

use Benchmark qw(:all) ;
#use Data::Dumper;

### the fast ones (XS implementations)
use Text::Levenshtein::BVXS;
use Text::Levenshtein::XS qw(distance);


use Text::Fuzzy;
#use Text::Levenshtein::Edlib; # does not install
use Text::Levenshtein::Flexible;
use Text::LevenshteinXS; # no UTF-8
use Text::Levenshtein::XS;

#use Text::Levenshtein::BVmyers;
#use Text::Levenshtein::BVhyrr;


# the slow ones (PP implementations)
use Levenshtein::Simple;
use String::Approx 'adist'; # fails tests
use Text::Fuzzy::PP;
use Text::Levenshtein;
use Text::Levenshtein::BV;
use Text::WagnerFischer qw(distance);

my $tests = [
    {
        name    => 'ASCII len~10: Chrerrplzon, Choerephon',
        strings => [ qw(Chrerrplzon Choerephon) ],
        arrays  => [
            [split(//,'Chrerrplzon')],
            [split(//,'Choerephon')]
        ],
        test_on => 1,
    },
    {
        name    => 'UTF-8 len 10: Chſeſplzon, Choeſephon',
        strings => [ qw( Chſeſplzon Choeſephon ) ],
        arrays  => [
            [split(//,'Chſeſplzon')],
            [split(//,'Choeſephon')]
        ],
        test_on => 1,
    },
    {
        name    => 'ASCII len=50: a..zA..X, b..zA..Y',
        strings => [ qw(
            abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX
            bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY
        ) ],
        arrays  => [
            [split(//,'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX')],
            [split(//,'bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY')]
        ],
        test_on => 1,
    },
    {
        name    => 'ASCII len=50 prefix/suffix: a..z0A..W, a..z1A..W',
        strings => [ qw(
            abcdefghijklmnopqrstuvwxyz0ABCDEFGHIJKLMNOPQRSTUVW
            abcdefghijklmnopqrstuvwxyz1ABCDEFGHIJKLMNOPQRSTUVW
        ) ],
        arrays  => [
            [split(//,'abcdefghijklmnopqrstuvwxyz0ABCDEFGHIJKLMNOPQRSTUVW')],
            [split(//,'abcdefghijklmnopqrstuvwxyz1ABCDEFGHIJKLMNOPQRSTUVW')]
        ],
        test_on => 1,
    },
    {
        name    => 'UTF-8 50/50: "Chſeſplzon"x5, "Choeſephon"x5',
        strings => [
            "Chſeſplzon"x5,
            "Choeſephon"x5
        ],
        arrays  => [
            [split(//, "Chſeſplzon"x5)],
            [split(//, "Choeſephon"x5)]
        ],
        test_on => 1,
    },
];

print "\n", 'Levenshtein XS modules', "\n";

for my $test (@$tests) {
    next unless $test->{test_on};

    print "\n\n", "*** Test $test->{name}", "\n";

    my $tf   = Text::Fuzzy->new( $test->{strings}->[0] );

    my $distance = Levenshtein::Simple->distance( @{$test->{arrays}} );

    is( $tf->distance( $test->{strings}->[1] ), $distance,
        "$test->{name} Text::Fuzzy distance == $distance"
    );
    is( &Text::Levenshtein::Flexible::levenshtein( @{$test->{strings}} ), $distance,
        "$test->{name} Text::Levenshtein::Flexible distance == $distance"
    );
    is( &Text::Levenshtein::XS::distance( @{$test->{strings}} ), $distance,
        "$test->{name} Text::Levenshtein::XS distance == $distance"
    );
    is( &Text::Levenshtein::BVXS::distance( @{$test->{strings}} ), $distance,
        "$test->{name} Text::Levenshtein::BVXS distance == $distance"
    );

    print "\n", 'Benchmark XS modules', "\n";

    cmpthese( -1, {
        'T::Fuzzy' => sub {
            $tf->distance( $test->{strings}->[1] )
        },
        'TL::Flex' => sub {
            &Text::Levenshtein::Flexible::levenshtein( @{$test->{strings}} )
        },
        'TL::XS' => sub {
            &Text::Levenshtein::XS::distance( @{$test->{strings}} )
        },
        'TL::BVXS' => sub {
            &Text::Levenshtein::BVXS::distance( @{$test->{strings}} )
        },
        #'BVXS::noop' => sub {
        #    &Text::Levenshtein::BVXS::noop( @{$test->{strings}} )
        #},
        #'BVXS::noutf' => sub {
        #    &Text::Levenshtein::BVXS::noutf( @{$test->{strings}} )
        #},
    });

}

if (1) {
print "\n", 'Levenshtein PP modules', "\n";

for my $test (@$tests) {
    next unless $test->{test_on};

    print "\n\n", "*** Test $test->{name}", "\n";

    my $tf   = Text::Fuzzy::PP->new( $test->{strings}->[0] );

    my $distance = Levenshtein::Simple->distance( @{$test->{arrays}} );

    is( $tf->distance( $test->{strings}->[1] ), $distance,
        "$test->{name} Text::Fuzzy::PP distance == $distance"
    );
    is( Text::Levenshtein::BV->distance( @{$test->{arrays}} ), $distance,
        "$test->{name} Text::Levenshtein::BV distance == $distance"
    );
    is( &Text::Levenshtein::distance( @{$test->{strings}} ), $distance,
        "$test->{name} Text::Levenshtein distance == $distance"
    );
    is( &Text::WagnerFischer::distance( @{$test->{strings}} ), $distance,
        "$test->{name} Text::WagnerFischer distance == $distance"
    );

    print "\n", 'Benchmark PP modules', "\n";

    cmpthese( -1, {
        'L::Simple' => sub {
            Levenshtein::Simple->distance( @{$test->{arrays}} )
        },
        'T::Fuzz::PP' => sub {
            $tf->distance( $test->{strings}->[1] )
        },
        'T::L' => sub {
            &Text::Levenshtein::distance( @{$test->{strings}} )
        },
        'T::L::BV' => sub {
            Text::Levenshtein::BV->distance( @{$test->{arrays}} )
        },
        'T::WF' => sub {
            &Text::WagnerFischer::distance( @{$test->{strings}} )
        },
    });

}
}


done_testing();
