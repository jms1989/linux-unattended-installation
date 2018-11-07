#!/bin/bash
echo "Clone dotfiles repository from GitHub"
git clone https://gitlab.com/jms1989/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/install.sh
touch ~/.sudo_as_admin_successful
echo "done."
rm -f $0
exit
