#!/bin/zsh


cd ~

echo "Add tools"
ln -s ~/devspaces-configuration/tools ~/tools

echo "Install OMZSH"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "Install fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc

echo "Install zsh syntax highlighting"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting


echo "Install starship"
mkdir ~/bin
curl -sS https://starship.rs/install.sh | sh -s -- -b ~/bin --yes

source ~/.zshrc

# echo "Install Mise"
# curl https://mise.run | sh


echo "Configure Claude"
ada profile add --account 972842349728 --profile claude-test --provider isengard --region us-west-2 --role Admin
npm install -g @anthropic-ai/claude-code
toolbox install mcp-registry
mcp-registry install builder-mcp

echo "Install Chezmoi"
sh -c "$(curl -fsLS get.chezmoi.io)"
# sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply benjsnellings 


echo "Init Chezmoi"
./bin/chezmoi init --apply benjsnellings


echo "Chezmoi Devspace Customization"
output_file="~/.local/share/chezmoi/.chezmoidata.json"
touch ~/.local/share/chezmoi/.chezmoidata.json

 cat > ~/.local/share/chezmoi/.chezmoidata.json << EOF
{
  "devspace": "true"
}
EOF

./bin/chezmoi apply


echo "ReSource"
# zsh
# source ~/.zshrc
