# 📦 VM/Container Setup Script - Complete Package

## 🎁 What You Got

This package contains everything you need to quickly setup new Debian/Ubuntu VMs and containers:

### Main Files:

1. **setup.sh** (8 KB)
   - Full-featured setup script
   - Installs all requested tools + extras
   - Production-ready with error handling
   - Colorized output and logging

2. **setup-minimal.sh** (1.7 KB)  
   - Lightweight version
   - Just the essentials
   - Faster execution
   - Perfect for CI/CD

3. **verify.sh** (2.8 KB)
   - Post-installation verification
   - Checks all installations
   - Colorized status report

4. **README.md** (4 KB)
   - Complete documentation
   - Hosting options
   - Security best practices
   - Troubleshooting guide

5. **HOSTING_GUIDE.md** (3.4 KB)
   - Step-by-step hosting instructions
   - Comparison of hosting methods
   - Recommendations for different use cases

6. **EXAMPLES.md** (6.9 KB)
   - 15+ real-world usage examples
   - Different platforms (AWS, DigitalOcean, Docker, etc.)
   - CI/CD integration examples

---

## ✅ What Gets Installed

### Core Development Tools:
- ✅ Zsh with Oh My Zsh
- ✅ Node.js (LTS) + npm + npx
- ✅ Python 3 + pip3 + venv
- ✅ uv + uvx (fast Python package manager)
- ✅ Docker + Docker Compose

### Oh My Zsh Plugins:
- git, docker, docker-compose
- npm, node, python, pip
- zsh-autosuggestions
- zsh-syntax-highlighting  
- zsh-completions
- sudo, command-not-found

### Additional Utilities:
- git, curl, wget, vim, htop, tmux
- jq, tree, net-tools, dnsutils
- fzf (fuzzy finder)
- bat (better cat)
- ripgrep (better grep)
- eza (better ls)

---

## 🚀 Quick Start (3 Steps)

### 1. Choose Hosting (Recommended: GitHub Gist)
```bash
# Go to https://gist.github.com
# Create new gist with setup.sh content
# Get the raw URL
```

### 2. Test It
```bash
# Review the script first (ALWAYS!)
curl -fsSL YOUR_URL | less

# Run it
curl -fsSL YOUR_URL | bash
```

### 3. Verify
```bash
# Check everything installed correctly
curl -fsSL YOUR_VERIFY_URL | bash
```

---

## 🎯 Recommended Hosting Strategy

**Quick & Easy (5 minutes):**
- Upload `setup.sh` to GitHub Gist
- Share raw URL with your team
- Done! ✨

**Professional Setup (15 minutes):**
- Create GitHub repo: `your-username/vm-setup`
- Add all files from this package
- Enable GitHub Pages
- Optional: Add custom domain
- Share: `https://your-username.github.io/vm-setup/setup.sh`

**Enterprise Setup (30 minutes):**
- Host on company domain
- Use Cloudflare Pages or similar
- Add to company onboarding docs
- Create short URL: `setup.company.com`

---

## 💡 Best Practices

### Security:
1. **Always review scripts** before running
2. Use HTTPS URLs only
3. Pin versions for production
4. Keep scripts in version control

### Usage:
1. Start with full script on dev machines
2. Use minimal script for CI/CD
3. Run verify script to check installations
4. Customize for your team's needs

### Maintenance:
1. Update Node.js version regularly
2. Test script monthly
3. Keep documentation current
4. Monitor security advisories

---

## 🔧 Customization Ideas

### Add to setup.sh:
- Your company's internal tools
- Specific language versions (Go, Rust, etc.)
- Cloud CLI tools (AWS, GCP, Azure)
- Your dotfiles repository
- Custom Zsh themes
- IDE configurations

### Example Addition:
```bash
# Add to setup.sh after Python installation
log_info "Installing Go..."
wget https://go.dev/dl/go1.21.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
```

---

## 📊 Script Comparison

| Feature | setup.sh | setup-minimal.sh |
|---------|----------|------------------|
| Size | 8 KB | 1.7 KB |
| Install Time | ~5-10 min | ~3-5 min |
| Error Handling | ✅ Full | ⚠️ Basic |
| Colorized Output | ✅ Yes | ❌ No |
| Extra Tools | ✅ fzf, bat, ripgrep | ❌ No |
| Logging | ✅ Detailed | ❌ Minimal |
| **Best For** | Development machines | CI/CD, containers |

---

## 🎓 Learning Resources

### Zsh & Oh My Zsh:
- https://github.com/ohmyzsh/ohmyzsh
- https://github.com/zsh-users

### Docker:
- https://docs.docker.com

### uv (Python):
- https://github.com/astral-sh/uv

### Node.js:
- https://nodejs.org

---

## 🐛 Common Issues & Solutions

**"Permission denied" errors:**
```bash
chmod +x setup.sh
./setup.sh
```

**Docker permission denied:**
```bash
# Log out and back in after script runs
# Or run: newgrp docker
```

**Zsh not default shell:**
```bash
chsh -s $(which zsh)
# Then log out/in
```

**uv not found:**
```bash
source ~/.zshrc
# Or: export PATH="$HOME/.cargo/bin:$PATH"
```

---

## 📞 Next Steps

1. ✅ Review the scripts
2. ✅ Choose a hosting method (see HOSTING_GUIDE.md)
3. ✅ Upload and get your URL
4. ✅ Test on a VM/container
5. ✅ Share with your team
6. ✅ Add to documentation

---

## 🎉 You're All Set!

You now have:
- ✅ Production-ready setup scripts
- ✅ Complete documentation
- ✅ Real-world examples
- ✅ Hosting guide
- ✅ Verification tools

**Time to deploy!** 🚀

Questions? Check the README.md or EXAMPLES.md for more details.

---

*Created with ❤️ for faster VM/container setup*
