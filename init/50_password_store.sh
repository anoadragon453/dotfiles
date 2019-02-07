# Clone password-store passwords.
# TODO: Make more applicable to people installing from github (since we
# currently just ask for a gitlab oauth key...)

# TODO: Only for Linux for now. Need to get pass installed on osx
is_debian || is_ubuntu || return 1

# Stop if password-store is already installed
if [ -d $HOME/.password-store ]
then
  return 1
fi

e_header "Setting up passwordstore... Ensure your GPG keys are set up."
read -p "Enter your GitLab Oauth key: " key; echo
read -p "Enter the repo address (e.g. gitlab.com/bob/my-store): " repo; echo

git clone https://oauth2:$key@$repo $HOME/.password-store
