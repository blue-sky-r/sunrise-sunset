#!/usr/bin/awk -f

# ============================
# sunset / sunrise calculation
# ============================
#
# awk implementation based on R - https://rdrr.io/cran/HelpersMG/src/R/sun.info.R
#
# calculates sunset/sunrise trigger time with optional offset and optional sleep
#
# https://github.com/blue-sky-r/sunrise-sunset

function usage()
{
    print "= calculate sunset/sunrise time for location and date = awk script for OpenWRT = ver 2021.01.09 ="
    print
    printf "usage: %s [-v v=1] -- latitude longitude [sun]set|[sun]rise offset [dec|hms|systime|sleep] [yyyy-mm-dd]", ENVIRON["_"]
    print
    print
    print "-v v=1     ... optional verbose output"
    print "latitude   ... location lat.  coordinate [decimal]"
    print "longitude  ... location long. coordinate [decimal]"
    print "[sun]rise  ... calculate sunrise"
    print "[sun]set   ... calculate sunset"
    print "offset     ... offset in minutes (negave = before, positive = after)"
    print "dec        ... print decimal value of sunset/sunrise [hours]"
    print "hms        ... print human readable h-m-s value of sunset/sunrise [h m s]"
    print "systime    ... print unix time value of sunset/sunrise [sec]"
    print "sleep      ... sleep till sunset/sunrise shitfed by offset value"
    print "yyyy-mm-dd ... use this date for calculation (default today)"
    print
    print "multiple parts can be requested to return, e.g:  -- lat long sunset offset 'dec hms systime sleep'"
    print
    exit 1
}

# verbose output (for debugging)
#
function verbose(txt)
{
    if (v) print txt
}

# absolute value
#
function abs(x)
{
    return x >= 0 ? x : -x
}

# decimal secs to human friendly hour min sec notation ( 3695 -> 01h 30m 05s )
#
function s2hms(sec)
{
    hint = int(sec / 3600)
    mint = int((sec % 3600) / 60)
    sint = sec - 3600 * hint - 60 * mint
    return sprintf("%02dh %02dm %02ds", hint, mint, sint)
}

# angle to radians
#
function radians(angle)
{
    return angle * pi / 180
}

# arcus cosine - https://en.wikipedia.org/wiki/Inverse_trigonometric_functions
#
function acos(x)
{
    return atan2(sqrt(1-x*x), x)
}

# yyy-mm-dd -> yyyy mm dd 00 00 00
#
function ymd000(s)
{
    gsub(/-|\//, " ", s)
    return s " 00 00 00"
}

# sleep seconds, immediate return for negative sleep
#
function sleep(sec)
{
    if (sec > 0) system(sprintf("sleep %d", sec))
}

# sHHMM -> decimal (+0130 -> 1.5)
#
function shhmm_dec(shhmm)
{
    # abs +HHMM to decimal
    anum = substr(shhmm, 2, 2) + substr(shhmm, 4) / 60
    # adjust sign
    return substr(shhmm, 1, 1) == "+" ?  anum : -anum
}

# local DST (daylight saving time) offset as decimal hours (+0130 -> 1.5)
#
function dst_hdec(ts)
{
    # get local timezone offset for Jan 1, 2000 e.g. +0100
    zofs1jan = strftime("%z", mktime("2000 01 01 0 0 0"), 0)
    # get local timezone offset for timestamp ts e.g. +0100
    zofs = strftime("%z", ts, 0)
    # calc dst fix
    return zofs == zofs1jan ?  0 : shhmm_dec(zofs) - shhmm_dec(zofs1jan)
}

# sun-set/rise calculation for day-of-year, lattitude, longitude
#
function suncalc(doy, lat, lon, rise)
{
    ## Radius of the earth (km)
    R = 6378

    ## Radians between the xy-plane and the ecliptic plane
    epsilon = radians(23.45)

    ## Convert observer's latitude to radians
    L = radians(lat)

    ## Calculate offset of sunrise based on longitude (min)
    ## If Long is negative, then the mod represents degrees West of
    ## a standard time meridian, so timing of sunrise and sunset should
    ## be made later.
    timezone = -4 * (abs(lon) % 15)
    if (lon < 0) timezone = -1 * timezone

    ## The earth's mean distance from the sun (km)
    r = 149598000

    theta = 2 * pi / 365.25 * (doy - 80)

    zs = r * sin(theta) * sin(epsilon)
    rp = sqrt(r ** 2 - zs ** 2)

    t0 = 1440 / (2 * pi) * acos((R - zs * sin(L)) / (rp * cos(L)))

    ## a kludge adjustment for the radius of the sun
    that = t0 + 5

    ## Adjust "noon" for the fact that the earth's orbit is not circular:
    n = 720 - 10 * sin(4 * pi * (doy - 80.0) / 365.25) + 8 * sin(2 * pi * doy / 365.25)

    ## now sunrise and sunset are:
    sunrise = (n - that + timezone) / 60.0
    sunset  = (n + that + timezone) / 60.0

    return rise ? sunrise : sunset
}

BEGIN {
    if (ARGC < 4 ) usage()

    # verbose/debug
    verbose("ARGC: " ARGC)
    for (i = 0; i < ARGC; i++) verbose(sprintf("\tARGV[%d]: %s", i, ARGV[i]))

    # pi constant
    #
    pi = 3.1415926535

    # location coordinates [decimal]
    lat = ARGV[1]
    lon = ARGV[2]

    # sun-set sun-rise
    sr  = ARGV[3]

    # offset [min]
    ofs = ARGV[4]

    # what to return - default hms
    ret = ARGC > 5 ? ARGV[5] : "hms"

    # timestamp
    ts  = ARGC > 6 ? mktime(ymd000(ARGV[6])) : systime()
    # day-of-year
    doy = strftime("%j", ts, 1)

    # verbose/debug
    verbose("INPUT - latitude[dec]:" lat ", longitude[dec]:" lon ", sunset/rise[sr]:" sr ", offset[min]:" ofs ", return:[ " ret " ]")

    # dst fix
    dst = dst_hdec(ts)
    verbose("DATETIME - timestamp:" ts ", datetime[Y-m-d H:M:S]:" strftime("%F %T", ts, 1) ", day-of-year:" doy " dst[h.dec]:" dst)

    # calculated decimal hour
    hcalc = suncalc(doy, lat, lon, match(sr, /rise/))
    # calculated value with dst fix and optional offset
    h = hcalc + dst + ofs / 60
    # verbose/debug
    verbose("RESULT - " sr " = calc[dec]:" hcalc " + dst[dec]:" dst " + offset[min]:" ofs " = hours[dec]:" h ", hours[hms]:" s2hms(3600 * h))

    # h as timestamp
    tsh = mktime(strftime("%Y %m %d 00 00 00", ts, 1)) + int(3600 * h)
    # calc nap length in sec
    nap = tsh - ts
    # verbose/debug
    verbose("SLEEP  - adjusted " sr " = hours[dec]:" h ", timestamp:" tsh ", nap.time[sec]:" nap ", nap.time[hms]:" s2hms(nap))

    # return requested parts
    if (index(ret, "dec"))      print h
    if (index(ret, "hms"))      print s2hms(3600 * h)
    if (index(ret, "systime"))  print tsh
    if (index(ret, "sleep"))    sleep(nap)
}
