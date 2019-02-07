# Homebrew installs python2 pip as "pip2"
for pip2_cmd in pip2 pip FAIL; do [[ "$(which $pip2_cmd)" ]] && break; done
for pip3_cmd in pip3 pip FAIL; do [[ "$(which $pip3_cmd)" ]] && break; done

# Exit if pip is not installed.
[[ $pip_cmd == FAIL ]] && e_error "Python 2 & 3 pip needs to be installed." && return 1

# Add pip packages
pip2_packages=(
  msgpack 		# zeronet
  gevent 		# zeronet
  psutil
  tmuxp
)

pip3_packages=(
)

installed_pip2_packages="$($pip2_cmd list 2>/dev/null | awk '{print $1}')"
installed_pip3_packages="$($pip3_cmd list 2>/dev/null | awk '{print $1}')"
pip2_packages=($(setdiff "${pip2_packages[*]}" "$installed_pip2_packages"))
pip3_packages=($(setdiff "${pip3_packages[*]}" "$installed_pip3_packages"))

if (( ${#pip2_packages[@]} > 0 )); then
  e_header "Installing pip2 packages (${#pip2_packages[@]})"
  for package in "${pip2_packages[@]}"; do
    e_arrow "$package"
    $pip2_cmd install "$package"
  done
fi

if (( ${#pip3_packages[@]} > 0 )); then
  e_header "Installing pip3 packages (${#pip3_packages[@]})"
  for package in "${pip3_packages[@]}"; do
    e_arrow "$package"
    $pip3_cmd install "$package"
  done
fi
