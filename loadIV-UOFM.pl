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

my $ag_handle = undef;
my $ag_source = "/tmp/IV-UOFM";
my $table_name = "IV_UOFM";

my $key = undef;
my $record;

my $dbh =
  DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $rc = $dbh->do("delete from $table_name");
if ($rc) {
    print "$rc UOFM record(s) deleted\n";
    sleep(3);
    $ag_handle = new DB::Appgen file => "$ag_source";
    my $sth = $dbh->prepare(
        "insert into $table_name values(?,?,?)"
    );
    while ( $key = $ag_handle->next() ) {
        $ag_handle->seek( key => $key );
        $record = $ag_handle->record;

        print "processing $record->[0]\t\t$record->[1]\n";
        
        $sth->bind_param( 1,  $record->[0] );
        $sth->bind_param( 2,  $record->[1] );
        $sth->bind_param( 3,  $record->[2] );
        $sth->execute();

    }
    $sth->finish;
}

$dbh->disconnect;
$ag_handle->close;

sub checkForNull {

    my $value = shift;

    if ( !defined $value or $value == 0 ) {
        return 0;
    } else {
        return $value / 100;
    }
}
