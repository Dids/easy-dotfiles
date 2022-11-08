#!/bin/bash

sources() {
  local script_folder="$( dirname "$(realpath -s "${BASH_SOURCE[0]}")" )"
  
  source "$script_folder/../common/vars.sh"
  source "$script_folder/../common/utils.sh"

}; sources

setup_log_file "git-setup"

check_additional_repo() {
  echo "Checking if $PRJ_DISPLAY private repo is already configured..."

  cd "$PROJECT_ROOT" && git pull --quiet

  cd "$PRIVATE_FOLDER"
  test "$(git rev-parse --show-superproject-working-tree)" || return 1
}

display_new_repo_help() {
  local help="
    You need to manually create a separate 'private' repository in your git provider account:
    dotfiles-private

    ❗Important: Please make sure that the repo is not empty (check the 'Add a README file' option).

    Official guide on how to create repositories on github: 
    https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
  "

  echo "$help" | sed "s/^[ ]*//"
}

configure_additional_repo() {
  cd "$PROJECT_ROOT"

  local main_repo_url="$(git ls-remote --get-url)"
  local expected_private_url="${main_repo_url%%/*}/dotfiles-private"

  echo "Please provide the repositoy URL for <dotfiles-private>."
  echo "The repo needs to be already created and the URL should look like: "
  echo "$expected_private_url"
  echo
  echo "Enter the URL for <dotfiles-private> repo"
  read -p "[ or press Enter to use '$expected_private_url' ]: " provided_url

  local repo="${provided_url:-"$expected_private_url"}"
  
  rm -rf private && git submodule add --force "$repo" private
}

handle_additional_repo_data() {
  local branches=( $(list_branches) ) && [[ "${#branches[@]}" -gt 1 ]] && return

  cd "$PRIVATE_FOLDER" && is_empty_folder config || return

  echo -e "\nIt seems that $PRJ_DISPLAY private configuration is empty."
  echo -e "It's recommended to use the 'sample' data for initializing your configuration.\n"

  local message="Do you want to use the 'sample' data for initializing your private repo?"
  confirm_action "$message" || return

  cd "$PROJECT_ROOT" && ./sample/setup.sh
}

list_branches() {
  cd "$PRIVATE_FOLDER"

  git branch -r | awk '{ print $1 }' | sed -e '1d' -e 's/origin\///'
}

create_branch() {
  local name="$1"
  echo -e "\nCreating new branch [ $name ] for private repo..."

  check_git_props

  cd "$PRIVATE_FOLDER" && git switch --force-create "$name"
  git push --set-upstream origin "$name"
}

switch_branch() {
  local name="$1";
  echo -e "\nSwitching branch to [ $name ] for private repo..."

  cd "$PRIVATE_FOLDER" && git switch "$name"
}

default_submodule_profile() {
  local default_branch="$(LC_ALL=C git remote show origin | sed -n '/HEAD branch/s/.*: //p')"

  switch_branch "$default_branch"
}

submodule_profile_check() {
  cd "$PRIVATE_FOLDER"; local profile="$(git branch --show-current)"

  [[ "$profile" ]] \
      && echo -e "\nCurrent profile for $PRJ_DISPLAY private data is: [ $profile ]" \
      && return

  echo -e "\n[ WARN ] There's no profile set for the private repo. Will use default..."
  default_submodule_profile
}

display_profiles() {
  echo -e "\nCreating the $PRJ_DISPLAY profiles list..."
  PROFILES_ARRAY=( $(list_branches) )

  echo "Profiles list for $PRJ_DISPLAY private data:"
  printf "[ %s ]\n" "${PROFILES_ARRAY[@]}"

  submodule_profile_check
}

create_new_profile() {
  local message="Do you want to create and use a new profile for this $PRJ_DISPLAY installation?"
  echo; confirm_action "$message" || return 1

  read -p "Enter the new $PRJ_DISPLAY profile name: " new_profile

  create_branch "$new_profile"
}

switch_profile() {
  local message="Do you want to switch to another profile for this $PRJ_DISPLAY installation?"
  echo; confirm_action "$message" || return 1

  echo "Select the desired $PRJ_DISPLAY profile:"
  select profile in "${PROFILES_ARRAY[@]}"; do 
    [[ "$profile" ]] && break || echo "Please input a valid number!"
  done

  switch_branch "$profile"
}

push_git_changes() {
  local message="Do you want to push your git configuration changes?"
  echo; confirm_action "$message" || return

  echo -e "\nPushing the git configuration changes..."

  cd "$PROJECT_ROOT" && ./scripts/git/push.sh
}

check_additional_repo \
    || { display_new_repo_help; configure_additional_repo; }

handle_additional_repo_data

display_profiles
create_new_profile || switch_profile

push_git_changes
