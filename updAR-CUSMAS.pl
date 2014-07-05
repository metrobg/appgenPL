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

#my $dbhost = "192.168.10.121";
#my $dbname = "XE";
#my $dbuser = "ges";
#my $dbpass = "sv44";

my $table_name = "AR_CUSMAS";
my $ag_source  = "/tmp/AR-CUSMAS";
my $ag_handle  = undef;

my $key = undef;
my $record;
my $cost_mtd;
my $cost_ytd;
my $sales_mtd;
my $sales_ytd;
my $class;
my $type;
my $salesrep;

$ag_handle = new DB::Appgen file => "$ag_source";

my $dbh =
  DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $sth = $dbh->prepare(
    "update $table_name set 
                           sales_mtd  	= ?,
                           sales_ytd  	= ?, 
                           cost_mtd   	= ?,
                           cost_ytd   	= ?,
                           cclass     	= ?,
                           ctype    	= ?,
                           salesrep   	= ? 
                           where custno	= ?"
);
my $cnt = 0;

while ( $key = $ag_handle->next() ) {
    $ag_handle->seek( key => $key );
    $record    = $ag_handle->record;
    $cost_mtd  = toNumber( $record->[25] );
    $cost_ytd  = toNumber( $record->[26] );
    $sales_mtd = toNumber( $record->[23] );
    $sales_ytd = toNumber( $record->[24] );

    $sth->bind_param( 8, $record->[0] );     #item code
    $sth->bind_param( 1, $sales_mtd );       # sales MTD
    $sth->bind_param( 2, $sales_ytd );       # sales YTD
    $sth->bind_param( 3, $cost_mtd );        # cost MTD
    $sth->bind_param( 4, $cost_ytd );        # cost YTD
    $sth->bind_param( 5, $record->[46] );    # customer class
    $sth->bind_param( 6, $record->[9] );     # customer type
    $sth->bind_param( 7, $record->[8] );     # sales rep
    $sth->execute();
    #print "$record->[0]\t cost MTD: $cost_mtd\t sales MTD: $sales_mtd\n";
    $cnt++;

    #last if ($cnt == 150);
}

$ag_handle->close;
$sth->finish;
$dbh->disconnect;

sub toNumber {
    my $value = shift;

    if ( !$value ) {
        $value = 0;
    } else {

        $value = sprintf( "%.2f", $value / 100 );

    }

    return $value;
}    # end of function

