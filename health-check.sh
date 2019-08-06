#!/bin/sh

DIR="$( cd "$(dirname "$0")" ; pwd -P )"
VARS="$(echo "${DIR}"/vars)"

while read f1 f2
do
  RESPONSE="$(systemctl is-active --quiet "${f1}".service && echo true)"

  if [ "${RESPONSE}" = "true" ]; then
    curl --retry 3 "${f2}"
  else
    curl --retry 3 "${f2}"/fail
  fi
  sleep 3s
done < "${VARS}"
