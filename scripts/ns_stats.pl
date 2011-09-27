#!/opt/csw/bin/perl

use strict;
use warnings;
use Getopt::Long;
use POSIX;
use DBI;
use Date::Calc;

# ns_stats.pl
# Perform analysis of schedule shifts and log entries to determine who is at
# their schedule shifts and record the results.


# Set up the date to use. If we get a valid -date argument use that, otherwise
# default to the current date.

# Arguments should be a date in the format yyyy-mm-dd

#  0    1    2     3     4    5     6     7     8
# ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my @date = localtime(time);
# %Y is replaced by the year with century as a decimal number.
# %m is replaced by the month as a decimal number [01,12].
# %d is replaced by the day of the month as a decimal number [01,31].
my $datestr = strftime("%Y-%m-%d",@date);
my $datearg = "";
my $args = GetOptions(
	'date=s' => \$datearg
	);

if ($datearg =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
	$datestr = sprintf("%4d-%02d-%02d",$1,$2,$3);
};


my $db = "schedule";
my $host = "db.cecs.pdx.edu";
my $user = "schedule";
my $password = "jm)n3Ffz6m";
my $dbh = DBI->connect ("DBI:mysql:database=$db:host=$host",$user,$password) or die "Can't connect to database: $DBI::errstr\n";

# Fetch active assignments for the given day.
my $shifts_r = get_shifts_for_day($datestr);

# Collect all log entries for the given day. 
# Store the cat id, on and off time, and machine name for these shifts.
my $logs_r = get_logs_for_day($datestr);

# Sort the log entries by start time in ascending order
#sort_log_entries(\@log_entries,'ns_shift_start_time');

# For a given shift...
foreach my $shift (@{$shifts_r}) {

	my $shift_id = $shift->{'ns_shift_id'};
	my $shift_start = $shift->{'ns_shift_start_time'}; 
	my $shift_end = $shift->{'ns_shift_end_time'};

	print $shift_id . " " . $datestr . ": " . $shift_start . " - " . $shift_end . "\n";

	# Collect all assignments for the shift, store shift ID, desk ID, and
	# cat ID for each assignment.


	# Iterate over the log entries
#	foreach my $log_entry (@log_entries) {
		# Ranges will be stored like...
		# {cat_id,location,[ranges]}
		# ranges[[range1start(hh:mm),range1end],[range2start,range2end]..etc.]

		# Designate the start time of the first entry as the beginning of the
		# range, or if the log entry's start time is before the 
		# shift's start time then use the shift's start time as the beginning
		# of the range. Designate the end of the range as the end time of the 
		# log entry if it is before the end time of the shift. If it is equal
		# to or after the end time of the shift, use the end time of the shift
		# as the end of the range.
		
		# For each entry thereafter if the start time of the log entry is 
		# before or equal to the end of the current range, set the end of the
		# current range to be the end time of the log entry if it is before
		# the end time of the shift, or if it is after the end of the shift use
		# the end time of the shift.

		# If the start time of the log entry is after the end time of the
		# current range, store the current range and start a new range with its
		# start as the start time of the current entry. Set the end time of
		# this new range to be the end time of the log entry if the end time is
		# before the end time of the shift, or if it is after the end time of
		# the shift use the end time of the shift as the end of the range.


		# If the end time of the current range is equal to the end time of the
		# shift store the range and break without iterating over any more log entries.

		
		# If the log entry processed on this iteration is the last of the log
		# entries, then store the current range and exit the loop.
#	};

	# Calculate how many minutes are in the shift being checked against, store this
	# value.

	# Determine the coverage of the stored ranges, in minutes, store this value.

	# Compare the actual coverage against that required by the shift. 

	# Rules:
	# -10 minute "grace" period. 
	# -If more than 10 minutes of a shift are missed, count the whole shift as 
	#  missed.

	# Store the result of this comparison
};


# Subroutines

# Get assigned shifts for a given day
# Args: string date (yyyy-mm-dd)
sub get_shifts_for_day {
	my $date = $_[0];

	# The data we need are the shift id, shift start time, and shift end 
	# time of all shifts falling on $date. The table ns_shift contains 
	# these in the ns_shift_id, ns_shift_start_time, and ns_shift_end_time
	# columns.
	my $sth_gsd = $dbh->prepare ('
		SELECT ns_shift_id, ns_shift_start_time, ns_shift_end_time
		FROM ns_shift
		WHERE ns_shift_date = ?
		')
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_gsd->bind_param (1,$date);
	$sth_gsd->execute or die "Couldn't execute statement: " . $sth_gsd->errstr;
	
	# From CPAN Perl DBI documentation:

	# An alternative to fetchrow_arrayref. Fetches the next row of data and 
	# returns it as a reference to a hash containing field name and field 
	# value pairs. Null fields are returned as undef values in the hash.

	# The keys of the hash are the same names returned by $sth->{$name}. If
	# more than one field has the same name, there will only be one entry in the
	# returned hash for those fields, so statements like "select foo, foo from bar"
	# will return only a single key from fetchrow_hashref. In these cases use column
	# aliases or fetchrow_arrayref. Note that it is the database server (and not the
	# DBD implementation) which provides the name for fields containing functions
	# like "count(*)" or "max(c_foo)" and they may clash with existing column names
	# (most databases don't care about duplicate column names in a result-set). If
	# you want these to return as unique names that are the same across databases,
	# use aliases, as in "select count(*) as cnt" or "select max(c_foo) mx_foo, ..."
	# depending on the syntax your database supports.

	my @shift_data;
	while (my $result_r = $sth_gsd->fetchrow_hashref()) {
		push (@shift_data,$result_r);
	};

	return \@shift_data;
};


# Get log entries for a given day
# Args: string date 
sub get_logs_for_day {
	my $gle_date = $_[0];

	my $sth_gle = $dbh->prepare ('
		SELECT ns_cat_id, ns_li_ontime, ns_li_offtime, ns_li_machine 
		FROM ns_log_item
		WHERE ns_li_date = ?
		')
		or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth_gle->bind_param(1,$gle_date);
	$sth_gle->execute or die "Couldn't execute statement: " . $sth_gle->errstr;
	
	my @log_entries;
	while (my $result_r = $sth_gle->fetchrow_hashref()) {
		push (@log_entries,$result_r);
	};
	
	return \@log_entries;
};


sub sort_log_entries {
	my $to_sort_r = $_[0];
	my $sort_column = $_[1];
};
