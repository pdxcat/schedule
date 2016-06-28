#!/usr/bin/perl

# Licensed to the Computer Action Team (CAT) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The CAT licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

use strict;
use warnings;
use Date::Calc "Delta_DHMS";
use DBI;
use FindBin;
use POSIX;
use Getopt::Long;
use YAML qw(LoadFile);


# ns_assign_shift.pl
# Assigns shifts to a DOG for a given day of the week and hour or range of
# hours.

# Some configuration items
my $config   = LoadFile("$FindBin::Bin/../config.yaml");

my $db = $config->{'db'};
my $host = $config->{'host'};
my $user = $config->{'user'};
my $password = $config->{'password'};

my $dbh = DBI->connect ("DBI:mysql:database=$db:host=$host",$user,$password) or die "Can't connect to database: $DBI::errstr\n";

# Which types of CATs are eligible for desk duty?
my @dog_types = (2,1);

# Main body

# Commented keys are populated later in the program.
my %args = (
dog_name	=>	'',
dog_id		=>	0,
term_name	=>	'',
date_range	=>	'',
desk_name	=>	'DOGHaus', # Default to DOGHaus
desk_id		=>	0,
day_name	=>	'',
day_id		=>	0,
start_time	=>	{actual	=>	''},
end_time	=>	{actual	=>	''}
);

GetOptions (
	'd=s' => \$args{'dog_name'},
	't=s' => \$args{'term_name'},
	'r=s' => \$args{'date_range'},
	'l=s' => \$args{'desk_name'},
	'n=s' => \$args{'day_name'},
	's=s' => \$args{'start_time'}{'actual'},
	'e=s' => \$args{'end_time'}{'actual'}
);


# Set up start and end times for weekdays and weekends
my %hours = (
	weekday_start 	=> 	'08',
	weekday_end 	=>	'18',
	weekend_start	=>	'12',
	weekend_end		=>	'17',);


### Validate arguments ###

# For each possible argument, check for its presence and validate its value. If
# any is missing/unusable, display an error message and flip a variable to make
# the script terminate early.

my $die_early = 0;

# Ensure a CAT username has been specified. If so, verify that this CAT is
# active in the scheduling system and eligible for desk duty.
my $dogs_hash_ref;
if (!$args{'dog_name'}) {
	print "A valid dog name (using -d \"name\") must be specified.\n";
	$die_early = 1;
} else {
	$dogs_hash_ref = get_dogs(\@dog_types);
	$args{dog_id} = get_id_from_value($args{dog_name},$dogs_hash_ref);
	if ($args{dog_id} eq "no match") {
		print "No such dog \"$args{dog_name}\" eligible for desk duty found.\n";
		$die_early = 1;
	} else {
		print "$args{dog_name} has id $args{dog_id} and is eligible for desk duty.\n";
	};
};


# Check for either a valid term name, or valid date range. If we received
# neither or both, script should abort.

my $terms_hash_ref = get_terms();

# These variables will be populated with the start and end times to be used in
# the rest of the programe as $var{'yyyy-mm-dd','yyyy','mm','dd'}
my %start_date;
my %end_date;

if (!$args{'term_name'} && !$args{'date_range'} || $args{'term_name'} && $args{'date_range'}) {
	print "Either a term name (-t \"term year\") or date range (-r \"yyyy-mm-dd yyyy-mm-dd\") must be specified.\n";
	$die_early = 1;

} elsif ($args{'term_name'} && !$args{'date_range'}) {
	# Make sure a valid term has been specified, check against output of get_terms().
	my $term_id = get_id_from_value($args{term_name},$terms_hash_ref);
	if ($term_id eq "no match") {
		print "No such term \"$args{term_name}\" exists in the database.\n";
		$die_early = 1;
	} else {
		print "$args{term_name} has id $term_id.\n";

		# Get the details of the term we're working with
		my $sth_get_term_dates = $dbh->prepare('
		SELECT ns_term_startdate, ns_term_enddate
		FROM ns_term
		WHERE ns_term_id = ?')
		or die "Couldn't prepare statement: " . $dbh->errstr;
		$sth_get_term_dates->bind_param(1,$term_id);
		$sth_get_term_dates->execute;

		# Populate the part of the start_date and end_date hashes
		# Fetch the "long forms" from the database
		($start_date{'yyyy-mm-dd'},$end_date{'yyyy-mm-dd'})
			= $sth_get_term_dates->fetchrow_array;

		# Chunk out the long forms for later usage
		@start_date{'yyyy','mm','dd'}
			= ($start_date{'yyyy-mm-dd'}
			=~ m/(\d\d\d\d)-(\d\d)-(\d\d)/);
		@end_date{'yyyy','mm','dd'}
			= ($end_date{'yyyy-mm-dd'}
			=~ m/(\d\d\d\d)-(\d\d)-(\d\d)/);
	};

} elsif ($args{'date_range'} && !$args{'term_name'}) {
	if ($args{'date_range'} !~ m/\d{4}-\d\d-\d\d\s\d{4}-\d\d-\d\d/) {
		print "Invalid date range specified. (Use the format \"-r yyyy-mm-dd yyyy-mm-dd\").\n";
		$die_early = 1;
	} else {
		# Populate the part of the start_date and end_date hashes
		($start_date{'yyyy-mm-dd'},$end_date{'yyyy-mm-dd'})
			= $args{'date_range'} =~ m/(\d{4}-\d\d-\d\d)\s(\d{4}-\d\d-\d\d)/;

		# Chunk out the long forms for later usage
		@start_date{'yyyy','mm','dd'}
			= ($start_date{'yyyy-mm-dd'}
			=~ m/(\d\d\d\d)-(\d\d)-(\d\d)/);
		@end_date{'yyyy','mm','dd'}
			= ($end_date{'yyyy-mm-dd'}
			=~ m/(\d\d\d\d)-(\d\d)-(\d\d)/);
	};
};


# Make sure the day, start time, and end time make sense
# Check that the day, start time, and end time given are in a valid
# format and represent valid values of their type (the name of a day of
# the week, and an hour between 0000 and 2300 for the start and end
# times).
# Check that the day specified was not Sunday, get the numerical value
# for the name of the day provided.
if ($args{'day_name'} =~ m/\d/ && $args{'day_name'} > 0 && $args{'day_name'} < 8) {
	$args{'day_id'} = $args{'day_name'};
} elsif ($args{day_name} =~ m/monday/i) {
	$args{day_id} = 1;
} elsif ($args{day_name} =~ m/tuesday/i) {
	$args{day_id} = 2;
} elsif ($args{day_name} =~ m/wednesday/i) {
	$args{day_id} = 3;
} elsif ($args{day_name} =~ m/thursday/i) {
	$args{day_id} = 4;
} elsif ($args{day_name} =~ m/friday/i) {
	$args{day_id} = 5;
} elsif ($args{day_name} =~ m/saturday/i) {
	$args{day_id} = 6;
} elsif (!$args{day_name}) {
	print "A day of the week to schedule for must be specified (using -n \"day\" or -n [1-6].)\n";
	$die_early = 1;
} else {
	print "Invalid day specified ($args{day_name}).\n";
	$die_early = 1;
};

if (!$die_early) {
	print "Scheduling for $args{day_name} (id $args{day_id}).\n";
};


# Chunk out the given start and end times so we can work with them
# The binding operator creates a list of matches, so assignment of the result
# must be to a list.
@{$args{'start_time'}}{'hh','mm'} = $args{'start_time'}{'actual'} =~ /(\d\d)(\d\d)/;
@{$args{'end_time'}}{'hh','mm'} = $args{'end_time'}{'actual'} =~ /(\d\d)(\d\d)/;

# Delta_DHMS will return positive values for all four return values if
# the first date comes BEFORE the second date. It will return negative
# values if the first date comes AFTER the second date.

# Check that start time and end time are within business hours for the given day of the week
# Check that the end time is after the start time
if (!$args{'start_time'}{'actual'} || !$args{'end_time'}{'actual'}) {
	print "Start and end times must be specified (using -s hhmm for start, -e hhmm for end).\n";
	$die_early = 1;
} elsif ($args{start_time}{hh} >= $args{end_time}{hh}) {
	print "Start time must be after end time!\n";
	$die_early = 1;
} elsif ($args{day_id} >= 1 && $args{day_id} <= 5) {
	# Check against weekday start and end times
	my %result;
	@result{'dd','hh','mm','ss'}
		= Date::Calc::Delta_DHMS(2011,5,23,@{$args{'start_time'}}{'hh','mm'},0,
		2011,5,23,$hours{'weekday_start'},0,0);
	if ($result{'hh'} > 0) {
		print "Specified start time is too early.\n";
		$die_early = 1;
	};
	@result{'dd','hh','mm','ss'}
		= Date::Calc::Delta_DHMS(2011,5,23,@{$args{'start_time'}}{'hh','mm'},0,
		2011,5,23,$hours{'weekday_end'},0,0);
	if ($result{'hh'} < 1 ) {
		print "Specified start time is too late.\n";
		$die_early = 1;
	};
	@result{'dd','hh','mm','ss'}
		= Date::Calc::Delta_DHMS(2011,5,23,@{$args{'end_time'}}{'hh','mm'},0,
		2011,5,23,$hours{'weekday_end'},0,0);
	if ($result{'hh'} < 0) {
		print "Specified end time is too late!\n";
		$die_early = 1;
	};
} elsif ($args{day_id} == 6) {
	# Check against weekend start and end times
	my %result;
	@result{'dd','hh','mm','ss'}
		= Date::Calc::Delta_DHMS(2011,5,23,@{$args{'start_time'}}{'hh','mm'},0,
		2011,5,23,$hours{'weekend_start'},0,0);
	if ($result{'hh'} > 0) {
		print "Specified start time is too early.\n";
		$die_early = 1;
	};
	@result{'dd','hh','mm','ss'}
		= Date::Calc::Delta_DHMS(2011,5,23,@{$args{'start_time'}}{'hh','mm'},0,
		2011,5,23,$hours{'weekend_end'},0,0);
	if ($result{'hh'} < 1 ) {
		print "Specified start time is too late.\n";
		$die_early = 1;
	};
	@result{'dd','hh','mm','ss'}
		= Date::Calc::Delta_DHMS(2011,5,23,@{$args{'end_time'}}{'hh','mm'},0,
		2011,5,23,$hours{'weekend_end'},0,0);
	if ($result{'hh'} < 0) {
		print "Specified end time is too late!\n";
		$die_early = 1;
	};
} else {
	# If we got here something is off
	print "Times could not be verified due to invalid day provided.\n";
	$die_early = 1;
};

if (!$die_early) {
	print "The given start and end times ($args{'start_time'}{'actual'} and $args{'end_time'}{'actual'}) are within acceptable ranges.\n";
};


# Make sure a valid desk has been specified, check against output of get_desks()
my $desks_hash_ref = get_desks();
$args{desk_id} = get_id_from_value($args{desk_name},$desks_hash_ref);
if ($args{desk_id} eq "no match") {
	print "No such desk \"$args{desk_name}\" exists in the database.\n";
	$die_early = 1;
} else {
	print "$args{desk_name} has id $args{desk_id} (an alternate desk may be specified using -l deskname).\n";
};


# If any of the arguments were bogus, die.
if ($die_early) {
	print "Aborting.\n";
	exit;
} else {
	print "Received valid args, proceeding.\n";
};


### Main Loop ###

# If the first day of the term is after today, use it as the start date
# for the assignment operation. If it is after today use today's date
# as the first day.


# Delta_Days(yyyy,mm,dd,yyyy,mm,dd) returns positive if date 1 is
# BEFORE date 2, negative if date 1 is AFTER date 2. The return value
# is the difference between the two dates measured in days.

my %current_date = (
	'yyyy'	=> $start_date{'yyyy'},
	'mm'	=> $start_date{'mm'},
	'dd'	=> $start_date{'dd'}, );
# Enter loop to step through each day of the term
while (Date::Calc::Delta_Days(@current_date{'yyyy','mm','dd'},@end_date{'yyyy','mm','dd'})
	>= 0) {
	$current_date{'yyyy-mm-dd'} = sprintf("%4d-%02d-%02d",@current_date{'yyyy','mm','dd'});
	# If a day matches the day to be assigned...
	if (Date::Calc::Day_of_Week(@current_date{'yyyy','mm','dd'}) == $args{'day_id'}) {
		my $current_hour = $args{'start_time'}{'hh'};
		# Enter loop to step through the time range in one hour increments
		while ($current_hour < $args{'end_time'}{'hh'}) {
			# For each hour...
			# Try to grab a shift entry for the specified
			# date and time, if one doesn't exist move on.
			my $shift_id
				= get_shift_id(
				$current_date{'yyyy-mm-dd'},
				$current_hour,
				sprintf("%02d",$current_hour + 1));
			print "Got shift ID: $shift_id\n";
			if ($shift_id != 0) {
				# If a shift entry exists...
				# Check and see if an "active"
				# assignment already exists for the
				# specified CAT using check_shift()
				if (check_shift(
					$args{'dog_id'},
					$shift_id,
					$args{'desk_id'})) {
					# If one does, mention this and step to the next hour
					print "Active shift assignment already exists for $current_date{'yyyy-mm-dd'} starting at $current_hour, skipping.\n";
				} else {
					# If one doesn't, call new_assignment()
					# and create a new shift assignment
					new_assignment(
						$args{'dog_id'},
						$shift_id,
						$args{'desk_id'});
				};
			} else {
				print "No shift for " . $current_date{'yyyy-mm-dd'} . " at " . sprintf("%02d",$current_hour) . " exists.\n";
			};
			$current_hour = sprintf("%02d",$current_hour + 1);
		};
	} else {
		# If the day doesn't match the day to be assigned step to the next day
	};
	# ($year,$month,$day) = Add_Delta_Days($year,$month,$day, $Dd);
	@current_date{'yyyy','mm','dd'}
		= Date::Calc::Add_Delta_Days(@current_date{'yyyy','mm','dd'},1);
};

### Subroutines ###

# Gets the ID of the shift for a given date and time, if one exists.
# Args: date (yyyy-mm-dd), shift start (hh), shift end (hh)
sub get_shift_id {

	if (@_ != 3) {
		print "get_shift_id() was passed an invalid number of arguments! (" . @_ . ").\n";
	};
	my %gsi_args;
	@gsi_args{'date','start','end'} = @_;
	$gsi_args{'start'} = sprintf("%02d:00:00",$gsi_args{'start'});
	$gsi_args{'end'} = sprintf("%02d:00:00",$gsi_args{'end'});

	# Query to match *the* (there should only be one!) shift entry for the
	# given date and start and end times.
	my $sth_gsi = $dbh->prepare('
		SELECT ns_shift_id
		FROM ns_shift
		WHERE ns_shift_date = ?
		AND ns_shift_start_time = ?
		AND ns_shift_end_time = ?
		')
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_gsi->bind_param(1,$gsi_args{'date'});
	$sth_gsi->bind_param(2,$gsi_args{'start'});
	$sth_gsi->bind_param(3,$gsi_args{'end'});
	$sth_gsi->execute;

	my @shift_ids;
	while (my @gsi_result = $sth_gsi->fetchrow_array()) {
		if (@gsi_result == 1) {
			push(@shift_ids,$gsi_result[0]);
		} elsif (@gsi_result > 1) {
			print "Got too many columns from database query in get_shift_id()\n";
		};
	};

	# If we got more than one matching shift entry something is really
	# wrong in the database and needs to be fixed before it is messed with
	# any further.
	if (@shift_ids > 1) {
		print "Found more than one shift for $gsi_args{'date'} at $gsi_args{'start'}: \n";
		foreach my $id (@shift_ids) {
			print "$id\n";
		};
		exit;

	# No entries probably just means that shifts for the term that
	# assignment is being attempted for have not been generated. Maybe
	# should change this to exit the program since its likely there won't
	# be any shift entries for a given range if the first one checked for
	# doesn't exist, barring any terrible misuse of the system. Gonna leave
	# it be for now.
	} elsif (@shift_ids == 0) {
		print "No shifts found for $gsi_args{'date'} at $gsi_args{'start'}. \n";
		return 0;
	};

	return $shift_ids[0];
};

# Create new assignment entry
# Args: 'dog_id', date, start time, end time, 'desk_id'
sub new_assignment {
	if (@_ != 3) {
		print "new_assignment() was passed an invalid number of arguments! (" . @_ . ").\n";
		exit;
	};
	my %na_args;
	@na_args{'dog_id','shift_id','desk_id'} = @_;

	my $sth_add_assignment = $dbh->prepare('
		INSERT INTO `ns_shift_assigned` (ns_cat_id,ns_shift_id,ns_desk_id,ns_sa_assignedtime)
		VALUES (?,?,?,?)
		') or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_add_assignment->bind_param(1,$na_args{'dog_id'});
	$sth_add_assignment->bind_param(2,$na_args{'shift_id'});
	$sth_add_assignment->bind_param(3,$na_args{'desk_id'});
	my $current_timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
	#print $current_timestamp . "\n";
	$sth_add_assignment->bind_param(4,$current_timestamp);
	$sth_add_assignment->execute;
	print "Assignment successful for DOG $na_args{'dog_id'}, shift $na_args{'shift_id'}.\n";
};

# Determine if an "active" shift assignment for a given shift exists for a Cat
# "Active" shift assignments are those for which the is not a corresponding entry in ns_shift_dropped
# Args: 'dog_id', shift_id, 'desk_id'

sub check_shift {

	if (@_ != 3) {
		print "check_shift() was passed an invalid number of arguments! (" . @_ . ").\n";
		exit;
	};
	my %cs_args;
	@cs_args{'dog_id','shift_id','desk_id'} = @_;

	# Get entries from ns_shift_assigned which match the criteria for
	# active assignment entries for the given Cat, desk, and shift.
	my $sth_cs = $dbh->prepare('
	SELECT sa.ns_sa_id
	FROM ns_shift_assigned as sa
	WHERE sa.ns_shift_id = ?
	AND sa.ns_cat_id = ?
	AND sa.ns_desk_id = ?
	AND NOT EXISTS
		(SELECT *
		FROM ns_shift_dropped as sd
		WHERE sd.ns_sa_id = sa.ns_sa_id)')
	or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_cs->bind_param(1,$cs_args{'shift_id'});
	$sth_cs->bind_param(2,$cs_args{'dog_id'});
	$sth_cs->bind_param(3,$cs_args{'desk_id'});
	$sth_cs->execute;

	# Dump active assignment IDs into an array.
	my @assignment_ids;
	while (my @cs_result = $sth_cs->fetchrow_array()) {
		if (@cs_result == 1) {
			push(@assignment_ids,$cs_result[0]);
		} elsif (@cs_result > 1) {
			print "Got too many columns from database query in check_shift()\n";
			exit;
		};
	};

	# If we got more than one match something is really off in the DB and
	# needs to be checked out before anything else happens.
	if (@assignment_ids > 1) {
		print "Found more than one active assignment for shift ID: $cs_args{'shift_id'}!\nAssignment IDs are: \n";
		foreach my $id (@assignment_ids) {
			print "$id\n";
		};
		exit;

	# If we found an active assignment return its id.
	} elsif (@assignment_ids == 1) {
		print "Found active assignment for shift ID: $cs_args{'shift_id'}. \n";
		print "Assignment ID: " . $assignment_ids[0] . "\n";
		return $assignment_ids[0];

	# No active assignments means we are clear to create a new assignment entry.
	} elsif (@assignment_ids == 0) {
		print "No active assignment found for shift ID: $cs_args{'shift_id'}. \n";
		return 0;
	};
};

# Iterates through each entry of a hash to see if the given scalar exists as a
# value for any hash key and returns the key corresponding to that value if it
# exists. This will return the first key found, so if there may be multiple
# instances of the value being looked for this is not the subroutine to use.
# Args: Value to look for (scalar), hash reference to iterate through
sub get_id_from_value {
	my $search_value = $_[0];
	my $hash_ref = $_[1];
	my $return_id;
	foreach my $id (keys(%{$hash_ref})) {
		# Case insensitive!
		if ($hash_ref->{$id} =~ m/^$search_value$/i) {
			$return_id = $id;
			last;
		};
	};
	if (defined $return_id) {
		return $return_id;
	} else {
		return "no match";
	};
};

# Get all possible stations a DOG could be posted at, keyed to their id in ns_desk
# Args: None
#
# Output hash format:
# desk_id => desk_name
#
sub get_desks {
	my $sth_get_desks = $dbh->prepare('
	SELECT ns_desk_id, ns_desk_shortname
	FROM ns_desk')
	or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_get_desks->execute;
	my %return_hash;
	while (my @ns_desk_entry = $sth_get_desks->fetchrow_array()) {
		$return_hash{$ns_desk_entry[0]} = $ns_desk_entry[1];
	};
	return \%return_hash;
};

# Generate a hash of all current DOGs, keyed to their id in ns_cat
# Args: Types of CATzen to return (@dog_types) (optional)
#
# Output hash format:
# cat_id => cat_uname
#
sub get_dogs {
	# This sub might be called with a reference to an array containing the DOG
	# types to fetch, if it is we need to handle that
	if (defined $_[0]) {
		my $types_ref = $_[0];
		# Since we're using this in a SQL query it needs to be formatted
		my $types_db_list;
		for (my $i = 0; $i < @$types_ref; $i++) {
			if ($i == 0) {
				$types_db_list = $types_ref->[$i];
			} else {
				$types_db_list .= "," . $types_ref->[$i];
			};
		};
		my $get_dogs_query = "SELECT ns_cat_id, ns_cat_uname FROM ns_cat WHERE ns_cat_type_id IN ($types_db_list)";
		my $sth_get_dogs = $dbh->prepare($get_dogs_query)
		or die "Couldn't prepare statement: " . $dbh->errstr;
		$sth_get_dogs->execute;
		my %return_hash;
		while (my @ns_cat_entry = $sth_get_dogs->fetchrow_array()) {
			$return_hash{$ns_cat_entry[0]} = $ns_cat_entry[1];
		};
		return \%return_hash;
	# If we don't get a list of CAT types to grab just get everyone
	} else {
		my $sth_get_dogs = $dbh->prepare('
		SELECT ns_cat_id, ns_cat_uname
		FROM ns_cat')
		or die "Couldn't prepare statement: " . $dbh->errstr;
		$sth_get_dogs->execute;
		my %return_hash;
		while (my @ns_cat_entry = $sth_get_dogs->fetchrow_array()) {
			$return_hash{$ns_cat_entry[0]} = $ns_cat_entry[1];
		};
		return \%return_hash;
	};
};

# Get a hash of term names keyed to their id
# Args: None
#
# Output hash format:
# term_id => term_name
#
sub get_terms {
	my $sth_get_terms = $dbh->prepare('
	SELECT ns_term_id, ns_term_name
	FROM ns_term')
	or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_get_terms->execute;
	my %return_hash;
	while (my @ns_term_entry = $sth_get_terms->fetchrow_array()) {
		$return_hash{$ns_term_entry[0]} = $ns_term_entry[1];
	};
	return \%return_hash;
};


