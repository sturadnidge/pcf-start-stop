#!/bin/bash

# bosh cmd is an alias set in .profile of ops manager user
shopt -s expand_aliases
source ~/.profile

function usage {
  printf "Usage: ${0##*/} (start | stop) [--hard]\n"
  exit 1
}

# @param Array
# @param Element
# @returns 0 if element is in Array, 1 if not
# @example hasIn "${Array[@]}" "Element"
function hasIn {
  local e
  for e in "${1}"
  do
    [[ "$e" == "$2" ]] && return 0
  done
  return 1
}

if [ $# -eq 0 ]
then
  usage
fi

start_time=$(date +%s)
# Get manifest name for this deployment
manifest=$(bosh deployment | awk -F "/" '{ print $7}' | awk -F "." '{ print $1 }')

case $1 in

  'start')
    printf "\nstarting deployment $manifest\n\n"
    bosh -n start
    printf "\nenabling VM resurrection\n\n"
    bosh vm resurrection on
    printf "\nrunning smoke tests\n\n"
    bosh -n run errand smoke-tests
    ;;

  'stop')
    # Get the list of jobs in this deployment
    jobVMs=$(bosh vms --detail | grep -E '^\|.[a-z]' | awk -F '|' '{ print $2 }' | tr -d '[[:blank:]]')
    # Make sure only 1 Consul instance is running
    for y in $jobVMs
    do
      consulIndex=$(echo $y | grep '^consul' | awk -F '/' '{ print $2 }' | awk -F '(' '{ print $1 }')
      if [ $consulIndex ] && [ $consulIndex -ne 0 ]
      then
        printf "\nmore than 1 consul job found, aborting\n\n"
        exit 1
      fi
    done
    # We got here, safe to proceed
    printf "\n1 consul job found, proceeding\n\n"
    printf "disabling VM resurrection\n\n"
    bosh vm resurrection off
    # Stopping a deployment ensures things are shut down in the correct order
    if [ -n "$2" ] && [ "$2" == "--hard" ]
    then
      # Do not allow hard stop if any of these jobs are running
      declare -a protected=(
        mysql
        nfs_server
      )
      printf "\nchecking deployment for protected jobs... "
      for z in $jobVMs
      do
        job=$(echo $z | awk -F "/" '{ print $1 }')
        if hasIn "${protected[@]}" "$job"
        then
          printf "found protected job $job, aborting - no actions have been taken\n\n"
          printf "re-enabling VM resurrection\n\n"
          bosh vm resurrection on
          exit 1
        fi
      done
      # We got here, safe to proceed
      printf "done"
      printf "\n\ndeleting deployment $manifest\n\n"
      bosh -n stop --hard
    else
      # Soft stopping a deployment with internal blobstore / database is OK
      printf "\n\nstopping deployment $manifest\n\n"
      bosh -n stop
    fi
    ;;

  *)
    usage
    ;;

esac

end_time=$(date +%s)
secs=$(($end_time-$start_time))
printf "\nscript took: %02dh:%02dm:%02ds\n\n" $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))
