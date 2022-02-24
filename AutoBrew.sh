#!/bin/sh
# AutoBrew - Install Homebrew with root
# Source: https://github.com/kennyb-222/AutoBrew/
# Author: Kenny Botelho
# Version: 1.2

# Set environment variables
HOME="$(mktemp -d)"
export HOME
export USER=root
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
BREW_INSTALL_LOG=$(mktemp)

# Get current logged in user
TargetUser=$(echo "show State:/Users/ConsoleUser" | \
    scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Check if parameter passed to use pre-defined user
if [ -n "$3" ]; then
    # Supporting running the script in Jamf with no specialization via Self Service
    TargetUser=$3
elif [ -n "$1" ]; then
    # Fallback case for the command line initiated method
    TargetUser=$1
fi

# Ensure TargetUser isn't empty
if [ -z "${TargetUser}" ]; then
    /bin/echo "'TargetUser' is empty. You must specify a user!"
    exit 1
fi

# Verify the TargetUser is valid
if /usr/bin/dscl . -read "/Users/${TargetUser}" 2>&1 >/dev/null; then
    /bin/echo "Validated ${TargetUser}"
else
    /bin/echo "Specified user \"${TargetUser}\" is invalid"
    exit 1
fi

# Verify the TargetUser has admin group
if /usr/bin/id -Gn sysadmin | /usr/bin/grep -q -w admin > /dev/null 2>&1; then
  /bin/echo "${TargetUser} has admin group"
else
  /bin/echo "${TargetUser} does NOT have admin group"
  exit 1
fi

# Install Homebrew | strip out all interactive prompts
/bin/bash -c "$(curl -fsSL \
    https://raw.githubusercontent.com/Homebrew/install/master/install.sh | \
    sed "s/abort \"Don't run this as root\!\"/\
    echo \"WARNING: Running as root...\"/" | \
    sed 's/  wait_for_user/  :/')" 2>&1 | tee "${BREW_INSTALL_LOG}"

# Reset Homebrew permissions for target user
brew_file_paths=$(sed '1,/==> This script will install:/d;/==> /,$d' \
    "${BREW_INSTALL_LOG}")
brew_dir_paths=$(sed '1,/==> The following new directories/d;/==> /,$d' \
    "${BREW_INSTALL_LOG}")
# Get the paths for the installed brew binary
brew_bin=$(echo "${brew_file_paths}" | grep "/bin/brew")
brew_bin_path=${brew_bin%/brew}
# shellcheck disable=SC2086
chown -R "${TargetUser}":admin ${brew_file_paths} ${brew_dir_paths}
chgrp admin ${brew_bin_path}/
chmod g+w ${brew_bin_path}

# Unset home/user environment variables
unset HOME
unset USER

# Finish up Homebrew install as target user
su - "${TargetUser}" -c "${brew_bin} update --force"

# Run cleanup before checking in with the doctor
su - "${TargetUser}" -c "${brew_bin} cleanup"

# Check for post-installation issues with "brew doctor"
doctor_cmds=$(su - "${TargetUser}" -i -c "${brew_bin} doctor 2>&1 | grep 'mkdir\|chown\|chmod\|echo\|&&'")

# Run "brew doctor" remediation commands
if [ -n "${doctor_cmds}" ]; then
    echo "\"brew doctor\" failed. Attempting to repair..."
    while IFS= read -r line; do
        echo "RUNNING: ${line}"
        if [[ "${line}" == *sudo* ]]; then
            # run command with variable substitution
            cmd_modified=$(su - "${TargetUser}" -c "echo ${line}")
            ${cmd_modified}
        else
            # Run cmd as TargetUser
            su - "${TargetUser}" -c "${line}"
        fi
    done <<< "${doctor_cmds}"
fi

# Check Homebrew install status, check with the doctor status to see if everything looks good
if su - "${TargetUser}" -i -c "${brew_bin} doctor"; then
    echo 'Homebrew Installation Complete! Your system is ready to brew.'
    exit 0
else
    echo 'AutoBrew Installation Failed'
    exit 1
fi
