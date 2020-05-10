#!/bin/sh

RELAY_CTRL=/sys/class/leds/tp-link:blue:relay/brightness

echo "Content-Type: text/plain"; echo

case "${QUERY_STRING:-$1}"  in
 	toggle) 
    		case "$(cat $RELAY_CTRL)" in
       		0) 
       			echo 1 > $RELAY_CTRL
          		echo "ON"
          		;;
       		1) 
       			echo 0 > $RELAY_CTRL
       	  		echo "OFF"
          		;;
    		esac
    		;;
 	on) 
   		echo 1 > $RELAY_CTRL
   		echo "ON"
   		;;
 	off) 
   		echo 0 > $RELAY_CTRL
   		echo "OFF"
   		;;
 	*) 
    		case "$(cat $RELAY_CTRL)" in
       		0) 
       			echo "RELAY is OFF"
          		;;
       		1) 
       			echo "RELAY is ON"
          		;;
    		esac
    		;;
esac

