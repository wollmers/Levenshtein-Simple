package Levenshtein::Simple;

use strict;
use warnings;

use 5.006;
our $VERSION = '0.11';

use Data::Dumper;

our $EQ  = 0;
our $INS = 1;
our $DEL = 1;
our $SUB = 1;

sub new {
    my $class = shift;
    # uncoverable condition false
    bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

# https://en.wikipedia.org/wiki/Levenshtein_distance#Computing_Levenshtein_distance
# https://en.wikipedia.org/wiki/Wagner%E2%80%93Fischer_algorithm

# https://de.wikipedia.org/wiki/Levenshtein-Distanz
# backtracing

# https://rosettacode.org/wiki/Levenshtein_distance/Alignment#Perl

# http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#Python

# https://stackoverflow.com/questions/10638597/minimum-edit-distance-reconstruction

sub _matrix {
    my ($self, $X, $Y) = @_;

    my $m = scalar( @{$X} );
    my $n = scalar( @{$Y} );

    print 'matrix $m: ',$m,' $n: ',$n,"\n";

    my $c = [];

    for my $i (0..$m) { $c->[$i][0] = $i; }
    for my $j (0..$n) { $c->[0][$j] = $j; }

    my ($i,$j);

    my $cost = 0;

    for ($i=1; $i <= $m; $i++) {
        for ($j=1; $j <= $n; $j++) {
            if ($X->[$i-1] eq $Y->[$j-1]) {
                #$c->[1][$j] = $c->[0][$j-1]+1;
                $cost = $EQ;
            }
            else {
                $cost = $SUB;
            }
            $c->[$i][$j] = $self->min3(
                $c->[$i-1][$j]   + $DEL,   # deletion
                $c->[$i][$j-1]   + $INS,   # insertion
                $c->[$i-1][$j-1] + $cost,  # substitution
            );
        }
    }
    return $c;
}

sub distance {
    my ($self, $X, $Y) = @_;

    my $m = scalar @$X;
    my $n = scalar @$Y;

    my $c = $self->_matrix($X,$Y);

    return ($c->[$m][$n]);
}

sub ses {
    my ($self,$X,$Y) = @_;

    my $m = scalar @$X;
    my $n = scalar @$Y;

    my $c = $self->_matrix($X, $Y);

    my $R = [];

    my $i = $m;
    my $j = $n;

    while ($i > 0 || $j > 0) {
        # equal = match
        if ($i > 0 && $j > 0 && $c->[$i-1][$j-1] + $EQ == $c->[$i][$j]) {
            unshift @$R, [$i-1, $j-1, '='];
            $i--; $j--;
        }
        # deletion
        elsif ($i > 0 && $c->[$i-1][$j] + $DEL == $c->[$i][$j]) {
            unshift @$R, [$i-1, $j-1, '-'];
            $i--;
        }
        # insertion
        elsif ($j > 0 && $c->[$i][$j-1] + $INS == $c->[$i][$j]) {
            unshift @$R, [$i-1, $j-1, '+'];
            $j--;
        }
        # substitution
        elsif ($i > 0 && $j > 0 && $c->[$i-1][$j-1] + $SUB  == $c->[$i][$j]) {
            unshift @$R, [$i-1, $j-1, '~'];
            $i--; $j--;
        }
    }
    return $R;
}

use Data::Dumper;

sub all_ses {
    my ($self,$X,$Y) = @_;

    my $m = scalar @$X;
    my $n = scalar @$Y;

    my $c = $self->_matrix($X, $Y);

    my $paths = [[]];
    my $result = [];

    my $d = $c->[$m][$n];
    my $matches = ($m + $n) - (2 * $d);
    my $lSES = $d + $matches;
    print '$d=',$d,' $matches=',$matches,' $lSES=',$lSES,"\n";

    my $i = $m;
    my $j = $n;

    #my $max = $m + $n;
    my $max = $lSES;
    #while ($i > 0 || $j > 0) {
    #while ($max > 0) {
    while (scalar(@$paths) > 0) {
        $max--;
        my @temp;
        PATH: for my $path (@$paths) {
            $i = $m;
            $j = $n;
            #print '$path: ',Dumper($path);
            if (scalar @$path) {
                $i = $path->[0][0] + 1;
                $j = $path->[0][1] + 1;
                if    ($path->[0][2] eq '-') {$i--;}
                elsif ($path->[0][2] eq '+') {$j--;}
                else  {$i--;$j--;}
            }

            # skip path, if $i or $j are larger than remaining SES-entries
            #if ( $max+1 < $i || $max+1 < $j ) {
                #print '$max: ',$max,' $i: ',$i,' $j: ',$j,"\n";
            #    next PATH;
            #}

            # deletion
            if ($i > 0 && $c->[$i-1][$j] + $DEL == $c->[$i][$j]) {
                if ($i == 1 && $j <= 1) {
                    push @$result, [ [$i-1, $j-1, '-'], @$path ];
                }
                else {
                    push @temp, [[$i-1, $j-1, '-'], @$path];
                }
            }
            # insertion
            if ($j > 0 && $c->[$i][$j-1] + $INS == $c->[$i][$j]) {
                if ($i <= 1 && $j == 1) {
                    push @$result, [ [$i-1, $j-1, '+'], @$path ];
                }
                else {
                    push @temp, [[$i-1, $j-1, '+'], @$path];
                }
            }
            # equal = match
            if ($i > 0 && $j > 0 && $c->[$i-1][$j-1] + $EQ == $c->[$i][$j]) {
                if ($i == 1 && $j == 1) {
                    push @$result, [ [$i-1, $j-1, '='], @$path ];
                }
                else {
                    push @temp, [ [$i-1, $j-1, '='], @$path ];
                }
            }
            # substitution
            if ($i > 0 && $j > 0 && $c->[$i-1][$j-1] + $SUB  == $c->[$i][$j]) {
                if ($i == 1 && $j == 1) {
                    push @$result, [ [$i-1, $j-1, '~'], @$path ];
                }
                else {
                    push @temp, [[$i-1, $j-1, '~'], @$path];
                }
            }
        }
        @$paths = @temp;
    }

    return $result;
}

sub _print_matrix {
    my ($self, $X, $Y, $c) = @_;

    my $m = scalar @$X;
    my $n = scalar @$Y;

    #my $c = $self->_matrix($X, $Y);

    print "\n", 'Levenshtein matrix of ',join('',@$X),' ',join('',@$Y),"\n";
    print "\n";
    print '  ','  ';
    for my $j (0..$n-1) { print ' ',$Y->[$j]; }
    print "\n",'  ';
    for my $j (0..$n) { print ' ',$j; }
    print "\n";
    for my $i (1..$m) {
        print ' ', $X->[$i-1];
        for my $j (0..$n) { print ' ', $c->[$i][$j]; }
        print "\n";
    }
}

sub _print_alignment {
    my ($self, $X, $Y, $hunks) = @_;

    my $line1 = '';
    my $line2 = '';
    my $line3 = '';

    for my $hunk (@$hunks) {
        $line2 .= $hunk->[2];
        if ($hunk->[2] eq '-') {
            $line1 .= $X->[$hunk->[0]];
            $line3 .= '_';
        }
        elsif ($hunk->[2] eq '+') {
            $line1 .= '_';
            $line3 .= $Y->[$hunk->[1]];
        }
        else {
            $line1 .= $X->[$hunk->[0]];
            $line3 .= $Y->[$hunk->[1]];
        }
    }
    print $line1,"\n";
    print $line2,"\n";
    print $line3,"\n";
}

sub min3 {
  ($_[1] <= $_[2])
    ? ($_[1] <= $_[3]
      ? $_[1] : $_[3]
    )
    : ($_[2] <= $_[3]
      ? $_[2] : $_[3]
  );
}


sub max {
    ($_[0] > $_[1]) ? $_[0] : $_[1];
}



sub _all_lcs {
      my ($self,$ranks,$rank,$max) = @_;

      my $R = [[]];

      while ($rank <= $max) {
        my @temp;
        for my $path (@$R) {
              for my $hunk (@{$ranks->{$rank}}) {
                if (scalar @{$path} == 0) {
                      push @temp,[$hunk];
                }
                elsif (($path->[-1][0] < $hunk->[0]) && ($path->[-1][1] < $hunk->[1])) {
                      push @temp,[@$path,$hunk];
                }
              }
        }
        @$R = @temp;
        $rank++;
      }
      return $R;
}

# get all LCS of two arrays
# records the matches by rank
sub allLCS {
  my ($self,$X,$Y) = @_;

  my $m = scalar @$X;
  my $n = scalar @$Y;

  my $ranks = {}; # e.g. '4' => [[3,6],[4,5]]
  my $c = [];
  my ($i,$j);

  for (0..$m) { $c->[$_][0] = 0; }
  for (0..$n) { $c->[0][$_] = 0; }

  for ($i=1;$i<=$m;$i++) {
    for ($j=1;$j<=$n;$j++) {
      if ($X->[$i-1] eq $Y->[$j-1]) {
        $c->[$i][$j] = $c->[$i-1][$j-1]+1;
        push @{$ranks->{ $c->[$i][$j] } }, [$i-1,$j-1];
      }
      else {
        $c->[$i][$j] =
          ($c->[$i][$j-1] > $c->[$i-1][$j])
            ? $c->[$i][$j-1]
            : $c->[$i-1][$j];
      }
    }
  }
  my $max = scalar keys %$ranks;
  return $self->_all_lcs($ranks,1,$max);
}

1;
__END__

