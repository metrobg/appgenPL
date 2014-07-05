#!/usr/bin/perl
use DBI;
use DB::Appgen;

use strict;
use warnings;
use POSIX qw(strftime);

my $ORACLE_HOME = "/usr/lib/oracle/11.2/client";
my $ORACLE_SID  = "XE";

$ENV{ORACLE_SID}  = $ORACLE_SID;
$ENV{ORACLE_HOME} = $ORACLE_HOME;
$ENV{PATH}        = "$ORACLE_HOME/bin";

my $year  = strftime "%y", localtime;    # get timestamp for file name
my $month = strftime "%m", localtime;    # get timestamp for file name

$year += 2000;

if ( $month != 1 ) {
    $month -= 1;                         # the previous month
} else {
    $month = 12;
    $year -= 1;
}

$month = 2;
$year = 2014;

my $table_name;                          # Oracle table name to be updated
$table_name = "AR_BUYPROF";

my $ag_handle;                           # Appgen database handle

# local native Appgen file to be processed
my $ag_source = "/tmp/AR-BUYPROF";

my $key;
my $db;
my $data;

my @currentMonth;
my $mvNumber;
my $mvCount;
my $mvValue;
my $monthSales;

my $cnt = 0;
my $period = "SYSDATE -136";

print "current year is: $year\n";

#exit;

$db = new DB::Appgen file => "$ag_source";

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

my $dbh;
$dbh = DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $sth = $dbh->prepare("insert into $table_name (custno,amount) 
                         values(?,?)");
$ag_handle = new DB::Appgen file => "$ag_source";
while ( $key = $ag_handle->next() ) {
    $ag_handle->seek( key => $key );
    $data       = $ag_handle->record;
    $mvCount    = $ag_handle->values_number( attribute => 13 );
    $mvValue    = $ag_handle->extract( attribute => 13, value => $mvCount );
    $monthSales = $ag_handle->extract( attribute => $month, value => $mvCount );

    next if !defined($mvValue) or $mvValue != $year;
    $monthSales = toNumber( $monthSales, 2 );
    $sth->bind_param( 1, $data->[0] );

    #$sth->bind_param( 2, $period);
    $sth->bind_param( 2, $monthSales );

    $sth->execute();

    #print "insert into AR_BUYPROF values($data->[0],";

    print "Customer: $data->[0]\t  $monthSales\n ";

    #last if $cnt == 5;
    $cnt++;
}
$sth->finish;
$dbh->disconnect;
$ag_handle->close;

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

