# sunrise - sunset calculator

These scripts can calculate sunrise + sunset time for specific location and date.

## motivation

Activate a staircase LED light just before sunset to save the energy, but make sure the staircase
is well lit for safety reasons. The staircase LED bars are controlled by WiFi Smart Socket
[ [ Kankun / Konke ](https://openwrt.org/toh/kankun/kk-sp3) ] running OpenRWT. So any similar smart-plug 
device based on OpenWRT should work ...

    BusyBox v1.19.4 (2014-03-27 17:39:06 CST) built-in shell (ash)
    Enter 'help' for a list of built-in commands.
    
      _    _               _    _
     | | _-_| _____ _____  | | _-_| _____ ____
     |  -_-  |     ||     ||  -_-  |     ||    |
     | |-_   |  -  ||  |  || |-_   |  -__||   _|
     |  _ -_ |_____||__|__||  _ -_ |_____||__|
     |_| -__|  S M A L L   |_| -__| S M A R T
     -----------------------------------------------------
     KONKE Technology Co., Ltd. All rights reserved.
     -----------------------------------------------------
      * www.konke.com            All other products and
      * QQ:27412237              company names mentioned
      * 400-871-3766             may be the trademarks of
      * fae@konke.com            their respective owners.
     -----------------------------------------------------

![Smart WiFi Socket Kankun/Konke](/images/konke-sp3.jpg)

## possible solutions

Simplified overview of possible ways to approach the problem with pros and cons:

* online services (sunrise/sunset calculators)
  - pros:
    - very easy implementation
  - cons:
    - does not work off-line
    - unreliale in long run as public free services tend to be sold, change their interfaces etc ... 
    simply speaking
    if they cannot make any profit from you (pushing ads) they do not like you and make
    everything in their power to block you from using their precious service

* precalculated lookup table
  - pros:
    - easy implementation
    - works off-line
  - cons:
    - limited flexibility (table has to be recalculated for any new location)
    - requires support tools for table calculation
  
* real-time sunsrise/sunset calculator
  - pros:
    - works off-line
  - cons:
    - not easy implementation
  
* dark/dusk sensitive input:
  - pros:
    - location independent
    - can handle also special cases like sun eclipse, heavy clouds during the day
  - cons:
    - requires hw modification (add photosensitive LDR element)
    - requires fw extension (OpenWRT package to setup sensitivity etc)
    
This is the implementation of  "real-time sunrise/sunset calculator"
 
## implementation
 
Implementation is based on R code [ [sun.info.R](https://rdrr.io/cran/HelpersMG/src/R/sun.info.R) ].
This R implementation looks very precise (within a few minutes) while complexity of the code is not high.
Even the comments and variable names are matching as close as possible the R-code for easy refenrence.

### scripts

The repository contains following scripts:

* [sunrise-sunset.py](/sunrise-sunset.py) ... python implmenetation as a proof-of-concept (PoC) to verify the functionality 

* [sunrise-sunset.awk](/sunrise-sunset.awk) ... awk implementation for OpenWRT

* [cron-sunset.sh](/cron-sunset.sh) ... cron wrapper for OpenWRT

#### sunrise-sunset.py

Python implementation - just PoC as python in not included in OpenWRT [ [ Kankun / Konke ](https://openwrt.org/toh/kankun/kk-sp3) ] 
customized firmware.

#### sunrise-sunset.awk

AWK impelementation - suits pefectly for OpenWRT [ [ Kankun / Konke ](https://openwrt.org/toh/kankun/kk-sp3) ] customized 
firmware as awk is build in. A few math/system functions have to defined explicitly as they are not part of awk, like 
ABS=VALUE, ARCUS-COSINE, convert DEGREE-to-RADIANS and SLEEP. The rest is just command line parameter handling, verbose
output and some conversions for human friendly format. 

There are four mandatory cli parametres: latitude, longitude, mode (sunrise/sunset) and offset. 

Executing with less than four parameters shows this usage help:

    = calculate sunset/sunrise time for location and date = awk script for OpenWRT = ver 2020.05.01 =

    usage: sunrise-sunset.awk [-v v=1] -- latitude longitude [sun]set|[sun]rise offset [dec|hms|systime|sleep] [yyyy-mm-dd]

    -v v=1     ... optional verbose output
    latitude   ... location lat.  coordinate [decimal]
    longitude  ... location long. coordinate [decimal]
    [sun]rise  ... calculate sunrise
    [sun]set   ... calculate sunset
    offset     ... offset in minutes (negave = before, positive = after)
    dec        ... print decimal value of sunset/sunrise [hours]
    hms        ... print human readable h-m-s value of sunset/sunrise [h m s]
    systime    ... print unix time value of sunset/sunrise [sec]
    sleep      ... sleep till sunset/sunrise shitfed by offset value
    yyyy-mm-dd ... use this date for calculation (default today)
    
    multiple parts can be requested to return, e.g:  -- lat long sunset offset 'dec hms systime sleep'

#### cron-sunset.sh 

Intended to be called directly from cron. It is just simple wrapper for sunrise-sunset.awk providing parameters and logging.
The wrapper is executed by cron at the scheduled time. Then it sleeps until sunset - offset time.
When sleep is over configurable action is executed (switch on the lights). If execution (cron) time t is after
the sunset then action is executed immediately. So for example the cron is executing wrapper cron-sunset.sh at 17:00.
That means the light will switch on no sooner than 17:00 or at sunset - offset time. The offset is for fine-tune adjustment.
Optional action logging logs via standard logger. The script accepts action paameters (default to "relay.cgi on").

### To do

Possible future improvements and extensions:
- optional location autodetect by ip geolocation
- additional LDR (dark/dusk sensitivity) option





  



