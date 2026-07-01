
This file contatins generic information about how to work with amazon packages. @steering/amazon-builder-steering.md
This file contains instructions for git and code review operations. @steering/git-steering.md
This file contains more spcific context for my workflows. It takes precedence over the generic information. @steering/snellin-steering.md

My dotfiles are managed by chezmoi. Before editing or creating ANY file under `~` (including `~/.claude/*`), you MUST use the `editing-chezmoi-dotfiles` skill to check whether it is managed and edit it correctly — never edit an applied target that will be reverted, and never clobber a template.
