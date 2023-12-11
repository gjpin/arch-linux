#!/bin/bash
#
# https://gitlab.com/lassegs/powerprofilecycle/-/blob/ae51b294874b35fecd52480fc8dfa36a1e1484f4/powerprofilecycle.sh
# Script to cycle through power-profiles-daemon profiles. Handy for integration
# with waybar, i3blocks and others. When run it will cycle to next profile and
# output a corresponding fa-icon for displaying in a bar. With the -m toggle,
# the script will not cycle profiles, rather just print fa-icon corresponding to
# current profile.
#

PSET="powerprofilesctl set"
PGET="powerprofilesctl get"

while getopts "mh" opt; do
  case $opt in
    m)
      case $($PGET) in
        performance)
          echo  && exit 0
          ;;
        power-saver)
          echo   && exit 0
          ;;
        balanced)
          echo   && exit 0 
      esac
      ;;
    h)
      echo -e "Run script without arguments to cycle power profiles and print icon. \n-m Monitor. Get power profile and print icon. \n-h Help. Show this help text"  
      exit 0
      ;;
    *)
      echo "Invalid option. Try -h."
      exit 1
  esac
done

case $($PGET) in
  performance)
    $PSET power-saver && echo   && exit 0
    ;;
  power-saver)
    $PSET balanced && echo   && exit 0
    ;;
  balanced)
    $PSET performance && echo  && exit 0
    ;;
esac

echo "Could not find power profile match. Is power-profiles-daemon running?"
exit 1
