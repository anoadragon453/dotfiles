# Declare a dictionary
declare -A aliases
aliases=(
  ["het"]="mosh --ssh=\"ssh -i ~/.ssh/hetzner\" root@5.9.9.18"
)

for key in ${#aliases[@]}
do
  alias key=${aliases[key]}
done
