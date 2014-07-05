#!/usr/bin/perl
use DBI;
use DB::Appgen;

use strict;
use warnings;

my $ORACLE_HOME = "/usr/lib/oracle/11.2/client";
my $ORACLE_SID  = "XE";

$ENV{ORACLE_SID}  = $ORACLE_SID;
$ENV{ORACLE_HOME} = $ORACLE_HOME;
$ENV{PATH}        = "$ORACLE_HOME/bin";

my $DBHOST=shift;
my $PASSWD=shift;

 if (!defined $DBHOST) {
     print "No Oracle Host defined\n";
     exit;
 }
 if (!defined $PASSWD) {
     print "No Password defined\n";
     exit;
 }

my $dbhost = "$DBHOST";
my $dbname = "XE";
my $dbuser = "rader";
my $dbpass = "$PASSWD";

my @attr33;
my @attr34;
my $factor;

#my $dbhost = "192.168.10.121";
#my $dbname = "XE";
#my $dbuser = "ges";
#my $dbpass = "sv44";

#my $ag_source = "/tmp/IV-ITMFIL.1";
my $ag_source = "/home/ag6/IV/IV-ITMFIL.1";

my $key = undef;
my $data;
my $db;

my $list;
my $cost;

my $newList;

$db = new DB::Appgen file => "$ag_source";

while ( $key = $db->next() ) {

    $db->seek( key => $key, lock => 1 );

    #next if $key ne "047CC7";
    $data = $db->record;

    next if defined $data->[1];    # if this is an alernate item

    $list = $data->[11];

    print "key is: $key\t";

    next if !defined($list);       #eq 0;
    $newList = ( $list * .020 ) + $list;

    @attr33 = $db->attribute( attribute => 33 );    # look for addl um

    my $kount = -1;
    $kount =
      $db->value_length( attribute => 33, value => 1 );    #how many addl units

    #    print "kount is: $kount value is:->@attr33<-\n";

    if ( $kount > 0 ) {
        $factor = $db->extract( attribute => 34, value => 1 ) / 1000;

    }

    $newList = toNumber( $newList, 2 );
    my $vlist = $newList;
    $vlist =~ tr/.//d;    # remove decimal point

    my $newUMList = $factor * $vlist;
    my $newUMCost = $factor * $data->[22];

    $cost = toNumber( $data->[22], 3 );    # get the cost
    $list = toNumber( $list,       2 );

    print "Print list: $list\t New list: $newList\tCost: $cost\n";
    $db->replace( attribute => 13, value => 1, text => $vlist );
    $db->replace( attribute => 23, value => 1, text => $data->[22] );
    $db->replace( attribute => 14, value => 1, text => "16752" );

    # alter UM pricing
    $db->replace( attribute => 79, value => 1, text => $newUMList );
    $db->replace( attribute => 80, value => 1, text => $newUMCost );
    $db->replace( attribute => 81, value => 1, text => "16752" );

    # reset pricing
    #$db->replace( attribute => 13, value => 1, text => " ");
    #$db->replace( attribute => 23, value => 1, text => " ");
    #$db->replace( attribute => 14, value => 1, text => " ");
    #$db->replace( attribute => 79, value => 1, text => " ");
    #$db->replace( attribute => 80, value => 1, text => " ");
    #$db->replace( attribute => 81, value => 1, text => " " );
    $db->commit;
    $db->release;

}

$db->close;
print "Appgen DB closed\n";

sub toNumber {
    my $value     = shift;
    my $precision = shift;

    if ( !$value ) {
        $value = 0;
    } else {

        if ( $precision == 2 ) {
            $value = sprintf( "%.2f", $value / 100 );
        } else {
            $value = sprintf( "%.3f", $value / 1000 );

        }

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

