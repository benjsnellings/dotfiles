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
curl -fsSL https://claude.ai/install.sh | bash
claude update
toolbox install mcp-registry
mcp-registry install builder-mcp
claude mcp add -s user builder-mcp -- builder-mcp --include-tools 'ReadInternalWebsites, InternalSearch, InternalCodeSearch, BrazilBuildAnalyzerTool, GetSoftwareRecommendation, SearchSoftwareRecommendations, Taskei*'
aim skills install AmazonBuilderCoreAISkillSet
aim skills install AmazonBuilderGenAIPowerUsersQContext


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


echo "Install host dependencies (jq, aws, Bitwarden CLI, etc.)"
# install-dependencies.sh lives in the repo, so it is only available after
# 'chezmoi init' above cloned it. It installs jq + the Bitwarden CLI (bw),
# which the run_bedrock-aws-profiles-setup.sh script needs to restore the
# bedrock-access-* AWS profiles from Bitwarden.
if [ -f ~/.local/share/chezmoi/install-dependencies.sh ]; then
  ( cd ~/.local/share/chezmoi && ./install-dependencies.sh ) \
    || echo "WARNING: install-dependencies.sh had issues (continuing)"
fi


echo "Restore Bedrock AWS profiles from Bitwarden"
# The first apply above cannot populate ~/.aws because the vault is locked on a
# fresh host. After logging into and unlocking Bitwarden, re-apply to let
# run_bedrock-aws-profiles-setup.sh fetch the keys into ~/.aws:
echo "  -> bw login    # once per host, if not already authenticated"
echo "  -> bwu         # unlock the vault (exports BW_SESSION)"
echo "  -> chezmoi apply   # populates the bedrock-access-* AWS profiles"


echo "ReSource"
# zsh
# source ~/.zshrc
