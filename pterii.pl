#!/usr/bin/env perl

use 5.10.0;
use strict;
use warnings;

sub execPterii;
sub execPterii {
    my $code = shift;

    my @tokens;
    while ($code =~ m/
                     ([-+*\/%><!.^=|&~?A-LN-RT-XZ,;()\[\]{} ]       # single char
                     | :?[A-LN-RT-XZ_]                              # variables
                     | [fhkmnqtvwxyz]|[a-z].                        # function
                     | (["'`]) (?:\\.|(?!\2).)*\2                   # quote
                     | [0-9]+                                       # number
                     | M(.)   (?:\\.|(?!\3).)*\3                    # m regex
                     | [SY](.)(?:\\.|(?!\4).)*\4(?:(?!\4).|\\.)*\4  # s, y regex
                     | [\$@#](?:[A-Za-z]+|.)                        # variable
                     | \\[eln]|\\.(?:[A-Z]|[^\\]*\\)                # backslash seq
                     )/gx) {
        push @tokens, $1;
    }

    # the stack (1-letter variable name in case someone wants to use it in the
    # Pterii code
    my @s = ();
    # args used by almost every single operator/function
    my @args = ();
    # "grab args" -- update the @args variable
    my $ga = sub {
        # TODO cut off at last stack div
        @args = @s;
        @s = ();
    };

    my $comptoken = sub {
        my $token = shift;

        # let's handle easy constants first
        my $constmap = {
            ' '  => '',

            '+'  => '&$ga; push @s, shift @args; $s[-1] +=  $_ foreach @args;',
            '-'  => '&$ga; push @s, shift @args; $s[-1] -=  $_ foreach @args;',
            '*'  => '&$ga; push @s, shift @args; $s[-1] *=  $_ foreach @args;',
            '/'  => '&$ga; push @s, shift @args; $s[-1] /=  $_ foreach @args;',
            '%'  => '&$ga; push @s, shift @args; $s[-1] %=  $_ foreach @args;',
            '^'  => '&$ga; push @s, shift @args; $s[-1] **= $_ foreach @args;',
            '.'  => '&$ga; push @s, shift @args; $s[-1] .=  $_ foreach @args;',
            '!'  => '&$ga; push @s, 1;           $s[-1] &= !$_ foreach @args;',
            '&'  => '&$ga; push @s, 1;           $s[-1] &=  $_ foreach @args;',
            '|'  => '&$ga; push @s, 0;           $s[-1] |=  $_ foreach @args;',

            'ab' => '&$ga; push @s, map abs,      @args;',
            'ch' => '&$ga; push @s, map chomp,    @args;',
            'co' => '&$ga; push @s, map cos,      @args;',
            'ex' => '&$ga; push @s, map exp,      @args;',
            'lc' => '&$ga; push @s, map lc,       @args;',
            'pr' => '&$ga;          map print,    @args;',
            'sa' => '&$ga;          map say,      @args;',
            'si' => '&$ga; push @s, map sin,      @args;',
            'sl' => '&$ga;          map sleep $_, @args;',
            'sq' => '&$ga; push @s, map sqrt,     @args;',
            'uc' => '&$ga; push @s, map uc,       @args;',

            're' => '&$ga; push @s, reverse @args;',
            'so' => '&$ga; push @s, sort    @args;',

            'at' => '&$ga; push @s, atan2 $args[0], $args[1];',
            'dd' => '&$ga; push @s, $args[0]..$args[1];',
            'x'  => '&$ga; push @s, $args[0] x $args[1];',

            'jo' => '&$ga; push @s, join    $args[-1], @args[0..$#args-1];',
            'jO' => '&$ga; push @s, join    $args[0],  @args[1..$#args];',
            'sf' => '&$ga; push @s, sprintf $args[-1], @args[0..$#args-1];',
            'sF' => '&$ga; push @s, sprintf $args[0],  @args[1..$#args];',
            'sp' => '&$ga; push @s, split   $args[-1], @args[0..$#args-1];',
            'sP' => '&$ga; push @s, split   $args[0],  @args[1..$#args];',

            'di' => 'die;',
            'ra' => 'push @s, rand;',
            'ti' => 'push @s, time;',

            '(' => '(', ')' => ')', '[' => '[',
            ']' => ']', '{' => '{', '}' => '}'
        }->{$_};
        return $constmap if $constmap;

        # ok so it's more complicated than that ;(
        if ($token =~ /^([0-9]+|".*"|\$.*|\@.*)$/) {
            return "push \@s, $token;";
        } elsif ($token =~ /^`.*`$/) {
            $token = substr $token, 1, length($token) - 2;
            $token =~ s/\\`/`/g;
            $token =~ s/(['\\])/\\$1/g;
            return "push \@s, eval '$token';";
        } elsif (substr($token, 0, 1) eq '\\') {
            $token =~ s/\\//g;
            my $type = {
                'e' => 'else', 'E' => 'elsif', 'f' => 'for', 'i' => 'if',
                'l' => 'last', 'n' => 'next', 'r' => 'return', 'u' => 'until',
                'U' => 'unless', 'w' => 'while'
            }->{substr($token, 0, 1)};
            $token = substr $token, 1;

            if ($token eq '') {
                return $type;
            } else {
                $token =~ s/(['\\])/\\$1/g;
                return "$type((execPterii '$token')[0])";
            }
        } elsif ($token =~ /^:?[A-Z_]$/) {
            my $isAssignment = $token =~ /:/;
            $token =~ s/://;
            my ($varname, $vartype) = @{{
                'A' => ['a', '$'], 'B' => ['b', '$'], 'C' => ['c', '$'],
                'D' => ['d', '$'], 'E' => ['e', '$'], 'F' => ['f', '$'],
                'G' => ['g', '$'], '_' => ['_', '$'],
                'H' => ['a', '@'], 'I' => ['b', '@'], 'J' => ['c', '@'],
                'K' => ['d', '@'], 'L' => ['e', '@'], 'N' => ['f', '@'],
                'O' => ['g', '@'], 'P' => ['_', '@'],
                'Q' => ['a', '%'], 'R' => ['b', '%'], 'T' => ['c', '%'],
                'U' => ['d', '%'], 'V' => ['e', '%'], 'W' => ['f', '%'],
                'X' => ['g', '%'], 'Z' => ['_', '%'],
            }->{$token}};
            if ($isAssignment) {
                return "&\$ga; if(\@args>1){$vartype::$varname=\@args;}" .
                    "else{$vartype::$varname=\$args[0];}";
            } else {
                return "push \@s, $vartype::$varname;";
            }
        }
    };

    my $compiled = join(' ', map $comptoken->($_), @tokens);
    eval $compiled;
    return @s;
}

my $code = join('', <>);
print(execPterii $code);
