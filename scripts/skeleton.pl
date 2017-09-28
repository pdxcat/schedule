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
use Date::Calc 'Delta_DHMS';
use DBI;
use FindBin;
use POSIX;
use YAML qw(LoadFile);

# script name
# script purpose

my $config = LoadFile("$FindBin::Bin/../config.yaml");

my $db       = $config->{'db'};
my $host     = $config->{'host'};
my $user     = $config->{'user'};
my $password = $config->{'password'};

