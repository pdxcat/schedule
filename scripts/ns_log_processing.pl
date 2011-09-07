#! /opt/csw/bin/perl
use strict;
use warnings;
use Date::Calc "Delta_DHMS";
use DBI;
use POSIX;
my $db = "schedule";
my $host = "db.cecs.pdx.edu";
my $user = "schedule";
my $password = "jm)n3Ffz6m";
my @unames = ();
my $leeway = 10;
my $start = ();
my $end = ();
my @strays = ();
my @logs = ();
my ($date,$shortdate,$weekday,$windate,$dbdate);

if(@ARGV == 3){
        my ($d1,$d2,$d3) = (shift(@ARGV), shift(@ARGV), shift(@ARGV));
        $date = strftime("%a %b %e",0,0,0,$d3,$d2-1,$d1-1900);
        $shortdate = strftime("%b%d", 0,0,0,$d3,$d2-1,$d1-1900);
        $weekday = strftime("%a", 0,0,0,$d3,$d2-1,$d1-1900);
        $windate = $d1 . $d2 . $d3;
        $dbdate = $d1 . "-" . $d2 . "-" . $d3;
}elsif(@ARGV == 0){
        chomp($date = `date +"%a %b %e"`);
        chomp($shortdate = `date +%b%d`);
        chomp($weekday = `date +%a`);
        chomp($windate = `date +%Y%m%d`);
        chomp($dbdate = `date +"%Y-%m-%d"`)
}else{
  die "Usage: schedLogging.pl [YYYY MM DD]\n"
};

#Get anduril logs
# Anduril is dead, long live anduril. 9/7/11
#foreach (`ssh -q schedule\@anduril.cat.pdx.edu \'last tty console| grep \"$date\"\'`){
#  /^(.+?)\s+.+?\s+.+?\s+.+?\s+.+?\s+.+?\s+(.+?)\s+.+?\s+(.+?)\s+(.+)/;
#  if($3 eq "logged"){
#    push @strays, "$1 $2 $3 anduril";
#  }elsif ($4 ne "(00:00)"){
#   push @logs, "$1 $2 $3 anduril";
#  };
#};

#Get chandra (dh sunray) logs
foreach (`ssh -q schedule\@chandra.cs.pdx.edu \'last dtlocal | grep \"$date\"\'`){
	# Some sample last output...
	# sunshine  dtlocal      :5               Wed Sep  7 13:37   still logged in
	# nibz      dtlocal      :3               Fri Sep  2 13:07 - down  (1+05:15)
	# nibz      dtlocal      :3               Thu Sep  1 17:24 - 13:06  (19:42)
	/^(.+?)\s+.+?\s+(.+?)\s+.+?(\d{2}:\d{2}).+?(\d{2}:\d{2}|logged).+?/;
 	if ($2 ne ":5") {
		next;
	};

	if($4 eq "logged"){
	}elsif ($4 ne "(00:00)"){
		push @logs, "$1 $3 $4 chandra";
	};
};

#Add aragog logs
foreach (`ssh -q schedule\@aragog.cat.pdx.edu \'last 1 2 3 4 5 6 7 8 9 10 | grep \"$date\" | grep -v wtmp\'`){
  /^(.+?)\s+.+?\s+.+?\s+.+?\s+.+?\s+.+?\s+(.+?)\s+.+?\s+(.+?)\s+(.+)\s/;
  if($3 eq "logged"){
    push @strays, "$1 $2 $3 aragog";
  }elsif ($4 ne "(00:00)"){
    push @logs, "$1 $2 $3 aragog";
  };
};

#Add windows logs
foreach("hapi","mut","kupo"){
  my @temp2=();
  foreach(`ssh schedule\@chandra.cs.pdx.edu \'grep "$windate" /u/schedule/logs/windows/*|grep -i $_\'`){
    /^(?:.+:)(\w+),(\w+).+?(?:\w{4})(?:\w{2})(?:\w{2})(\w{2})(\w{2}),/;
    push @temp2, "$1 $3:$4 $2";
  };
  @temp2 = sort @temp2;
  my $i=0;
  my $j=1;
  while ($i<@temp2){
    if($j==@temp2){
      push @strays, $temp2[$i];
      $i++;
      next();
    };
    $temp2[$i] =~ /^(\w+)/;
    my $m = $1;
    $temp2[$j] =~ /^(\w+)/;
    my $n = $1;
    if ($m ne $n){
      push @strays, $temp2[$i];
      $i++;
      $j++;
      next;
    };
    if ($temp2[$i]=~/" off"/){
      $i++;
      $j++;
      push @strays, $temp2[$i];
      next();
    }elsif ($temp2[$i]=~/" on"/&&$temp2[$j]=~/" on"/){
      $i++;
      $j++;
      push @strays, $temp2[$j];
      next;
    };
    $temp2[$i]=~/^(?:.+?)\s(.+)\s(?:.+)/;
    my $k=$1;
    $temp2[$j]=~/^(?:.+?)\s(.+)\s(?:.+)/;
    my $l=$1;
    push @logs, "$m $k $l $_";
    $i+=2;
    $j+=2;
  };
};

# Build hash of active cat's usernames and their id in the database...
# Should be type 1 (DOG) or type 2 (DROID) if they are active and subject to desk duties.
my %active_cats;
%active_cats = ();
# uname: id
my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",$user,$password) or die "Can't connect to database: $DBI::errstr\n";
my $sth_get_active_cats = $dbh->prepare('SELECT ns_cat_id, ns_cat_uname, ns_cat_type_id FROM ns_cat') or die "Couldn't prepare statement: " . $dbh->errstr;
$sth_get_active_cats->execute;
while (my @ns_cat_entry = $sth_get_active_cats->fetchrow_array()) {
	if ($ns_cat_entry[2] == 1 || $ns_cat_entry[2] == 2) {
		$active_cats{$ns_cat_entry[1]} = $ns_cat_entry[0];
	};
};
#my $key;
#foreach $key (sort keys (%active_cats)) {
#	print "$key: $active_cats{$key}\n";
#};

my $sth_add_log_entry = $dbh->prepare('INSERT INTO `ns_log_item` (ns_cat_id,ns_li_date,ns_li_ontime,ns_li_offtime,ns_li_machine) VALUES (?,?,?,?,?)') or die "Couldn't prepare statement: " . $dbh->errstr;
my $sth_check_if_exists = $dbh->prepare('SELECT COUNT(*) FROM `ns_log_item` WHERE ns_li_date=? AND ns_li_ontime=? AND ns_li_offtime=? AND ns_li_machine=?') or die "Couldn't prepare statement: " . $dbh->errstr;
# @logs format...
# username timeon timeoff machine
foreach(@logs){
	/(\w+).+?(\d\d:\d\d).+?(\d\d:\d\d).+?(\w+)$/;
	# Make sure this is a DOG or DROID by checking against the hash we made earlier.
	if(exists $active_cats{$1}) {
		$sth_check_if_exists->bind_param(1,$dbdate);
		$sth_check_if_exists->bind_param(2,$2);
		$sth_check_if_exists->bind_param(3,$3);
		$sth_check_if_exists->bind_param(4,$4);
		$sth_check_if_exists->execute;
		my $rows = $sth_check_if_exists->fetchrow_array();
		# Make sure this log entry hasn't already been recorded to the database.
		if($rows >= 1) {
			print "Log entry for $1 ($dbdate,$2,$3,$4) already exists in database. Skipping.\n";
		# If we passed the two checks, add the log item to the database.
		} else {
			print "$1 is active, adding log entry for $dbdate,$2,$3,$4.\n";
			$sth_add_log_entry->bind_param(1,$active_cats{$1});
			$sth_add_log_entry->bind_param(2,$dbdate);
			$sth_add_log_entry->bind_param(3,$2);
			$sth_add_log_entry->bind_param(4,$3);
			$sth_add_log_entry->bind_param(5,$4);
			$sth_add_log_entry->execute;
		};
	# If the user is not a DOG or DROID, don't do anything.
	} else {
		print "$1 not a DOG or DROID, skipping.\n";
	};
};
