#!/bin/bash

# TODO explain args
# Accepted args: --schedule=value

sources() {
  local script_folder="$( dirname "$(realpath -s "${BASH_SOURCE[0]}")" )"

  source "$script_folder/../common/args.sh" "$@"
  source "$script_folder/../common/vars.sh"
  source "$script_folder/../common/utils.sh"

}; sources "$@"

check_schedule_arg

setup_log_file "${schedule:-"manual"}-push"

push_submodule() {
  cd "$PRIVATE_FOLDER" || return 
  git pull --quiet

  local message="$PRJ_DISPLAY manual push"
  [[ "$schedule" ]] \
      && local message="$PRJ_DISPLAY auto $schedule push"

  echo "Pushing changes in [ private ] submodule..."
  git add . && git commit . -m "$message"
  git push
}

push_main() {
  cd "$PROJECT_ROOT" || return
  git pull --quiet

  local message="$PRJ_DISPLAY private repo revision update"

  echo -e "\nPushing changes in main folder..."
  git add . && git commit . -m "$message"
  git push
}

check_git_props
push_submodule
push_main
