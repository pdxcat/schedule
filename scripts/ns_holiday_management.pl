#! /opt/csw/bin/perl

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
use DBI;

# ns_holiday_management.pl
# View, add, edit, and remove holidays from the schedule database.

my $db = "yourdatabasehere";
my $host = "yourserverhere.example.com";
my $user = "yournamehere";
my $password = "yourpasswordhere";
my $dbh = DBI->connect ("DBI:mysql:database=$db:host=$host",$user,$password) or die "Can't connect to database: $DBI::errstr\n";

# Check arguments. Valid ones are:
# -l				Lists holidays currently in the database
# -n 		 	 	Create a new entry in the database
# -d name			Delete an entry from the database

my $invalid_args_message = "Invalid argument. Use one of the following:
-l                            Lists holidays currently in the database
-n name date		      Create a new entry in the database
-d name                       Delete an entry from the database\n";

if (!defined $ARGV[0]) {
	print "No arguments given!\n";
# Option for listing all holiday entries
} elsif ($ARGV[0] eq "-l") {
	ho_list();
# Option to create a new holiday entry
} elsif ($ARGV[0] eq "-n") {
	my %args;
	my $namestring;
	for my $i (1 .. $#ARGV) {
		# If the first argument after -n is a date the user screwed up
		if ($i == 1 && $ARGV[$i] =~ /^\d{4}-\d{2}-\d{2}$/) {
			print $invalid_args_message;
			exit;
		} elsif ($i == 1 && $ARGV[$i] =~ /\w*/) {
			$namestring = $ARGV[$i];
		} elsif ($ARGV[$i] =~ /^\d{4}-\d{2}-\d{2}$/) {
			$args{'date'} = $ARGV[$i];
			last;
		} elsif ($ARGV[$i] =~ /\w*/) {
			$namestring .= " $ARGV[$i]";
		} else {
			print $invalid_args_message;
			exit;
		};
	};
	$args{'name'} = $namestring;
	if (defined $args{'name'} && defined $args{'date'} && $args{'name'} ne "") {
		ho_add(\%args);
	} else {
		print $invalid_args_message;
		exit;
	};
# Option to delete a holiday entry
} elsif ($ARGV[0] eq "-d") {
	if ($ARGV[1] =~ /^\d{4}-\d{2}-\d{2}$/) {
		my %args = (
		'date' => $ARGV[1]);
		ho_del_date(\%args);
	} else {
		my $namestring;
		for my $i (1 .. $#ARGV) {
			if ($i == 1) {
				$namestring = $ARGV[$i];
			} else {
				$namestring .= " $ARGV[$i]";
			};
		};
		my %args = (
		'name' => $namestring);
		ho_del_name(\%args);
	};
# Die if any other option was indicated
} else {
	print $invalid_args_message;
};

# Subroutines

# List holidays in the database
# Args: none
sub ho_list {
	my $ho_ref = ho_get();
	foreach my $id ( keys(%{$ho_ref}) ) {
		print "$ho_ref->{$id}->{'ns_holiday_name'} on $ho_ref->{$id}->{'ns_holiday_date'}.\n";
	};
};

# Add a holiday entry to the database
# Args: holiday name, holiday start date, holiday end date
sub ho_add {
	# Reference passed should have 'name', 'date'.
	my $args_ref = $_[0];
	my $ho_ref = ho_get();
	# Search through the existing holidays to make sure there are no
	# collisions with the holiday to be added.
	foreach my $id (keys(%{$ho_ref})) {
		if (($ho_ref->{$id}->{'ns_holiday_name'}
		eq $args_ref->{'name'}
		&& $ho_ref->{$id}->{'ns_holiday_date'}
		eq $args_ref->{'date'})
		|| $ho_ref->{$id}->{'ns_holiday_date'}
		eq $args_ref->{'date'}) {
			print "Collision detected!\n";
			exit;
		};
	};
	# If there aren't any collisions with existing entries, add a new one
	# with the specified attributes.
	my $sth_add_ho = $dbh->prepare(
	'INSERT INTO ns_holiday (ns_holiday_name, ns_holiday_date)
	VALUES (?, ?)') or die "Couldn't prepare statement: $dbh->errstr \n";
	$sth_add_ho->bind_param(1, $args_ref->{'name'});
	$sth_add_ho->bind_param(2, $args_ref->{'date'});
	my $return = $sth_add_ho->execute;
	# Query should affect 1 row, anything else is odd...
	if (!defined $return) {
		print "Unable to execute addition query: $dbh->errstr \n";
	} elsif ($return eq 1) {
		print "Added new holiday entry for $args_ref->{'name'}\n";
	} else {
		print "Something odd happened. Addition query returned: $return\n";
	};
};

# Delete a holiday entry from the database by name
# Args: holiday name
sub ho_del_name {
	# Reference passed should have 'name'.
	my $args_ref = $_[0];
	my $ho_ref = ho_get();
	my $sth_del_ho = $dbh->prepare(
	'DELETE FROM ns_holiday WHERE ns_holiday_name = ?');
	$sth_del_ho->bind_param(1, $args_ref->{'name'});
	my $return = $sth_del_ho->execute;
	if (!defined $return) {
		print "Unable to execute deletion query: $dbh->errstr \n";
	} elsif ($return eq "0E0") {
		print "No such holiday to remove!\n";
	} else {
		print "Successfully deleted $return holiday(s) called $args_ref->{'name'}.\n";
	};
};

# Delete a holiday entry from the database by date
# Args: holiday date
sub ho_del_date {
	# Reference passed should have 'date'.
	my $args_ref = $_[0];
	my $ho_ref = ho_get();
	my $sth_del_ho = $dbh->prepare(
	'DELETE FROM ns_holiday WHERE ns_holiday_date = ?');
	$sth_del_ho->bind_param(1, $args_ref->{'date'});
	my $return = $sth_del_ho->execute;
	if (!defined $return) {
		print "Unable to execute deletion query: $dbh->errstr \n";
	} elsif ($return eq "0E0") {
		print "No such holiday to remove!\n";
	} else {
		print "Successfully deleted $return holiday(s) with date $args_ref->{'date'}.\n";
	};
};

sub ho_get {
	# Select all holiday
	# Return a hash reference containing the holidays keyed to their id
	my $sth_get_hos = $dbh->prepare('SELECT * FROM ns_holiday ORDER BY ns_holiday_date')
	or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_get_hos->execute;
	return $sth_get_hos->fetchall_hashref('ns_holiday_id');
};
