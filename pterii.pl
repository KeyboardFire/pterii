#!/usr/bin/env perl

use 5.10.0;
use strict;
use warnings;

my $code = join('', <>);

my @tokens;
while ($code =~ m/
                 ([-+*\/%><!.^=|&~:?A-LN-RT-XZ,;()\[\]{} ]      # single char
                 | [fhjkmnqtvwxyz]|[a-z].                       # function
                 | (["']) (?:\\.|(?!\2).)*\2                    # quote
                 | M(.)   (?:\\.|(?!\3).)*\3                    # m regex
                 | [SY](.)(?:\\.|(?!\4).)*\4(?:(?!\4).|\\.)*\4  # s, y regex
                 | [\$@#](?:[A-Za-z]+|.)                        # variable
                 | \\s.|\\.                                     # backslash seq
                 )/gx) {
    push @tokens, $1;
}

say foreach @tokens;
