  #Usage:
  # nrfutil sdk-manager toolchain env --json --skip-overhead --ncs-version v3.2.1 \
  # | jq -f ncs-env.jq


def getv($k):
    .env_variables[] | select(.key == $k) | .value;

