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

my $IV_UOFM   = "/tmp/IV-UOFM";
my $IV_ITMFIL = "/tmp/IV-ITMFIL";
my $IV_PCLASS = "/tmp/IV-PCLASS";
my $AR_CUSMAS = "/tmp/AR-CUSMAS";
my $iv_itmfil = undef;

my $key = undef;
my $record;

my $qty;
my $list;
my $dealer;
my $retail;
my $kosher;

my $catalog;
my $seasonal;
my $promotion;
my $liquidation;
my $special_order;
my $sample;
my $dry;
my $chill;
my $refer;
my $frozen;
my $publix;
my $greenwise;


my $dbh =
  DBI->connect( "dbi:Oracle:host=$dbhost;sid=$dbname", $dbuser, $dbpass )
  || die "Database connection not made: $DBI::errstr";

my $rc = $dbh->do("delete from IV_ITMFIL");
if ($rc) {
    print "$rc inventory record(s) deleted\n";
    sleep(5);
    $iv_itmfil = new DB::Appgen file => "$IV_ITMFIL";
    my $sth = $dbh->prepare(
        "insert into iv_itmfil (ITEM,SAMEAS,DESCRIPTION,SUBSTITUTE,PCLASS,
                          UOFM,QB,LIST,QOH,COST,PKG,RETAIL,DEALER,MCODE,KOSHER,PRIMARY_VENDOR,VENDOR_ITEM,CATALOG,SEASONAL,PROMOTION,LIQUIDATION,SPECIAL_ORDER,SAMPLE,DRY,CHILL,REFER,FROZEN,PUBLIX,GREENWISE,DIABETIC)
                         values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
    );
    while ( $key = $iv_itmfil->next() ) {
        $iv_itmfil->seek( key => $key );
        $record = $iv_itmfil->record;

        print "processing $record->[0]\n";
        if ( !defined $record->[1] ) {    # if there is no same as field
            if ( defined $record->[21] && $record->[21] > 0 ) {    # if Qty
                $qty = $record->[21] / 1000;
            } else {
                $qty = 0;
            }
            $list   = checkForNull( $record->[11] );    # test for null
            $dealer = checkForNull( $record->[152] );
            $retail = checkForNull( $record->[151] );
        }
        $sth->bind_param( 1,  $record->[0] );  # item
        $sth->bind_param( 2,  $record->[1] );  # same as
        $sth->bind_param( 3,  $record->[2] );  # description
        $sth->bind_param( 4,  $record->[3] );  # substitute
        $sth->bind_param( 5,  $record->[4] );  # price class
        $sth->bind_param( 6,  $record->[5] );  # u of m
        $sth->bind_param( 7,  $record->[9] );  # qb pricing
        $sth->bind_param( 8,  $list );            # list price
        $sth->bind_param( 9,  $qty );             # qoh
        $sth->bind_param( 10, $record->[22] );    # cost
        $sth->bind_param( 11, $record->[30] );    # pkg
        $sth->bind_param( 12, $retail );          # retail price
        $sth->bind_param( 13, $dealer );          # dealer price
        $sth->bind_param( 14, $record->[29] );    # mcode

        #$kosher = checkForNullChar( $record->[161] );  #kosher item (Y|N)

        $sth->bind_param( 15, $record->[161] );
        $sth->bind_param( 16, $record->[15] );   # vendor number
        $sth->bind_param( 17, $record->[16] );   # vendor item number

        $catalog = checkForNullChar($record->[165]);
        $sth->bind_param( 18, $catalog );   #  Catalog flag

        $seasonal = checkForNullChar($record->[166]);
        $sth->bind_param( 19, $seasonal );   #  Seasonal flag

        $promotion = checkForNullChar($record->[167]);
        $sth->bind_param( 20, $promotion );   # promotional flag

        $liquidation = checkForNullChar($record->[175]);
        $sth->bind_param( 21, $liquidation );   # Liquadition flag

        $special_order = checkForNullChar($record->[168]);
        $sth->bind_param( 22, $special_order );   # Special Order flag

        $sample = checkForNullChar($record->[169]);
        $sth->bind_param( 23, $sample );   # Sample flag


        $dry = checkForNullChar($record->[170]); 
        $sth->bind_param( 24, $dry );   # Dry good flag

        $chill = checkForNullChar($record->[176]);
        $sth->bind_param( 25, $chill );   # Chill flag

        $refer = checkForNullChar($record->[171]);
        $sth->bind_param( 26, $refer );   # Refer

        $frozen = checkForNullChar($record->[172]);
        $sth->bind_param( 27, $frozen );   # Frozen flag

        $publix = checkForNullChar($record->[173]);
        $sth->bind_param( 28, $publix );   # Publix flag

        $greenwise = checkForNullChar($record->[174]);
        $sth->bind_param( 29, $greenwise );   # Greenwise flag
        
        $sth->bind_param( 30, checkForNullChar($record->[178] ));   # diabetic
        
       

        $sth->execute();

    }
    $sth->finish;
}

$dbh->disconnect;
$iv_itmfil->close;

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
