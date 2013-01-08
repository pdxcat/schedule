#! /opt/csw/bin/perl
use strict;
use warnings;
use Date::Calc "Delta_DHMS";
use Date::Calc "Add_Delta_DHMS";
use Date::Calc "Delta_Days";
use Date::Calc "Add_Delta_Days";
use Date::Calc "Day_of_Week";
use DBI;
use POSIX;

# ns_shift_gen.pl
# Generates entries for ns_shift.

# Functionality
# -Generate shifts in one hour blocks, only on Monday through Friday, 8-6, Saturday 12-6.
# -Skip holidays in ns_holiday.
# -Should be smart enough to not need a specific day to start on, unlike current script which requires a monday.

# Arguments to take
# -Start date and end date to generate shifts between, or a term name.

# Main loop
# -Check arguments, make sure we get two dates in yyyy-mm-dd format and put
#  these into $start_date and $end_date
# -Call getholidays() and build a list of dates to ignore for purposes of populating ns_shift.
# -Step through each date in between the start and end dates and generate shifts appropriately based on the day of the week.

# Subroutines
# -Build list of holidays from entries in ns_holiday
# -Loop to go through each valid hour for a day and create an appropriate number of shifts for each of hours based on the number of seats we have.
# -Insert record into ns_shift

my $db = "schedule";
my $host = "db.cecs.pdx.edu";
my $user = "schedule";
my $password = "jm)n3Ffz6m";
my $dbh = DBI->connect ("DBI:mysql:database=$db:host=$host",$user,$password) or die "Can't connect to database: $DBI::errstr\n";
my @start_date;		# Date to start at, taken from arguments in YYYY-MM-DD format, then broken up into this array as three pieces YYYY, MM, DD.
my @end_date;		# Date to end at, as above.
my %holidays;		# Hash of holidays, built from ns_holiday entries. holiday date => holiday name.
%holidays = ();

# Determine whether we have valid arguments. If so, call buildshifts() and start generating shifts.
if (!defined @ARGV) {
	print "No arguments specified! Please use the -d option to specify a start and end date, or the -t option to specify a term by name.\n";
	exit;
}elsif ($ARGV[0] eq "-t") {
	# -t option specifies a term from the ns_term table by name.
	# Argument should look like '-t Fall 2010'
	if (@ARGV == 3 && $ARGV[1] =~ /[A-Z]\w*/ && $ARGV[2] =~ /\d\d\d\d/) {
		my $term_name = "$ARGV[1] $ARGV[2]";
		my $sth_get_terms = $dbh->prepare(
			"SELECT ns_term_name, ns_term_startdate, ns_term_enddate
			FROM ns_term
			WHERE ns_term_name = ?")
			or die "Couldn't prepare statement: " . $dbh->errstr;
		$sth_get_terms->bind_param(1,$term_name);
		$sth_get_terms->execute;
		# @term info should be term name, term start date, term end date.
		my @term_info = $sth_get_terms->fetchrow_array();
		if (!@term_info) {
			print "There is no term called $term_name in the database!\n";
			exit;
		};
		print "Got term $term_info[0] starting $term_info[1], ending $term_info[2].\n";
		print "-----\n";
		@start_date = ($term_info[1] =~ /(\d\d\d\d)-(\d\d)-(\d\d)/);
		@end_date = ($term_info[2] =~ /(\d\d\d\d)-(\d\d)-(\d\d)/);
		buildshifts();
	}else{
		print "Invalid argument! Should look like -t Summer 1987\n";
		exit;
	};
}elsif ($ARGV[0] eq "-d") {
	# -d option should take a start and end date in YYYY-MM-DD format.
	# Argument should look like '-d 2010-01-10 2010-02-01'
	if (@ARGV == 3 && $ARGV[1] && $ARGV[2] =~ /(\d\d\d\d)-(\d\d)-(\d\d)/) {
		@start_date = ($ARGV[1] =~ /(\d\d\d\d)-(\d\d)-(\d\d)/);
		@end_date = ($ARGV[2] =~ /(\d\d\d\d)-(\d\d)-(\d\d)/);
		buildshifts();
	}else {
		print "Invalid argument! Should look like -d YYYY-MM-DD YYYY-MM-DD\n";
		exit;
	};
}else{
	print "Invalid argument! Please use the -d option to specific a start and end date, or the -t option to specify a term by name.\n";
	exit;
};

# Main subroutine of the script, started if it receives valid arguments from the user. Steps through each day between the start and end dates supplied and generates shifts for those days.
sub buildshifts {
	getholidays();

	# Set these times to the first and last *START* times you want shifts to have.
	# They were set wrong before and shifts were being made for 6-7 PM and 5-6 PM
	# on weekdays and weekends respectively -_- 10/21/2011
	my %wd_hours = ('start', 8, 'end', 17);
	my %we_hours = ('start', 12, 'end', 16);
	my $seats = 1;
	# yyyy mm dd
	my @c_date  = ($start_date[0],$start_date[1],$start_date[2]);
	# hh mm ss
	my @c_time = (0,0,0);
	my $db_date = sprintf("%4d-%02d-%02d",@c_date[0..2]);

	# Test the difference between the current date and the end date, run until they are the same.
	for (my $d_dd = 0;
	    $d_dd != -1;
	    $d_dd = Date::Calc::Delta_Days(@c_date,@end_date))
	    {
		if (exists $holidays{$db_date}) {
			print "$c_date[1]-$c_date[2]-$c_date[0] is $holidays{$db_date}. Skipping.\n";
		} elsif (Date::Calc::Day_of_Week(@c_date) == 7) {
			print "$c_date[1]-$c_date[2]-$c_date[0] is a Sunday, skipping.\n";
		} elsif (Date::Calc::Day_of_Week(@c_date) == 6) {
			print "$c_date[1]-$c_date[2]-$c_date[0] is a Saturday.\n";
			for ($c_time[0] = $we_hours{'start'};
			    $c_time[0] <= $we_hours{'end'};
			    (@c_date[0..2],@c_time[0..2])
			    = Date::Calc::Add_Delta_DHMS(@c_date,@c_time,0,1,0,0)) {
			    hourloop(@c_date,@c_time,$seats);
			};
		} else {
			print "$c_date[1]-$c_date[2]-$c_date[0] is a weekday.\n";
			for ($c_time[0] = $wd_hours{'start'};
			    $c_time[0] <= $wd_hours{'end'};
			    (@c_date[0..2],@c_time[0..2])
			    = Date::Calc::Add_Delta_DHMS(@c_date,@c_time,0,1,0,0)) {
			    hourloop(@c_date,@c_time,$seats);
			};
		};
		(@c_date[0..2]) = Date::Calc::Add_Delta_Days(@c_date, 1);
		$db_date = sprintf("%4d-%02d-%02d",@c_date[0..2]);
	};
};


# Takes a date, time, and number of seats available, generates a shift entry for each available seat.
sub hourloop {
    my %hl_args = (
    year => $_[0],
    month => $_[1],
    day => $_[2],
    hour => $_[3],
    minute => $_[4],
    second => $_[5],
    seats => $_[6], );
    my $hl_db_date = sprintf("%4d-%02d-%02d",@hl_args{'year','month','day'});
    my $hl_db_time = sprintf("%02d:%02d:%02d",@hl_args{'hour','minute','second'});
    my $hl_db_end_time = sprintf("%02d:%02d:%02d",$hl_args{'hour'} + 1,@hl_args{'minute','second'});
    if (checkdate($hl_db_date,$hl_db_time) eq "noshift") {
	# If checkdate() returns 0 it means there are no shifts matching the given date + time and it is okay to proceed with generating the shifts.
	for (my $c_seat = 1; $c_seat <= $hl_args{'seats'}; $c_seat++) {
	    addrecord($hl_db_date,$hl_db_time,$hl_db_end_time);
	};
    } elsif (checkdate($hl_db_date,$hl_db_time) eq "shift") {
	# If checkdate() returns 1 it means at least 1 shift matching the given date + time exists and shift generation should be aborted.
	print "A shift or shifts already exist for $hl_db_date at $hl_db_time. Skipping.\n";
    } else {
	# If one of the above conditions wasn't met, something broke.
	print "Something odd has happened in hourloop() or checkdate()!\n";
	exit;
    };
};


# Add a shift record to the ns_shift table. Takes a date, start time, and end time as arguments.
sub addrecord {
	my %ar_args = (
	date => $_[0],
	start_time => $_[1],
	end_time => $_[2], );
	my $sth_add_shift = $dbh->prepare('INSERT INTO `ns_shift` (ns_shift_date,ns_shift_start_time,ns_shift_end_time) VALUES (?,?,?)') or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_add_shift->bind_param(1,$ar_args{'date'});
	$sth_add_shift->bind_param(2,$ar_args{'start_time'});
	$sth_add_shift->bind_param(3,$ar_args{'end_time'});
	$sth_add_shift->execute;
	print "Added shift with start time $_[1] and end time $_[2] on $_[0].\n";
};

# Determine if any shifts exist for the given date. Takes a date and time in database formatted form as arguments.
sub checkdate {
    my $cd_db_date = $_[0];
    my $cd_db_time = $_[1];
    my $sth_get_shifts = $dbh->prepare('SELECT COUNT(*) FROM `ns_shift` WHERE ns_shift_date = ? AND ns_shift_start_time = ?') or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth_get_shifts->bind_param(1,$cd_db_date);
    $sth_get_shifts->bind_param(2,$cd_db_time);
    $sth_get_shifts->execute;
    my $cd_count = $sth_get_shifts->fetchrow_array();
    if ($cd_count == 0) {
	return "noshift";
    } elsif ($cd_count >= 1) {
	return "shift";
    } else {
	return "error";
    };
};

# Build the hash of holidays. Uses the holiday date as its key.
sub getholidays {
	my $sth_get_holidays = $dbh->prepare('SELECT ns_holiday_name, ns_holiday_date, ns_holiday_excused FROM ns_holiday') or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_get_holidays->execute;
	while (my @ns_holiday_entry = $sth_get_holidays->fetchrow_array()) {
		if ($ns_holiday_entry[2] == 1) {
			$holidays{$ns_holiday_entry[1]} = $ns_holiday_entry[0];
		 	print "Got holiday $holidays{$ns_holiday_entry[1]} on $ns_holiday_entry[1]\n";
		};
	};
	print "-----\n";
};
