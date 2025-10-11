


# Create a file with the PAT
token=$1
filename=PAT-"$(date -I)"
touch $filename && echo "$1" > $filename

# Use Bitwarden CLI to attach the file to the item
bw create attachment --file ./$filename --itemid ae829f3b-2c91-445a-8e9f-b332003d7b27
bw sync

