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
use Getopt::Long;
use POSIX;
use DBI;
use FindBin;
use Date::Calc;
use Data::Dumper;
use YAML qw(LoadFile);

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
my $datestr = strftime( "%Y-%m-%d", @date );
my $datearg = "";
my $args    = GetOptions( 'date=s' => \$datearg );

if ( $datearg =~ /^(\d{4})-(\d{2})-(\d{2})$/ )
    {
    $datestr = sprintf( "%4d-%02d-%02d", $1, $2, $3 );
    }

my $config = LoadFile("$FindBin::Bin/../config.yaml");

my $db       = $config->{'db'};
my $host     = $config->{'host'};
my $user     = $config->{'user'};
my $password = $config->{'password'};

my $dbh = DBI->connect( "DBI:mysql:database=$db:host=$host", $user, $password )
    or die "Can't connect to database: $DBI::errstr\n";

# Fetch shifts for the given day.
my $shifts_r = get_shifts_for_day($datestr);

# Collect all log entries for the given day.
# Store the cat id, on and off time, and machine name for these shifts.
my $logs_r = get_logs_for_day($datestr);

# Sort the log entries by start time in ascending order
#sort_log_entries(\@log_entries,'ns_shift_start_time');
@$logs_r = sort { $a->{'ns_li_ontime'} cmp $b->{'ns_li_ontime'} } @$logs_r;

# For a given shift...
foreach my $shift ( @{$shifts_r} )
    {

    my $shift_id    = $shift->{'ns_shift_id'};
    my $shift_start = $shift->{'ns_shift_start_time'};
    my $shift_end   = $shift->{'ns_shift_end_time'};

    print $shift_id . " "
        . $datestr . ": "
        . $shift_start . " - "
        . $shift_end . "\n";

    my %log_ranges = ();

    # Iterate over the log entries
    foreach my $log_entry (@$logs_r)
        {
        my $le_cat_id = $log_entry->{'ns_cat_id'};
        my $le_on     = $log_entry->{'ns_li_ontime'};
        my $le_off    = $log_entry->{'ns_li_offtime'};

        # Set the location based on which machine the log entry was
        # from. Manually created log entries should be considered
        # universal, this is effected by adding manual entries to the
        # ranges for both the doghaus and kennel so they will come up
        # in comparisons against shifts for either location.
        my @le_locations = ();
        if (
            grep( $log_entry->{'ns_li_machine'},
                ( 'aragog', 'chandra', 'hapi', 'minicat', 'scissors', 'rock' ) )
            )
            {
            @le_locations = ("dh");
            }
        elsif ( grep( $log_entry->{'ns_li_machine'}, ( 'kupo', 'paper' ) ) )
            {
            @le_locations = ("kennel");
            }
        elsif ( grep( $log_entry->{'ns_li_machine'}, ('override') ) )
            {
            @le_locations = ( "dh", "kennel" );
            }
        else
            {
            # If the log entry doesn't match one of the above
            # conditions just skip it.
            next;
            }

        # Ranges will be stored like...
        # (cat_id -> location -> [ranges])
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

        # (cat_id -> location -> [ranges])
        # ranges[[range1start(hh:mm),range1end],[range2start,range2end]..etc.]

        foreach my $le_location (@le_locations)
            {
            # Ignore out of scope log entries
            if ( $le_off lt $shift_start || $le_on gt $shift_end )
                {
                next;
                }

            # if a range for the given cat and location exists
            if ( $log_ranges{$le_cat_id}{$le_location} )
                {
                # add to the existing range or create a new one as necessary
                # if log start time later than range end time
                if ( $log_ranges{$le_cat_id}{$le_location}
                    [ $#{ $log_ranges{$le_cat_id}{$le_location} } ][1]
                    lt $le_on )
                    {
                    # add new range
                    # range start = log start
                    push(
                        @{ $log_ranges{$le_cat_id}{$le_location} },
                        [ ($le_on) ]
                    );

                    # if log end time later than shift end time
                    if ( $le_off gt $shift_end )
                        {
                        # range end = shift end
                        push(
                            @{
                                $log_ranges{$le_cat_id}{$le_location}[
                                    $#{ $log_ranges{$le_cat_id}{$le_location} }
                                ]
                            },
                            $shift_end
                        );
                        }
                    else
                        {
                        # range end = log end
                        push(
                            @{
                                $log_ranges{$le_cat_id}{$le_location}[
                                    $#{ $log_ranges{$le_cat_id}{$le_location} }
                                ]
                            },
                            $le_off
                        );
                        }

                    # elsif log end time == range end time
                    }
                elsif ( $log_ranges{$le_cat_id}{$le_location}
                    [ $#{ $log_ranges{$le_cat_id}{$le_location} } ][1] eq
                    $le_off )
                    {
                    # skip to next entry
                    next;
                    }
                else
                    {
                    # range end time earlier than log end time
                    # modify existing range entry
                    @{ $log_ranges{$le_cat_id}{$le_location}
                            [ $#{ $log_ranges{$le_cat_id}{$le_location} } ] }[1]
                        = $le_off;
                    }

                # if a range for the given cat and location doesn't exist
                }
            else
                {
                # create a new range for cat_id,location
                # if log start time earlier than shift start time
                if ( $le_on lt $shift_start )
                    {
                    # range start = shift start
                    @{ $log_ranges{$le_cat_id}{$le_location} } = [$shift_start];
                    }
                else
                    {
                    # range start = log start
                    @{ $log_ranges{$le_cat_id}{$le_location} } = [$le_on];
                    }

                # if log end time later than shift end time
                if ( $le_off gt $shift_end )
                    {
                    # range end = shift end
                    push(
                        @{
                            $log_ranges{$le_cat_id}{$le_location}
                                [ $#{ $log_ranges{$le_cat_id}{$le_location} } ]
                        },
                        $shift_end
                    );
                    }
                else
                    {
                    # range end = log end
                    push(
                        @{
                            $log_ranges{$le_cat_id}{$le_location}
                                [ $#{ $log_ranges{$le_cat_id}{$le_location} } ]
                        },
                        $le_off
                    );
                    }
                }
            }

        }

 # Calculate how many minutes are in the shift being checked against, store this
 # value.

# ($Dd,$Dh,$Dm,$Ds) = Delta_DHMS($year1,$month1,$day1, $hour1,$min1,$sec1, $year2,$month2,$day2, $hour2,$min2,$sec2);
# Shift times are in hh:mm:ss format.
    my @shift_starta = $shift_start =~ m/(\d{2}):(\d{2}):(\d{2})/;
    my @shift_enda   = $shift_end =~ m/(\d{2}):(\d{2}):(\d{2})/;

    my %shift_duration;
    @shift_duration{ 'dd', 'hh', 'mm', 'ss' } =
        Date::Calc::Delta_DHMS( 2011, 10, 26, @shift_starta[ 0 .. 2 ],
        2011, 10, 26, @shift_enda[ 0 .. 2 ] );
    $shift_duration{'mm'} += ( $shift_duration{'hh'} * 60 );
    print "Shift duration: " . $shift_duration{'mm'} . " minutes.\n";

    # Collect all assignments for the shift, store assignment ID, desk ID,
    # and cat ID for each assignment.
    my $shift_assignments_r = get_assignments_by_shift($shift_id);

# Iterate over the assignments for the current shift. assignment{ns_cat_id,ns_sa_id,ns_desk_id}
    foreach my $assignment_r (@$shift_assignments_r)
        {
        print "Assignment ID: " . $assignment_r->{'ns_sa_id'} . "\n";

        # Translate the desk id from the assignment into a format we can match
        # against the locations stored with the log ranges generated earlier.
        my $a_location;
        if ( $assignment_r->{'ns_desk_id'} == 2 )
            {
            print "Location: DOGHaus\n";
            $a_location = "dh";
            }
        elsif ( $assignment_r->{'ns_desk_id'} == 3 )
            {
            print "Location: Kennel\n";
            $a_location = "kennel";
            }
        else
            {
            print "Assignment $assignment_r->{'ns_sa_id'} was made to an invalid desk id ($assignment_r->{'ns_desk_id'}), skipping.\n";
            next;
            }

        foreach my $r_cat ( keys %log_ranges )
            {
            if ( $r_cat == $assignment_r->{'ns_cat_id'} )
                {
                my %coverage = ();
                print "Found range for cat ID: " . $r_cat . "\n";

                # The below bit needs work

                foreach my $r_loc ( keys %{ $log_ranges{$r_cat} } )
                    {
                    if ( $r_loc eq $a_location )
                        {
                        print "Range location matches assignment location.\n";
                        foreach my $r_times ( @{ $log_ranges{$r_cat}{$r_loc} } )
                            {
                            print "Start: " . $r_times->[0] . "\n";
                            print "End: " . $r_times->[1] . "\n";

                            my @st = $r_times->[0] =~ m/(\d\d):(\d\d):\d\d/;
                            my @et = $r_times->[1] =~ m/(\d\d):(\d\d):\d\d/;

                            @coverage{ 'yy', 'mo', 'dd', 'hh', 'mm', 'ss' } =
                                Date::Calc::N_Delta_YMDHMS( 2011, 10, 26,
                                @st[ 0 .. 1 ],
                                0, 2011, 10, 26, @et[ 0 .. 1 ], 0 );
                            $coverage{'mm'} += ( $coverage{'hh'} * 60 );
                            print "Logged coverage: "
                                . $coverage{'mm'}
                                . " minutes.\n";
                            }

                        }
                    else
                        {
                        print "Range location does not match assignment location.\n";
                        next;
                        }
                    }
                }
            else
                {
                next;
                }
            }

        }

    # %log_ranges
    # (cat_id -> location -> [ranges])
    # ranges[[range1start(hh:mm),range1end],[range2start,range2end]..etc.]

# Determine the coverage of the stored ranges, if any, for the CAT who assignment it is.
# For each range...
# Check cat_id
# Check location
# Determine difference between start and end of range in minutes
# Increment range in minutes variable by the difference

# Compare the actual coverage against that required by the shift.
# Get the difference between $shift_duration{'mm'} and the range in minutes variable

    # Rules:
    # -10 minute "grace" period.
    # -If more than 10 minutes of a shift are missed, count the whole shift as
    #  missed.

    # Store the result of this comparison
    print "\n";
    }

# Subroutines

# Get assigned shifts for a given day
# Args: string date (yyyy-mm-dd)
sub get_shifts_for_day
    {
    my $date = $_[0];

    # The data we need are the shift id, shift start time, and shift end
    # time of all shifts falling on $date. The table ns_shift contains
    # these in the ns_shift_id, ns_shift_start_time, and ns_shift_end_time
    # columns.
    my $sth_gsd = $dbh->prepare( '
		SELECT ns_shift_id, ns_shift_start_time, ns_shift_end_time
		FROM ns_shift
		WHERE ns_shift_date = ?
		' )
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth_gsd->bind_param( 1, $date );
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
    while ( my $result_r = $sth_gsd->fetchrow_hashref() )
        {
        push( @shift_data, $result_r );
        }

    return \@shift_data;
    }

# Get log entries for a given day
# Args: string date
sub get_logs_for_day
    {
    my $gle_date = $_[0];

    my $sth_gle = $dbh->prepare( '
		SELECT ns_cat_id, ns_li_ontime, ns_li_offtime, ns_li_machine
		FROM ns_log_item
		WHERE ns_li_date = ?
		' )
        or die "Couldn't prepare statement: " . $dbh->errstr;

    $sth_gle->bind_param( 1, $gle_date );
    $sth_gle->execute or die "Couldn't execute statement: " . $sth_gle->errstr;

    my @log_entries;
    while ( my $result_r = $sth_gle->fetchrow_hashref() )
        {
        push( @log_entries, $result_r );
        }

    return \@log_entries;
    }

# Get assignments for a given shift
# Args: int shift id
sub get_assignments_by_shift
    {
    my $gabs_shift_id = $_[0];

    my $sth_gabs = $dbh->prepare( '
		SELECT ns_sa_id, ns_cat_id, ns_desk_id
		FROM `ns_shift_assigned`
		WHERE `ns_shift_id` = ?
		' )
        or die "Couldn't prepare statement: " . $dbh->errstr;

    $sth_gabs->bind_param( 1, $gabs_shift_id );
    $sth_gabs->execute
        or die "Couldn't execute statement: " . $sth_gabs->errstr;

    my @assignments;
    while ( my $result_r = $sth_gabs->fetchrow_hashref() )
        {
        push( @assignments, $result_r );
        }

    return \@assignments;
    }
