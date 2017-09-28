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
use Date::Calc ( 'Delta_DHMS', 'Add_Delta_Days' );
use DBI;
use FindBin;
use POSIX;
use YAML qw(LoadFile);

my $config = LoadFile("$FindBin::Bin/../config.yaml");

my $db       = $config->{'db'};
my $host     = $config->{'host'};
my $user     = $config->{'user'};
my $password = $config->{'password'};

my ( $date, $shortdate, $weekday, $windate, $dbdate );

my $datearg  = '';
my $rangearg = '';
my $args     = GetOptions(
    'date=s'  => \$datearg,
    'range=s' => \$rangearg
);

if ( $datearg =~ /^(\d{4})-(\d{2})-(\d{2})$/ && $rangearg eq '' )
    {
    # If we got a date argument only...
    $date      = strftime( '%a %b %e', 0, 0, 0, $3, $2 - 1, $1 - 1900 );
    $shortdate = strftime( '%b%d',     0, 0, 0, $3, $2 - 1, $1 - 1900 );
    $weekday   = strftime( '%a',       0, 0, 0, $3, $2 - 1, $1 - 1900 );
    $windate   = $1 . $2 . $3;
    $dbdate    = $1 . '-' . $2 . '-' . $3;

    process_logs();

    }
elsif ($datearg eq ''
    && $rangearg =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{4})-(\d{2})-(\d{2})$/ )
    {
    # If we got a range argument only...
    my @rangecurrent = ( $1, $2, $3 );
    my @rangeend     = ( $4, $5, $6 );

    while (
        Date::Calc::Delta_Days( @rangecurrent[ 0 .. 2 ], @rangeend[ 0 .. 2 ] )
        >= 0 )
        {
        $date = strftime(
            '%a %b %e', 0, 0, 0, $rangecurrent[2],
            $rangecurrent[1] - 1,
            $rangecurrent[0] - 1900
        );
        $shortdate = strftime(
            '%b%d', 0, 0, 0, $rangecurrent[2],
            $rangecurrent[1] - 1,
            $rangecurrent[0] - 1900
        );
        $weekday = strftime(
            '%a', 0, 0, 0, $rangecurrent[2],
            $rangecurrent[1] - 1,
            $rangecurrent[0] - 1900
        );
        $windate = sprintf( '%4d%02d%02d',   @rangecurrent[ 0 .. 2 ] );
        $dbdate  = sprintf( '%4d-%02d-%02d', @rangecurrent[ 0 .. 2 ] );

        process_logs();

        @rangecurrent[ 0 .. 2 ] =
            Date::Calc::Add_Delta_Days( @rangecurrent[ 0 .. 2 ], 1 );
        }

    }
elsif ( $datearg eq '' && $rangearg eq '' )
    {
    print "Defaulting to the current date. Try --date or --range if you need to process logs for other days.\n";

    # If we got neither argument...
    chomp( $date      = `date +'%a %b %e'` );
    chomp( $shortdate = `date +%b%d` );
    chomp( $weekday   = `date +%a` );
    chomp( $windate   = `date +%Y%m%d` );
    chomp( $dbdate    = `date +'%Y-%m-%d'` );

    process_logs();

    }
else
    {
    # Anything else...

    }

sub process_logs
    {
    my @strays = ();
    my @logs   = ();

    printf( "Doing things for date %s\n", $dbdate );

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
    foreach (
        `ssh -q schedule\@chandra.cs.pdx.edu \'last dtlocal | grep \"$date\"\'`)
        {
    # Some sample last output...
    # sunshine  dtlocal      :5               Wed Sep  7 13:37   still logged in
    # nibz      dtlocal      :3               Fri Sep  2 13:07 - down  (1+05:15)
    # nibz      dtlocal      :3               Thu Sep  1 17:24 - 13:06  (19:42)
        /^(.+?)\s+.+?\s+(.+?)\s+.+?(\d{2}:\d{2}).+?(\d{2}:\d{2}|logged).+?/;

        # If the line is not related to the DH Sunray step over it
        if ( $2 ne ':3' && $2 ne ':4' )
            {
            next;
            }

        # Ignore people who are still logged in
        if ( $4 eq 'logged' )
            {
            }
        elsif ( $4 ne '(00:00)' )
            {
            push @logs, "$1 $3 $4 chandra";
            }
        }

#Add aragog logs
# Aragog is gone, 10/20/2011
#foreach (`ssh -q schedule\@aragog.cat.pdx.edu \'last 1 2 3 4 5 6 7 8 9 10 | grep \"$date\" | grep -v wtmp\'`){
#  /^(.+?)\s+.+?\s+.+?\s+.+?\s+.+?\s+.+?\s+(.+?)\s+.+?\s+(.+?)\s+(.+)\s/;
#  if($3 eq "logged"){
#    push @strays, "$1 $2 $3 aragog";
#  }elsif ($4 ne "(00:00)"){
#    push @logs, "$1 $2 $3 aragog";
#  };
#};

    #Add scissors logs (formerly minicat)
    # Some sample last output:
    #eidolon  pts/0        rawr.cat.pdx.edu Fri Oct 21 13:39   still logged in
    #morbid   pts/0        :0.0             Fri Oct 21 11:22 - 11:26  (00:03)
    #morbid   pts/0        :0.0             Fri Oct 21 10:12 - 11:22  (01:10)
    #morbid   tty8         :0               Fri Oct 21 10:10 - 11:26  (01:15)
    foreach (
`ssh -q schedule\@scissors.cat.pdx.edu \'last | grep \"$date\" | grep -v wtmp\ | grep \":0\" '`
        )
        {
        /^(.+?)\s+.+?\s+.+?\s+.+?\s+.+?\s+.+?\s+(.+?)\s+.+?\s+(.+?)\s+(.+)\s/;
        if ( $3 eq 'logged' )
            {
            push @strays, "$1 $2 $3 scissors";
            }
        elsif ( $4 ne '(00:00)' )
            {
            push @logs, "$1 $2 $3 scissors";
            }
        }

    #Add windows logs
    foreach ( 'hapi', 'mut', 'kupo', 'aragog', 'paper', 'rock' )
        {
        my @temp2 = ();
        foreach (
`ssh schedule\@chandra.cs.pdx.edu \'grep "$windate" /u/schedule/logs/windows/*|grep -i $_\'`
            )
            {
            /^(?:.+:)(\w+),(\w+).+?(?:\w{4})(?:\w{2})(?:\w{2})(\w{2})(\w{2}),/;
            push @temp2, "$1 $3:$4 $2";
            }
        @temp2 = sort @temp2;
        my $i = 0;
        my $j = 1;
        while ( $i < @temp2 )
            {
            if ( $j == @temp2 )
                {
                push @strays, $temp2[$i];
                $i++;
                next();
                }
            $temp2[$i] =~ /^(\w+)/;
            my $m = $1;
            $temp2[$j] =~ /^(\w+)/;
            my $n = $1;
            if ( $m ne $n )
                {
                push @strays, $temp2[$i];
                $i++;
                $j++;
                next;
                }
            if ( $temp2[$i] =~ /" off"/ )
                {
                $i++;
                $j++;
                push @strays, $temp2[$i];
                next();
                }
            elsif ( $temp2[$i] =~ /" on"/ && $temp2[$j] =~ /" on"/ )
                {
                $i++;
                $j++;
                push @strays, $temp2[$j];
                next;
                }
            $temp2[$i] =~ /^(?:.+?)\s(.+)\s(?:.+)/;
            my $k = $1;
            $temp2[$j] =~ /^(?:.+?)\s(.+)\s(?:.+)/;
            my $l = $1;
            push @logs, "$m $k $l $_";
            $i += 2;
            $j += 2;
            }
        }

# Build hash of active cat's usernames and their id in the database...
# Should be type 1 (DOG) or type 2 (DROID) if they are active and subject to desk duties.
    my %active_cats;
    %active_cats = ();

    # uname: id
    my $dbh =
        DBI->connect( "DBI:mysql:database=$db:host=$host", $user, $password )
        or die "Can't connect to database: $DBI::errstr\n";
    my $sth_get_active_cats = $dbh->prepare(
        'SELECT ns_cat_id, ns_cat_uname, ns_cat_type_id FROM ns_cat')
        or die 'Could not prepare statement: ' . $dbh->errstr;
    $sth_get_active_cats->execute;
    while ( my @ns_cat_entry = $sth_get_active_cats->fetchrow_array() )
        {
        if ( $ns_cat_entry[2] == 1 || $ns_cat_entry[2] == 2 )
            {
            $active_cats{ $ns_cat_entry[1] } = $ns_cat_entry[0];
            }
        }

    #my $key;
    #foreach $key (sort keys (%active_cats)) {
    #   print "$key: $active_cats{$key}\n";
    #};

    my $sth_add_log_entry = $dbh->prepare(
'INSERT INTO `ns_log_item` (ns_cat_id,ns_li_date,ns_li_ontime,ns_li_offtime,ns_li_machine) VALUES (?,?,?,?,?)'
    ) or die 'Could not prepare statement: ' . $dbh->errstr;
    my $sth_check_if_exists = $dbh->prepare(
'SELECT COUNT(*) FROM `ns_log_item` WHERE ns_li_date=? AND ns_li_ontime=? AND ns_li_offtime=? AND ns_li_machine=?'
    ) or die 'Could not prepare statement: ' . $dbh->errstr;

    # @logs format...
    # username timeon timeoff machine
    foreach (@logs)
        {
        /(\w+).+?(\d\d:\d\d).+?(\d\d:\d\d).+?(\w+)$/;

# Make sure this is a DOG or DROID by checking against the hash we made earlier.
        if ( exists $active_cats{$1} )
            {
            $sth_check_if_exists->bind_param( 1, $dbdate );
            $sth_check_if_exists->bind_param( 2, $2 );
            $sth_check_if_exists->bind_param( 3, $3 );
            $sth_check_if_exists->bind_param( 4, $4 );
            $sth_check_if_exists->execute;
            my $rows = $sth_check_if_exists->fetchrow_array();

        # Make sure this log entry hasn't already been recorded to the database.
            if ( $rows >= 1 )
                {
                print "Log entry for $1 ($dbdate,$2,$3,$4) already exists in database. Skipping.\n";

                # If we passed the two checks, add the log item to the database.
                }
            else
                {
                print "$1 is active, adding log entry for $dbdate,$2,$3,$4.\n";
                $sth_add_log_entry->bind_param( 1, $active_cats{$1} );
                $sth_add_log_entry->bind_param( 2, $dbdate );
                $sth_add_log_entry->bind_param( 3, $2 );
                $sth_add_log_entry->bind_param( 4, $3 );
                $sth_add_log_entry->bind_param( 5, $4 );
                $sth_add_log_entry->execute;
                }

            # If the user is not a DOG or DROID, don't do anything.
            }
        else
            {
            print "$1 not a DOG or DROID, skipping.\n";
            }
        }

    return 1;
    }
