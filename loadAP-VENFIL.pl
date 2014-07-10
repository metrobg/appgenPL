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

#my $dbhost = "192.168.10.121";
#my $dbname = "XE";
#my $dbuser = "ves";
#my $dbpass = "ifv44";

my $DBHOST = shift;
my $PASSWD = shift;

if ( !defined $DBHOST ) {
    print "No Oracle Host defined\n";
    exit;
}
if ( !defined $PASSWD ) {
    print "No Password defined\n";
    exit;
}

my $dbhost = "$DBHOST";
my $dbname = "XE";
my $dbuser = "rader";
my $dbpass = "$PASSWD";

my $ap_venfil = undef;
my $AP_VENFIL = "/tmp/AP-VENFIL";

my $key = undef;
my $record;

my $qty;
my $list;
my $dealer;
my $retail;
my $kosher;

my $dbh =
  DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $rc = $dbh->do("delete from AP_VENFIL");
if ($rc) {
    print "$rc vendor record(s) deleted\n";
    sleep(5);
    $ap_venfil = new DB::Appgen file => "$AP_VENFIL";
    my $sth = $dbh->prepare(
"insert into ap_venfil (VEND_id,vend_name,vend_addr1,vend_addr2,vend_city,vend_state,vend_zip,vend_phone)
                         values(?,?,?,?,?,?,?,?)"
    );
    while ( $key = $ap_venfil->next() ) {
        $ap_venfil->seek( key => $key );
        $record = $ap_venfil->record;

        print "processing $record->[0]\n";

        #next if ( !defined $record->[1] )     # if there is no name field

        $sth->bind_param( 1, $record->[0] );     #  vendor id
        $sth->bind_param( 2, $record->[1] );     #  vendor name
        $sth->bind_param( 3, $record->[2] );     #  vendor address 1
        $sth->bind_param( 4, $record->[3] );     #  vendor address 2
        $sth->bind_param( 5, $record->[4] );     #  vendor city
        $sth->bind_param( 6, $record->[30] );    #  vendor state
        $sth->bind_param( 7, $record->[31] );    #  vendor zipcode
        $sth->bind_param( 8, $record->[28] );    #  vendor phone

        $sth->execute();

    }
    $sth->finish;
}

$dbh->disconnect;
$ap_venfil->close;

sub checkForNull {

    my $value = shift;

    if ( !defined $value or $value == 0 ) {
        return 0;
    } else {
        return $value / 100;
    }
}

sub checkForNullChar {

    my $value = shift;

    if ( !defined $value ) {
        return "N";
    } else {
        return $value;
    }
}
