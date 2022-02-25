# AutoBrew

AutoBrew.sh makes Homebrew deployments simple, easy, and automated.

##### Disclaimer
"Running/Installing Homebrew as root is extremely dangerous and no longer supported using the official Homebrew installation method."

### How to install Homebrew using AutoBrew.sh with Munki or Manually
Simply run this script using Munki to install Homebrew as the currently logged in user, or you can run the script directly from the command line as follows:

`sudo /bin/sh /path/to/AutoBrew.sh`

You can also run this script with an argument containing the username to install homebrew for any predefined user:

`sudo /bin/sh /path/to/AutoBrew.sh "username"`

### How to install Homebrew using Jamf

#### Using the Logged In User
Simply run this script using Jamf to install Homebrew as the currently logged in user, specified by Jamf as the 3rd argument when the script is run.

This user will then be able to install formulae with `brew install` and manage Homebrew with other `brew` commands.

#### Specific User
If you want to utilize a *specific* user for Homebrew (rather than the currently logged in user) this user can be specified in Jamf using a parameter value in the script payload for your policy. As parameters 1-3 are predefined (as mount point, computer name, and current username) the specified username would be given as the 4th parameter.

This is useful in a scenario where you want to use a specific *local admin* user to manage Homebrew, but want to allow *standard* users to utilize formulae that you manage.

With this implementation, **all** users that add the *Homebrew Bin Path* to their PATH will be able to utilize the scripts & binaries that are installed by Homebrew, but only the **specified** user will be able to install formulae with `brew install` and manage Homebrew with other `brew` commands.  *Note that other **admin** users would be able to "hijack" Homebrew by using `chown`, therefore this implementation is best used in an environment where your users are not administrators.*





