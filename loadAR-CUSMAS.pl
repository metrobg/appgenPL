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

my $ag_source = "/tmp/AR-CUSMAS";
my $ag_handle = undef;

my $table_name = "TMP_AR_CUSMAS";

my $key = undef;
my $record;

my $cost_mtd;
my $cost_ytd;
my $sales_mtd;
my $sales_ytd;

my $dbh =
  DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $rc = $dbh->do("delete from $table_name");
if ($rc) {
    print "$rc Customer records deleted\n";
    sleep(3);

    $ag_handle = new DB::Appgen file => "$ag_source";
    my $sth = $dbh->prepare(
        "insert into $table_name (NAME,ADDRESS1,ADDRESS2,CITY,STATE,ZIP,PHONE1,CONTRACT,PRICE_CATEGORY,CONTACT1,CONTACT2,PHONE2,FAX,EMAIL,URL,OTHER,SALES_MTD,SALES_YTD,COST_MTD,COST_YTD,CCLASS,CTYPE,SALESREP,CUSTNO,LAST_SALE) 
   values(initcap(?),
          initcap(?),
                  ?,
          initcap(?),
                  ?,
             	  ?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
          	?,
		?,
		?,
		?,    
		?,    
		?,    
                ?,
		?)"    #custno
    );

    my $cnt       = 0;
    my $last_sale = 3;

    while ( $key = $ag_handle->next() ) {
        $ag_handle->seek( key => $key );
        $record = $ag_handle->record;

        $last_sale = $record->[157];
        $last_sale = 3 if !is_number($last_sale);

        $cost_mtd  = toNumber( $record->[25] ,2);
        $cost_ytd  = toNumber( $record->[26] ,2);
        $sales_mtd = toNumber( $record->[23] ,2);
        $sales_ytd = toNumber( $record->[24] ,2);

        $sth->bind_param( 1,  $record->[1] );     # name
        $sth->bind_param( 2,  $record->[2] );     #address1
        $sth->bind_param( 3,  $record->[3] );     #address 2
        $sth->bind_param( 4,  $record->[4] );     #city
        $sth->bind_param( 5,  $record->[5] );     #state
        $sth->bind_param( 6,  $record->[6] );     #zip
        $sth->bind_param( 7,  $record->[7] );     #phone1
        $sth->bind_param( 8,  $record->[29] );    #contract
        $sth->bind_param( 9,  $record->[22] );    #PRICE_CATEGORY
        $sth->bind_param( 10, $record->[28] );    #contact1
        $sth->bind_param( 11, $record->[43] );    #contact2
        $sth->bind_param( 12, $record->[40] );    #phone2
        $sth->bind_param( 13, $record->[41] );    #fax
        $sth->bind_param( 14, '' );               #email
        $sth->bind_param( 15, '' );               #url
        $sth->bind_param( 16, '' );               #other
        $sth->bind_param( 17, $sales_mtd );       # sales month to date
        $sth->bind_param( 18, $sales_ytd );       # sales ytd
        $sth->bind_param( 19, $cost_mtd );        # cost mtd
        $sth->bind_param( 20, $cost_ytd );        # cost ytd

        if(!defined($record->[46]) {
            $sth->bind_param( 21, 15);    # customer class default  = 15
        } else {
            $sth->bind_param( 21, $record->[46] );    # customer class
          }
        if(!defined($record->[9]) {
            $sth->bind_param( 21, "IN");    # customer class default  = IN
        } else {
            $sth->bind_param( 21, $record->[9] );    # customer type
          }


        $sth->bind_param( 23, $record->[8] );     # sales rep
        $sth->bind_param( 24, $record->[0] );     #custno
        $sth->bind_param( 25, $last_sale );       # last sale date
        print "customer \t $record->[0]\t $last_sale\n";
        $sth->execute();
        $cnt++;

            #last if ($cnt == 100);
    }

    $sth = $dbh->prepare(
        "insert into AR_CUSMAS select * from $table_name
                         where custno not in (select custno from AR_CUSMAS)"
    );
    $sth->execute();
    $sth->finish;
    $ag_handle->close;
} else {

    print "Unable to delete records from AR_CUSMAS table\n";
}
$dbh->disconnect;

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

sub is_number {
    my $n   = shift;
    my $ret = 1;
    $SIG{"__WARN__"} = sub { $ret = 0 };
    eval { my $x = $n + 1; };
    return $ret;
}
