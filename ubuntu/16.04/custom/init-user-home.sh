#!/bin/bash
echo "Clone dotfiles repository from GitHub"
git clone https://github.com/jms1989/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/install.sh
echo "done."
rm -f $0
exit

