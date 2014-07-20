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

my $table_name;    # Oracle table name to be updated
$table_name = "IV_STATUS";

my $ag_handle;     # Appgen database handle

# local native Appgen file to be processed
my $ag_source = "/tmp/IV-STATUS";

my $key;
my $db;
my $record;

my $mvCount;

my $item      = "";
my $whse      = "";
my $committed = 0;
my $available = 0;
my $on_order  = 0;
my $qoh       = 0;
my $mtd       = 0;
my $ytd       = 0;

my $cnt = 0;
my $tcommit    = 0;
my $ton_ord    = 0;

system("/home/ag6/bin/show $ag_source > /tmp/iv-keys");

system("/home/ggraves/bin/import /tmp/iv-keys /tmp/IV-STATUS");

$db = new DB::Appgen file => "$ag_source";

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

my $dbh;
$dbh = DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $rc = $dbh->do("delete from IV_STATUS");
if ($rc) {
    print "$rc status record(s) deleted\n";
    sleep(5);

    my $sth = $dbh->prepare(
"insert into $table_name (item,whse,available,committed,on_order,qoh,sold_mtd,sold_ytd) values(?,?,?,?,?,?,?,?)"
    );

    $ag_handle = new DB::Appgen file => "$ag_source";
    while ( $key = $ag_handle->next() ) {
        $ag_handle->seek( key => $key );
        $record = $ag_handle->record;
        $mvCount = 0;
        $mvCount = $ag_handle->values_number( attribute => 9 );

        $mvCount = 0 if ( !defined($mvCount) );

        print "cnt $mvCount ";

        ( $item, $whse ) = split( /\*/, $record->[0], 2 );
     next if $whse ne "1";
        $qoh = $ag_handle->extract( attribute => 8, value => 1 );
        $qoh = toNumber( $qoh, 3 ) / 10;

        $mtd = $ag_handle->extract( attribute => 23, value => 1 );
        $mtd = toNumber( $mtd, 3 ) / 10;

        $ytd = $ag_handle->extract( attribute => 23, value => 2 );
        $ytd = toNumber( $ytd, 3 ) / 10;

        if ( $mvCount > 0 ) {
            for ( my $i = 1; $i <= $mvCount; $i++ ) {
                $tcommit = $ag_handle->extract( attribute => 12, value => $i );
                $tcommit = 0 if ( !defined($tcommit) );
                $committed += $tcommit;

                $ton_ord = $ag_handle->extract( attribute => 13, value => $i );
                $ton_ord  = 0 if ( !defined($ton_ord) );
                $on_order += $ton_ord;

                #print "$item:commit=>: $committed\n";

            }    #end of for loop
            $committed = toNumber( $committed, 3 ) / 10;
            $on_order  = toNumber( $on_order,  3 ) / 10;

        }    # end of if test for multi value in arrt 9
        $available = $qoh - $committed;

        $sth->bind_param( 1, $item );
        $sth->bind_param( 2, $whse );
        $sth->bind_param( 3, $available );
        $sth->bind_param( 4, $committed );
        $sth->bind_param( 5, $on_order );
        $sth->bind_param( 6, $qoh );
        $sth->bind_param( 7, $mtd );
        $sth->bind_param( 8, $ytd );

        $sth->execute();

        print "$item\t qoh: $qoh\t Comtd: $committed\t";

        print "Avail: $available\tOnOrd: $on_order\n ";

        #last if $cnt == 5;
        $cnt++;
        $committed = 0;
        $tcommit   = 0;
        $available = 0;
        $on_order  = 0;
        $ton_ord   = 0;
        $mtd       = 0;
        $ytd       = 0;
    }
    $sth->finish;
}
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

