#!/usr/bin/env ruby

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

require 'rubygems'
require 'isaac'
require 'mysql'
require 'time'

on :connect do
  join "#channel1 chan1key"
  join "#channel2 chan2key"
end

on :channel, /^!help deskbot$/i do
      msg channel, "Available commands: help, onduty [date time], next <username>, whois <username>"
end

on :channel, /^(?:%|deskbot)[^\w]*(\w+)\s*(.*)/i do
begin
  failed = true

  for i in 1..10 do #Retry 10 times
    begin
      (command, args) = match[0], match[1]

      case command
      when /help|\?/i
        msg channel, "Available commands: help, onduty [date time], next <username>, whois <username>"

      when /onduty/i
        msg channel, get_onduty(args)

      when /next/
        if args.nil?
          msg channel, "Usage: %next <username>..."
        else
          args.split(/[^\w]+/).each do |uname|
            msg channel, get_next_deskshift(uname)
          end
        end

      when /whois/
        if args.nil?
          msg channel, "Usage: %whois <username|handle>..."
        else
          args.split(/\s+/).each do |name|
            get_whois(name).each {|l| msg channel, l}
          end
        end

      when /reconnect/
        begin
          $db.close
          dbconnect
          msg channel, "Database connection established."
        rescue
          msg channel, "Unable to reestablish database connection, try again later."
        end

      else
        msg channel, "Unknown command: '#{command}'"
      end
    rescue
      $db.close rescue nil
      dbconnect
      next
    end
    failed = false
    break
  end
  if failed then
    msg channel, "Unable to reestablish database connection, try again later."
  end
rescue Exception => ex
  msg channel, ex.message
  puts ex.backtrace
end
end

def prep_queries()
  $queries = {
    :next => $db.prepare(
"SELECT CONCAT_WS(' ',ns_shift_date,ns_shift_start_time) FROM ns_shift
 JOIN (SELECT ns_shift_id FROM ns_cat
       JOIN ns_shift_assigned USING(ns_cat_id)
       LEFT JOIN ns_shift_dropped USING(ns_sa_id)
       WHERE ns_sd_id IS NULL
       AND (ns_cat_uname = ?
            OR ns_cat_handle = ? )) AS Foo
 USING(ns_shift_id)
 WHERE unix_timestamp(addtime(ns_shift_date,ns_shift_start_time)) > unix_timestamp(now())
 ORDER BY ns_shift_date,ns_shift_start_time LIMIT 1;"),

    :check_exists => $db.prepare(
"SELECT ns_cat_id FROM ns_cat
 WHERE ns_cat_uname = ?
    OR ns_cat_handle = ?;"),

    :onduty => $db.prepare(
"select ns_desk_shortname,GROUP_CONCAT(DISTINCT ns_cat_handle separator ', ') FROM ns_cat
 JOIN ns_shift_assigned USING(ns_cat_id)
 JOIN ns_shift USING(ns_shift_id)
 JOIN ns_desk USING(ns_desk_id)
 LEFT JOIN ns_shift_dropped USING(ns_sa_id)
 WHERE ns_sd_id IS NULL
 AND ns_shift_date = ?
 AND ns_shift_start_time = ?
 GROUP BY ns_desk_id;"),

    :next_onduty => $db.prepare(
"SELECT ns_desk_shortname,CONCAT_WS(' ', ns_shift_date,ns_shift_start_time),
 GROUP_CONCAT(DISTINCT ns_cat_handle SEPARATOR ', ')
 FROM ns_cat JOIN ns_shift_assigned USING(ns_cat_id)
 JOIN ns_desk USING(ns_desk_id)
 JOIN (SELECT ns_shift_id,ns_shift_date,ns_shift_start_time FROM ns_shift
       JOIN ns_shift_assigned USING(ns_shift_id)
       LEFT JOIN ns_shift_dropped USING(ns_sa_id)
       WHERE ns_sd_id IS NULL
       AND unix_timestamp(addtime(ns_shift_date,ns_shift_start_time)) > unix_timestamp( ? )
       ORDER BY ns_shift_date,ns_shift_start_time LIMIT 1) AS F
 USING(ns_shift_id) GROUP BY ns_desk_id;"),

    :whois => $db.prepare(
"SELECT ns_cat_uname,ns_cat_handle FROM ns_cat
 WHERE ns_cat_uname RLIKE ?
    OR ns_cat_handle RLIKE ?;")
  }
end

def dbconnect()
  $db = Mysql.new("db.example.com", "YOURNAMEHERE", "YOURPASSHERE", "schedule")
  $db.options(Mysql::OPT_CONNECT_TIMEOUT,0)
  #$db.reconnect = true
  $queries = {}
  prep_queries
end

configure do |c|
  c.nick = "DeskBot"
  c.server = "irc.example.com"
  c.port = "6697"
  c.ssl = true
  c.verbose = true
  dbconnect
end

def get_next_deskshift(uname)
  $queries[:next].execute uname, uname

  if $queries[:next].num_rows == 0
    $queries[:check_exists].execute(uname,uname)
    if $queries[:check_exists].num_rows == 0
      ret = "Unknown user: #{uname}."
    else
      ret = "No shifts scheduled for #{uname} at this time."
    end
  else
    row = $queries[:next].fetch
    return "#{uname} works next at #{Time.parse(row[0]).strftime("%H%M on %A, %b %d")}."
  end

  return ret
end

def get_onduty(at)
  begin
    at_time = at.nil? ? Time.now : Time.parse(at)
  rescue
    return "Couldn't parse #{at} as a date or time."
  end
  date = at_time.strftime "%Y-%m-%d"
  time = at_time.strftime "%H:00:00"
  ret = ""

  $queries[:onduty].execute(date, time)

  if $queries[:onduty].num_rows == 0
    return get_next_onduty(at_time)
  else
    ret = at_time.strftime "%A, %b %d, %H%M: "
    $queries[:onduty].each do |row|
      ret += "#{row[0]}: #{row[1]}  "
    end
    return ret
  end
end


def get_next_onduty(at)
  $queries[:next_onduty].execute(at.strftime "%Y-%m-%d %H:%M:00")

  if $queries[:next_onduty].num_rows == 0 then
    return "Nobody scheduled after #{at.strftime "%H%M %A %b %d, %Y"}.  Everything ever is bad."
  else
    row = $queries[:next_onduty].fetch
    return "Nobody scheduled. Next shift at #{Time.parse(row[1]).strftime "%H%M on %A, %b %d" }: #{row[0]}: #{row[2]}"
  end
end

def get_whois(name)
  $queries[:whois].execute(name,name)

  if $queries[:whois].num_rows == 0 then
    return "No cats matching #{name}."
  else
    r = []
    $queries[:whois].each do |row|
      r.push "Username: #{row[0]}  Handle: #{row[1]}"
    end

    if r.length > 4 then
      len = r.length
      r = r.take 3
      r.push "... #{len - 3} result#{len - 3 > 1 ? "s" : ""} omitted."
    end

    return r
  end
end
