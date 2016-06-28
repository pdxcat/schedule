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
use DBI;
use FindBin;
use YAML qw(LoadFile);

# ns_term_management.pl
# View, add, edit, and remove terms from the schedule database.

my $config   = LoadFile("$FindBin::Bin/../config.yaml");

my $db = $config->{'db'};
my $host = $config->{'host'};
my $user = $config->{'user'};
my $password = $config->{'password'};

my $dbh = DBI->connect ("DBI:mysql:database=$db:host=$host",$user,$password) or die "Can't connect to database: $DBI::errstr\n";

# Check arguments. Valid ones are:
# -l					Lists terms currently in the database
# -n name yyyy yyyy-mm-dd yy-mm-dd 	Create a new entry in the database
# -d name yyyy				Delete an entry from the database

my $invalid_args_message = "Invalid argument. Use one of the following:
-l                            		Lists terms currently in the database
-n name yyyy yyyy-mm-dd yy-mm-dd	Create a new entry in the database
-d name yyyy                  		Delete an entry from the database\n";

if (!defined $ARGV[0]) {
	print $invalid_args_message;
# Option for listing all term entries
} elsif ($ARGV[0] eq "-l") {
	term_list();
# Option to create a new term entry
} elsif ($ARGV[0] eq "-n") {
	# Do some checking of the arguments
	if (@ARGV == 5
	&& $ARGV[1] =~ /\w*/
	&& $ARGV[2] =~ /^\d{4}$/
	&& $ARGV[3] && $ARGV[4] =~ /^\d{4}-\d{2}-\d{2}$/)
	# If they check out, dump them to a hash and call term_add()
	{
		my %args = (
		"name" => sprintf("%s %4d",@ARGV[1,2]),
		"start_date" => $ARGV[3],
		"end_date" => $ARGV[4], );
		term_add(\%args);
	# If something is off, die
	} else {
		print $invalid_args_message;
	};
# Option to delete a term entry
} elsif ($ARGV[0] eq "-d") {
	# Check out arguments, make sure they're sane.
	if (@ARGV == 3
	&& $ARGV[1] =~ /\w*/
	&& $ARGV[2] =~ /^\d{4}$/)
	# If they look good dump them in a hash and call term_del()
	{
		my %args = (
		"name" => sprintf("%s %4d",@ARGV[1,2]), );
		term_del(\%args);
	# If not, die
	} else {
		print $invalid_args_message;
	};
# Die if any other option was indicated
} else {
	print $invalid_args_message;
};

# Subroutines

# List terms in the database
# Args: none
sub term_list {
	my $term_ref = term_get();
	foreach my $id ( keys(%{$term_ref}) ) {
		print "$term_ref->{$id}->{'ns_term_name'} starting $term_ref->{$id}->{'ns_term_startdate'} and ending $term_ref->{$id}->{'ns_term_enddate'}.\n";
	};
};

# Add a term entry to the database
# Args: term name, term start date, term end date
sub term_add {
	# Reference passed from main body of program, should have 'name',
	# 'start_date', 'end_date'.
	my $args_ref = $_[0];
	my $term_ref = term_get();
	# Search through the existing terms to make sure there are no
	# collisions with the term to be added.
	foreach my $id (keys(%{$term_ref})) {
		if ($term_ref->{$id}->{'ns_term_name'}
		eq $args_ref->{'name'}
		|| $term_ref->{$id}->{'ns_term_startdate'}
		eq $args_ref->{'start_date'}
		|| $term_ref->{$id}->{'ns_term_enddate'}
		eq $args_ref->{'end_date'}) {
			print "Collision detected!\n";
			exit;
		};
	};
	# If there aren't any collisions with existing entries, add a new one
	# with the specified attributes.
	my $sth_add_term = $dbh->prepare(
	'INSERT INTO ns_term (ns_term_name, ns_term_startdate, ns_term_enddate)
	VALUES (?, ?, ?)') or die "Couldn't prepare statement: $dbh->errstr \n";
	$sth_add_term->bind_param(1, $args_ref->{'name'});
	$sth_add_term->bind_param(2, $args_ref->{'start_date'});
	$sth_add_term->bind_param(3, $args_ref->{'end_date'});
	my $return = $sth_add_term->execute;
	# Query should affect 1 row, anything else is odd...
	if (!defined $return) {
		print "Unable to execute addition query: $dbh->errstr \n";
	} elsif ($return eq 1) {
		print "Added new term entry for $args_ref->{'name'}\n";
	} else {
		print "Something odd happened. Addition query returned: $return\n";
	};
};

# Delete a term entry from the database
# Args: term name
sub term_del {
	# Reference passed from main body of program, should have 'name'.
	my $args_ref = $_[0];
	my $term_ref = term_get();
	my $sth_del_term = $dbh->prepare(
	'DELETE FROM ns_term WHERE ns_term_name = ?');
	$sth_del_term->bind_param(1, $args_ref->{'name'});
	my $return = $sth_del_term->execute;
	# Query should affect either 1 or no rows, anything else is odd...
	if (!defined $return) {
		print "Unable to execute deletion query: $dbh->errstr \n";
	} elsif ($return eq "0E0") {
		print "No such term to remove!\n";
	} elsif ($return == 1) {
		print "Successfully deleted term $args_ref->{'name'}.\n";
	} else {
		print "Something odd happened. Deletion query returned: $return\n";
	};
};

sub term_get {
	# Select all terms
	# Return a hash reference containing the terms keyed to their id
	my $sth_get_terms = $dbh->prepare('SELECT * FROM ns_term')
	or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_get_terms->execute;
	return $sth_get_terms->fetchall_hashref('ns_term_id');
};
