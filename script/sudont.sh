#!/bin/bash
#
# This is the sudo agent, which either allows or denies access to sudo for users on this system.
#
# Built by Daniel Ward. Do not contact me for technical support.
#


#
# MySQL Credentials;
#
  mysqluser="USERNAME" # < Not root, it won't work for regular users.
  mysqlpass="PASSWORD"
#
# Define directory;
#
  thisdir="/etc/sudont"
#
# Begin;
#

# Default table layout for access_control;
#mysql> select * from access_control;
#+----+------------+-----------------------------+-----------------+
#| id | localuser  | dayscanaccess               | accesstimeframe |
#+----+------------+-----------------------------+-----------------+
#|  1 | gitcpublic | mon,tue,wed,thu,fri,sat,sun | 00:01-23:59     |
#+----+------------+-----------------------------+-----------------+

# Get the username that's trying to sudo;
  localuser="$(whoami)"

  echo "Querying for $localuser"
# Define the day in lowercase
  daytoday="$(date | awk '{print $1}')"
  if [[ $daytoday == "Mon" ]]; then
        daytoday='mon'
  fi
  if [[ $daytoday == "Tue" ]]; then
        daytoday='tue'
  fi
  if [[ $daytoday == "Wed" ]]; then
        daytoday='wed'
  fi
  if [[ $daytoday == "Thu" ]]; then
        daytoday='thu'
  fi
  if [[ $daytoday == "Fri" ]]; then
        daytoday='fri'
  fi
  if [[ $daytoday == "Sat" ]]; then
        daytoday='sat'
  fi
  if [[ $daytoday == "Sun" ]]; then
        daytoday='sun'
  fi
# Get the user in the db;
  mysql --user="$mysqluser" --password="$mysqlpass" -e "USE sudont; SELECT localuser AS '' FROM access_control WHERE localuser = '$localuser' AND dayscanaccess LIKE '%$daytoday%';" > $thisdir/temp/sudont.user.data 2>/dev/null
# Get the days in the db for that user;
  mysql --user="$mysqluser" --password="$mysqlpass" -e "USE sudont; SELECT dayscanaccess AS '' FROM access_control WHERE localuser = '$localuser' AND dayscanaccess LIKE '%$daytoday%';" > $thisdir/temp/sudont.days.data 2>/dev/null
# Get the access timeframe for that user;
  mysql --user="$mysqluser" --password="$mysqlpass" -e "USE sudont; SELECT accesstimeframe AS '' FROM access_control WHERE localuser = '$localuser' AND dayscanaccess LIKE '%$daytoday%';" > $thisdir/temp/sudont.times.data 2>/dev/null

# Check the user is valid;
  if grep -q "$localuser" "$thisdir/temp/sudont.user.data"; then
        # User is valid;
          if grep -q "$daytoday" "$thisdir/temp/sudont.days.data"; then
                # User can access on this day;
                # Check if the user has permissions for this time;
                  sed -i "s/\-/ /g" $thisdir/temp/sudont.times.data
                #
                # Define the time now;
                  timenow="$(date | awk '{print $4}' | cut -c1-5 | awk -F':' '$0=$1$2')"
                #
                # Define start time for sudo license;
                  sudostart="$(cat $thisdir/temp/sudont.times.data | awk '{print $1}')"
                #
                # Define end time for sudo license;
                  sudoend="$(cat $thisdir/temp/sudont.times.data | awk '{print $2}')"
                #
                # Buckle your seatbelts;
                #
                # Okay, so, if the time is anywhere between '00:00' and '09:59', bash will immediately require that Jesus take the wheel, then we're in trouble.
                # Bash will define it as an octal number, as it starts with a zero. Only digits 0-7 are, however, allowed in octal, as decimal 8 is octal 010. Hence 08 is not a valid number, and that's the reason for the error.
                # So, if the defined time in the db is beginning with '0', then we can just say 'no' , and go on our merry way.
                # We also need to apply that same principle to times starting with '0' from the actual system output of $date.
                #
                # "But dan, how do u do dis?" I hear you ask.... Simple... Like this...
                #
                #
                # Get the start time in the DB, and check if it has a '0' at the beginning;
                  starttimefromdb="$sudostart"
                # Check if it begins with a '0';
                  if [[ $starttimefromdb = "0"* ]]; then
                        # Set the 'sudostart' variable to account for this;
                        sudostartvar="${10#sudostart}"
                  else
                        # You're good to go, partner;
                        sudostartvar="$sudostart"
                  fi
                # Now we need to get the end time from the DB, and check if it has a '0' at the beginning;
                  endtimefromdb="$sudoend"
                  if [[ $endtimefromdb = "0"* ]]; then
                        # Set the 'sudoend' variable to account for this;
                        sudoendvar="${10#sudoend}"
                  else
                        # You're good to go, partner;
                        sudoendvar="$sudoend"
                  fi
                # Now we also apply this for the current output of the system;
                  systemtimevar="$timenow"
                  if [[ $systemtimevar = "0"* ]]; then
                        # Set the system time to account for the '0' at the start;
                        timenowvar="${timenow#0}"
                  else
                        # You're good to go, partner;
                        timenowvar="$timenow"
                  fi
                # Now, let's apply our new Dr. Who time travelling knowledge to our if statements, and voila!
                if [[ "$timenowvar" -gt "$sudostartvar" ]]; then
                        if [[ "$timenowvar" -lt "$sudoendvar" ]]; then
                                # User can sudo
                                # Build message;
                                echo "You can sudo until $(cat $thisdir/temp/sudont.times.data | cut -c6-7):$(cat $thisdir/temp/sudont.times.data | cut -c8-9) today. It is now $(date)." > $thisdir/temp/msg.data
                                tr -d "\n" < $thisdir/temp/msg.data > $thisdir/temp/msg.out.data
                                echo '' >> $thisdir/temp/msg.out.data
                                cat $thisdir/temp/msg.out.data
                                rm -rf $thisdir/temp/*
                                exit 0
                        else
                                # User cannot sudo at this time
                                # Build message;
                                echo "Your user can no longer sudo. Your time expired at: $(cat $thisdir/temp/sudont.times.data | cut -c6-7):$(cat $thisdir/temp/sudont.times.data | cut -c8-9) today. It is now $(date)." > $thisdir/temp/msg.data
                                tr -d "\n" < $thisdir/temp/msg.data > $thisdir/temp/msg.out.data
                                echo '' >> $thisdir/temp/msg.out.data
                                cat $thisdir/temp/msg.out.data
                                rm -rf $thisdir/temp/*
                                exit 3
                        fi
                  else
                        # User cannot sudo at this time
                        # Build message;
                        echo "Your user can no longer sudo. Your time expired at: $(cat $thisdir/temp/sudont.times.data | cut -c6-7):$(cat $thisdir/temp/sudont.times.data | cut -c8-9) today. It is now $(date)." > $thisdir/temp/msg.data
                        tr -d "\n" < $thisdir/temp/msg.data > $thisdir/temp/msg.out.data
                        echo '' >> $thisdir/temp/msg.out.data
                        cat $thisdir/temp/msg.out.data
                        #rm -rf $thisdir/temp/*
                        exit 3
                  fi
          else
                # User cannot access on this day;
                echo "Your user cannot sudo on this day. Sorry."
                rm -rf $thisdir/temp/*
                exit 3
          fi
  else
        # User is not available in the db;
        echo "Your user does not have special sudo permissions."
        rm -rf $thisdir/temp/*
        exit 3
  fi


  rm -rf $thisdir/temp/*

exit
