#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);

my $ORACLE_HOME = "/usr/lib/oracle/11.2/client";
my $ORACLE_SID  = "XE";

$ENV{ORACLE_SID}  = $ORACLE_SID;
$ENV{ORACLE_HOME} = $ORACLE_HOME;
$ENV{PATH}        = "$ORACLE_HOME/bin";

my $rulefile = shift;
my $ruleset  = shift;
my $output   = "$ruleset.rul";
my $answer;

if ( !defined($rulefile) || !defined($ruleset) ) {
    print "No rule file or rule set provided on command line\n";
    print "syntax: extractRule.pl rulefile_name ruleset_name\n\n";
    exit;
}

if ( -e $output ) {
    print "output rule file exists, overwrite?\n";
    print "(Y)es or (N)o ";
    chomp( $answer = <STDIN> );
    if ( uc($answer) eq "N" ) {
        exit;
    } else {

        open( FILE, "<$rulefile" );
        open( OUT,  ">$output" );

      OUTER:
        while (<FILE>) {
            my $line = $_;

            if (/^\[$ruleset\]/) {   # if we find the ruleset we are looking for
                print OUT "$line";    # print the rule set
              LINE:
                while ( $line = <FILE> )
                {    # continue reading lines until the start of
                    chomp $line;    # the next rule of EOF
                    last if $line =~ /^\[/;    # next rule marker found
                    print OUT "$line\n";

                }

            }
        }

    }
}

close FILE;

sub toNumber {
    my $value = shift;

    if ( !$value ) {
        $value = 0;
    } else {

        $value = sprintf( "%.2f", $value / 100 );

    }

    return $value;
}    # end of function

sub trim {
    my @out = @_;
    for (@out) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @out : $out[0];
}

