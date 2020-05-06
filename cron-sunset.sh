#!/bin/ash

# sunset script - trigger action at sunset + offset
#
# if the offset is negative = trigger the action offset minutes before sunset (like switch on the lights)
#
# REQUIRES: sunrise-sunset.awk
#
# USAGE: cron-sunset.sh [action pars]
#
# intended to be called from cron on OpenWRT
# it sleeps till $OFS minutes before sunset and
# then executes the $ACTION (default relay.cgi on)
#
# https://github.com/blue-sky-r/sunrise-sunset

# geolocation coordinates (BB.SK.EU)
#
LAT=48.736277
LON=19.1461917

# activation offset in minutes (negative = before sunset)
#
OFS=-10

# syslog tag (empty to disable syslog)
#
TAG=sunset

# executables dir
#
DIR="/www/cgi-bin"

# action (default 'relay.cgi on')
#
ACTION=${@:-relay.cgi on}

# sleep until sunset - offset
#
$DIR/sunrise-sunset.awk -- $LAT $LON sunset $OFS sleep

# optional syslog msg
#
[ -n "$TAG" ] && logger -t "$TAG" "${OFS}m = ACTION: $ACTION"

# execute action
#
$DIR/$ACTION
