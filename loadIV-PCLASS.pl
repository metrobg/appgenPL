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
#my $dbuser = "ges";
#my $dbpass = "sifv44";

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

my $IV_UOFM   = "/tmp/IV-UOFM";
my $IV_ITMFIL = "/tmp/IV-ITMFIL";
my $IV_PCLASS = "/tmp/IV-PCLASS";
my $AR_CUSMAS = "/tmp/AR-CUSMAS";
my $iv_pclass = undef;

my $key = undef;
my $record;

my $qty;
my $list;
my $dealer;
my $retail;
my $dbh =
  DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $rc = $dbh->do("delete from IV_PCLASS");
if ($rc) {
    print "$rc Price Class record(s) deleted\n";
    sleep(3);
    $iv_pclass = new DB::Appgen file => "$IV_PCLASS";
    my $sth = $dbh->prepare(
        "insert into iv_pclass 
                         values(?,?)"
    );
    while ( $key = $iv_pclass->next() ) {
        $iv_pclass->seek( key => $key );
        $record = $iv_pclass->record;

        print "processing $record->[0]\t\t$record->[1]\n";
        if ( !defined $record->[1] ) {         # if there is no same as field
                next;
          
            }
        
        $sth->bind_param( 1,  $record->[0] );
        $sth->bind_param( 2,  $record->[1] );
        $sth->execute();

    }
    $sth->finish;
}

$dbh->disconnect;
$iv_pclass->close;

sub checkForNull {

    my $value = shift;

    if ( !defined $value or $value == 0 ) {
        return 0;
    } else {
        return $value / 100;
    }
}
