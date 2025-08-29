# Kill current hyprsunset session
killall -q hyprsunset

# Get the current hour (in 24-hour format)
current_hour=$(date +%H)

if [ "$current_hour" -ge 18 ] || [ "$current_hour" -le 6 ]; then
  echo "Changing to nighttime hyprsunset"
  hyprsunset -t 5000
else
  echo "Changing to default hyprsunset"
  hyprsunset -t 6500
fi!/bin/sh

# Kill current hyprsunset session
killall -q hyprsunset

# Get the current hour (in 24-hour format)
current_hour=$(date +%H)

# If it’s 6pm to 7am, hyprsunset -t 5000
# Else hyprsunset -t 6500
if [ "$current_hour" -ge 18 ] || [ "$current_hour" -le 6 ]; then
  echo "Changing to nighttime hyprsunset"
  hyprsunset -t 5000
else
  echo "Changing to default hyprsunset"
  hyprsunset -t 6500
fi
