#!/usr/bin/python2

"""
https://rdrr.io/cran/HelpersMG/src/R/sun.info.R

estimate sunrise and sunset times

python implementation based on R as proof-of-concept

"""

import math


def day_of_year(d, m, y):
    """ day of the year helper = strftime("%j") """
    N1 = math.floor(275 * m / 9)
    N2 = math.floor((m + 9) / 12)
    N3 = (1 + math.floor((y - 4 * math.floor(y / 4) + 2) / 3))
    N = N1 - (N2 * N3) + d - 30
    return N

def dec_to_hms(dec):
    """ decimal hours to human readable format 1.5h -> 01h 30m"""
    h = int(dec)
    f = dec - h
    m = int(60 * f)
    return "%02dh %02dm" % (h,m)

def suncalc(doy, lat, lon):
    """ https://rdrr.io/cran/HelpersMG/src/R/sun.info.R """

    ## Radius of the earth (km)
    R = 6378.0

    ## Radians between the xy-plane and the ecliptic plane
    epsilon = math.radians(23.45)

    ## Convert observer's latitude to radians
    L = math.radians(lat)

    ## Calculate offset of sunrise based on longitude (min)
    ## If Long is negative, then the mod represents degrees West of
    ## a standard time meridian, so timing of sunrise and sunset should
    ## be made later.
    timezone = -4 * (abs(lon) % 15)
    if (lon < 0): timezone = -1 * timezone

    ## The earth's mean distance from the sun (km)
    r = 149598000.0

    theta = 2 * math.pi / 365.25 * (doy - 80.0)

    zs = r * math.sin(theta) * math.sin(epsilon)
    rp = math.sqrt(r ** 2 - zs ** 2)

    t0 = 1440.0 / (2 * math.pi) * math.acos((R - zs * math.sin(L)) / (rp * math.cos(L)))

    ## a kludge adjustment for the radius of the sun
    that = t0 + 5.0

    ## Adjust "noon" for the fact that the earth's orbit is not circular:
    n = 720.0 - 10 * math.sin(4 * math.pi * (doy - 80.0) / 365.25) + 8 * math.sin(2 * math.pi * doy / 365.25)

    # timezone offset relative to utc/gmt
    tz = int(((7.5 + lon) % 360) / 15)
    # if over 12 use negative offset
    if tz > 12: tz = 12 - tz

    ## now sunrise and sunset are:
    sunrise = (n - that + timezone) / 60.0 + tz
    sunset  = (n + that + timezone) / 60.0 + tz

    return {"rise": sunrise, "rise_hm": dec_to_hms(sunrise),
            "set": sunset, "set_hm": dec_to_hms(sunset), 'tz': tz}


# test for Banska Bystrica
# https://www.timeanddate.com/sun/@12057205
# 04/05/2020 sunrise 5:18, sunset 20:03 GMT+2
# 04/05/2020 'rise_hm': '05h 18m', 'set_hm': '20h 02m'
bb_lat = 48.736277; bb_lon = 19.1461917
d, y = 4, 2020
for m in range(1,13):
    print "%02d/%02d/%04d" % (d,m,y), suncalc(day_of_year(d, m, y), bb_lat, bb_lon)

