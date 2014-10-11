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
$table_name = "OE_ITMHIST";

my $ag_handle;     # Appgen database handle

# local native Appgen file to be processed
my $ag_source = "/tmp/itmhist";

my $key;
my $db;
my $record;

my $mvCount;

my $item     = "";
my $invoice  = "";
my $customer = 0;
my $inv_date = 0;
my $qty      = 0;
my $price;

my $cnt = 0;

#$db = new DB::Appgen file => "$ag_source";

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

my $rc = $dbh->do("delete from OE_ITMHIST");
if ($rc) {
    print "$rc Item History record(s) deleted\n";
    sleep(5);

    my $sth = $dbh->prepare(
"insert into $table_name (key,item,invoice,customer,inv_date,quantity,price) values(?,?,?,?,to_date(?,'mm/dd/yy'),?,?)"
    );

    open( FILE, "< /tmp/itmhist" );
    while (<FILE>) {
        chomp;
        ( $item, $invoice, $customer, $inv_date, $qty, $price ) =
          split( /\s+/, $_, 6 );

        #$item = trim($item);
        next if $item =~ /===/ or length($item) == 0;
        $cnt++;

        $sth->bind_param( 1, $cnt );
        $sth->bind_param( 2, $item );
        $sth->bind_param( 3, $invoice );
        $sth->bind_param( 4, $customer );
        $sth->bind_param( 5, $inv_date );
        $sth->bind_param( 6, $qty );
        $sth->bind_param( 7, $price );

        $sth->execute();
        my $vlen = length($item);
        print "$item|$invoice|$customer|$inv_date|$qty|$price\n";

        #last if $cnt == 5;
    }

    $sth->finish;

}
$dbh->disconnect;
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

