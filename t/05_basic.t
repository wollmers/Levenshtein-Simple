#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(
../lib/
./lib/
);

use Test::More;
use Test::More::UTF8;

my $class = 'Levenshtein::Simple';

use_ok($class);

my $object = new_ok($class);

if (1) {
    ok( $object = $class->new(), '$class->new()' );
    is( scalar keys %$object, 6, 'is scalar keys %$object, 6' );

    ok( my $o2 = $object->new(), '$object->new()' );

    ok( $object = $class->new(1,2), '$class->new(1,2)' );
    is( $object->{1}, 2,            'is $object->{1}, 2' );

    ok( $object = $class->new({}), '$class->new({})');
    is( scalar keys %$object, 6,   'is scalar keys %$object, 6');

    ok( $object = $class->new({a => 1}), '$class->new({a => 1})' );
    is( $object->{a}, 1,                 'is $object->{a}, 1' );

    ok( $object = $class->new( a => 1, b => 2 ), '$class->new( a => 1, b => 2 )' );
    is( $object->{a}, 1, 'is $object->{a}, 1' );
    is( $object->{b}, 2, 'is $object->{b}, 2' );

    ok( $object->new(), '$object->new()' );
}

if (1) {
    my @cases = (
        [ qw/  0  0  0  0 / ],
        [ qw/  1  0  0  0 / ],
        [ qw/  0  1  0  0 / ],
        [ qw/  0  0  1  0 / ],
        [ qw/  1  0  1  0 / ],
        [ qw/  1  1  1  1 / ],
        [ qw/  2  2  2  2 / ],
        [ qw/  2  1  1  1 / ],
        [ qw/  1  2  1  1 / ],
        [ qw/  1  1  2  1 / ],
        [ qw/  0 -1 -1 -1 / ],
        [ qw/ -1  0 -1 -1 / ],
        [ qw/ -1 -1  0 -1 / ],
        [ qw/ -2 -2 -2 -2 / ],
        [ qw/ -2 -1 -1 -2 / ],
        [ qw/ -1 -2 -1 -2 / ],
        [ qw/ -1 -1 -2 -2 / ],
    );

    for my $case (@cases) {
        is( $class->min3(
            $case->[0], $case->[1], $case->[2]
            ),
            $case->[3],
            "min3: [$case->[0], $case->[1], $case->[2]] == $case->[3]"
        );
    }
}

done_testing;
