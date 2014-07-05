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
#my $dbuser = "es";
#my $dbpass = "fv44";

my $IV_UOFM   = "/tmp/IV-UOFM";
my $IV_ITMFIL = "/tmp/IV-ITMFIL";
my $IV_PCLASS = "/tmp/IV-PCLASS";
my $AR_CUSMAS = "/tmp/AR-CUSMAS";
my $iv_itmfil = undef;

my $key = undef;
my $data;
my $db;
my @attr33;
my @attr34;
my @attr35;
my @attr36;
my @attr37;

my $list;
my $cost;
my $factor;

my $cnt = 0;
my $record_count = 0;

#print "$rc additional unit of mea record(s) deleted\n";
$db = new DB::Appgen file => "$IV_ITMFIL";

my $dbh =
  DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $rc  = $dbh->do("delete from ADDL_UOFM");

print "deleted $rc additional UofM record(s)\n";

sleep(3);
my $sth = $dbh->prepare("insert into ADDL_UOFM (ITEM,UOFM,DESCRIPTION,
                        FACTOR,LIST,COST) values(?,?,?,?,?,?)");

while ( $key = $db->next() ) {
    $db->seek( key => $key );
    $data = $db->record;
    my @attr33 = $db->attribute( attribute => 33 );
    my $kount = $db->values_number( attribute => 33 ); #how many additional units
    next if $kount eq -1 or !defined $attr33[0];
    @attr34 = $db->attribute( attribute => 34 );
    @attr35 = $db->attribute( attribute => 35 );
    @attr36 = $db->attribute( attribute => 36 );
    @attr37 = $db->attribute( attribute => 37 );
    while ( $cnt < $kount ) {
        if ( !defined $attr33[$cnt] ) {  #handle null attribute
            $cnt++;     
            next;                          #process next attribute
        }
        else {


            $list   = toNumber($attr36[$cnt] ,2);
            $cost   = toNumber($attr37[$cnt] ,3);
            $factor = toNumber($attr34[$cnt] ,3);

            $sth->bind_param( 1, $data->[0] );       #item code
            $sth->bind_param( 2, $attr33[$cnt] );    #U of M
            $sth->bind_param( 3, $attr35[$cnt] );    # Description
            $sth->bind_param( 4, $factor );    # factor
            $sth->bind_param( 5, $list );    # list
            $sth->bind_param( 6, $cost );    # cost
            $sth->execute();
            print "$data->[0] list: $list cost: $cost\n";
            #print "$data->[0] $attr33[$cnt]\t $attr35[$cnt]\n";
            $cnt++;
            $record_count++;
        }
    }
    $cnt = 0;
}
 print "DONE $record_count Record(s) loaded\n";

$db->close;
$sth->finish;
$dbh->disconnect;


sub toNumber {
    my $value = shift;
    my $precision = shift;

    if ( !$value ) {
        $value = 0;
    } else {

        if($precision == 2) {
        $value = sprintf( "%.2f", $value / 100 );
          } else {
        $value = sprintf( "%.3f", $value / 1000 );

     }

    }

    return $value;
}    # end of function

