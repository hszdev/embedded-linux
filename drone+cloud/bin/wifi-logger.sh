#!/bin/sh

DATABASE_PATH="$HOME/flights.db"

# Create the table if it doesnt exist
sqlite3 $DATABASE_PATH <<'END_SQL'
CREATE TABLE IF NOT EXISTS flight_logs (id LONG PRIMARY KEY, connection_strength INTEGER);
END_SQL

# Keep running till the script is interrupted.
while true; do

# Take the first wifi in the list and extract the value using tail, cut and sed
STRENGTH=$(cat /proc/net/wireless | tail -n +3 | cut -f 5 -d" " | sed "s/\.//g")

if [ -z "$STRENGTH" ]; then 

    echo "No internet data."

else 
    # Create the sql state using string interpolation
    SQL_STATEMENT="INSERT INTO flight_logs (id, connection_strength) VALUES ($(date +%s), $STRENGTH);"

    # Run the command
    sqlite3 $DATABASE_PATH <<< $SQL_STATEMENT;

    echo "Inserted at $(date +%s) with value $STRENGTH";

fi

# sleep for one second
sleep 1;


done
