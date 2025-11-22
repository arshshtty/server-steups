# Changelog

All notable changes to the VM/Container Setup Script will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### To Do
- [ ] Add support for ARM architecture
- [ ] Add PostgreSQL/MySQL option
- [ ] Add Redis option
- [ ] Create macOS version
- [ ] Add Terraform version
- [ ] Add support for Alpine Linux

---

## [1.0.0] - 2024-11-09

### Initial Release

#### Added
- Full-featured setup script (setup.sh)
- Minimal setup script (setup-minimal.sh)
- Verification script (verify.sh)
- Comprehensive documentation (README.md)
- Hosting guide (HOSTING_GUIDE.md)
- Usage examples (EXAMPLES.md)
- Quick reference card (QUICK_REFERENCE.txt)

#### Core Tools
- Node.js LTS with npm and npx
- Python 3 with pip3 and venv
- uv (fast Python package installer)
- Docker and Docker Compose
- Zsh with Oh My Zsh

#### Zsh Plugins
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions
- git, docker, docker-compose, npm, node, python, pip
- sudo, command-not-found

#### Additional Utilities
- git, curl, wget, vim
- htop, tmux, jq, tree
- fzf (fuzzy finder)
- bat (better cat)
- ripgrep (better grep)
- eza (better ls)
- net-tools, dnsutils, zip/unzip

#### Features
- Colored output and logging
- Error handling with set -e
- Idempotent (safe to run multiple times)
- Works with and without sudo
- Automatic Docker group assignment
- Shell configuration updates
- System package updates and cleanup

---

## Version History Template

Use this template when you make changes:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Features that will be removed in upcoming releases

### Removed
- Features that were removed

### Fixed
- Bug fixes

### Security
- Security fixes or improvements
```

---

## Examples of Future Updates

### [1.1.0] - Future
#### Added
- Support for Debian 12 (Bookworm)
- AWS CLI installation option
- GitHub CLI (gh) installation
- Starship prompt as alternative to Oh My Zsh theme

#### Changed
- Updated Node.js to v22 LTS
- Improved error messages
- Faster Docker installation method

#### Fixed
- Fixed zsh plugin loading on first run
- Corrected path issues with uv on ARM systems

---

### [1.0.1] - Future
#### Fixed
- Fixed compatibility issue with Ubuntu 24.04
- Corrected Oh My Zsh plugin configuration order

#### Security
- Updated Docker GPG key handling
- Improved script download verification

---

## How to Version

**MAJOR.MINOR.PATCH**

- **MAJOR** (1.x.x): Breaking changes, incompatible with previous versions
  - Example: Removing support for Ubuntu 18.04
  
- **MINOR** (x.1.x): New features, backward compatible
  - Example: Adding Go language support
  
- **PATCH** (x.x.1): Bug fixes, backward compatible
  - Example: Fixing a broken download URL

---

## Maintaining This File

1. Update this file whenever you make changes
2. Keep entries in reverse chronological order (newest first)
3. Group changes by type (Added, Changed, Fixed, etc.)
4. Include dates in YYYY-MM-DD format
5. Add links to GitHub issues/PRs if applicable
6. Be concise but descriptive

---

## Links

- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Repository](https://github.com/yourusername/vm-setup)
- [Issues](https://github.com/yourusername/vm-setup/issues)

---

*Last updated: 2024-11-09*
