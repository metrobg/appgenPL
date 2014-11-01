#!/usr/bin/perl

#############################################################
#         written by: Gilbert Graves                        #
#         10/22/2013                                        #
#############################################################
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

#my $dbhost = "192.168.10.121";
#my $dbname = "XE";
#my $dbuser = "user";
#my $dbpass = "s..v44";

my $dbhost = "$DBHOST";
my $dbname = "XE";
my $dbuser = "rader";
my $dbpass = "$PASSWD";

my $ag_handle = undef;
my $ag_source = "/tmp/AR-SLSMAN";
my $table_name = "AR_SLSMAN";

my $key = undef;
my $record;

system("/home/ag6/bin/dbcp -k 0 -d /tmp/AR-SLSMAN /tmp/BLANK"); 
# remove the house account prior to processing
my $dbh =
  DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $rc = $dbh->do("delete from $table_name where code <> '0'");
if ($rc) {
    print "$rc SLSMAN record(s) deleted\n";
    sleep(3);
    $ag_handle = new DB::Appgen file => "$ag_source";
    my $sth = $dbh->prepare(
        "insert into $table_name values(?,?)"
    );
    while ( $key = $ag_handle->next() ) {
        next if $key == "0";
        $ag_handle->seek( key => $key );
        $record = $ag_handle->record;

        print "processing $record->[0]\t\t$record->[1]\n";
        
        $sth->bind_param( 1,  $record->[0] );
        $sth->bind_param( 2,  $record->[1] );
        $sth->execute();

    }
    $sth->finish;
}

$dbh->disconnect;
$ag_handle->close;
system("/bin/rm -f /tmp/BLANK"); # remove so subsequent runs won't fail 

sub checkForNull {

    my $value = shift;

    if ( !defined $value or $value == 0 ) {
        return 0;
    } else {
        return $value / 100;
    }
}
