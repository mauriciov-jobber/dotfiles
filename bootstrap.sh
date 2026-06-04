#!/bin/bash
set -euo pipefail

mkdir -p ${HOME}/.local/bin

rm -rf "${HOME}/.zgen"
git clone --depth 1 https://github.com/tarjoilija/zgen.git "${HOME}/.zgen"
rm -rf "${HOME}/.zgen/.git"

mise trust ~/.dotfiles

mise use -p ${HOME}/.config/mise/conf.d/000-bootstrap.toml chezmoi

mise exec -- chezmoi init https://github.com/mauriciov-jobber/dotfiles
mise exec -- chezmoi apply

rm -f ${HOME}/.config/mise/conf.d/000-bootstrap.toml
