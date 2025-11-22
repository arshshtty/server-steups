# VM/Container Quick Setup Script

A comprehensive setup script for quickly configuring new Debian/Ubuntu virtual machines and containers with essential development tools.

## 🚀 Quick Start

### One-line installation (once hosted):

```bash
# Using curl
curl -fsSL https://your-domain.com/setup.sh | bash

# Using wget
wget -qO- https://your-domain.com/setup.sh | bash
```

### Local usage:

```bash
chmod +x setup.sh
./setup.sh
```

## 📦 What Gets Installed

### Core Tools
- ✅ **Zsh** with Oh My Zsh
- ✅ **Oh My Zsh plugins**: git, docker, docker-compose, npm, node, python, pip, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, sudo, command-not-found
- ✅ **Node.js** (LTS version) + npm + npx
- ✅ **Python3** + pip3 + venv
- ✅ **uv** (Fast Python package installer) + uvx
- ✅ **Docker** + Docker Compose (both plugin and standalone)

### Additional Utilities
- git, curl, wget, vim
- htop, tmux, tree, jq
- fzf (fuzzy finder)
- bat (better cat)
- ripgrep (better grep)
- eza (better ls, if available)
- net-tools, dnsutils, zip/unzip

## 🌐 Hosting Options

### Option 1: GitHub Gist (Easiest)
1. Create a new gist at https://gist.github.com
2. Upload `setup.sh`
3. Click "Raw" and use that URL

**Usage:**
```bash
curl -fsSL https://gist.githubusercontent.com/USERNAME/GIST_ID/raw/setup.sh | bash
```

### Option 2: GitHub Repository
1. Create a public repository
2. Push `setup.sh` to the repo
3. Use the raw.githubusercontent.com URL

**Usage:**
```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | bash
```

### Option 3: Custom Domain (Professional)

Host on your own domain using:
- **GitHub Pages**: Free, easy, use the repo method above with custom domain
- **Cloudflare Pages**: Free, fast CDN
- **Netlify**: Free tier available
- **Your own server**: nginx/Apache with HTTPS

**Example nginx config:**
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location /setup.sh {
        alias /var/www/scripts/setup.sh;
        add_header Content-Type text/plain;
        add_header Cache-Control "no-cache";
    }
}
```

### Option 4: Pastebin-style Services
- **paste.sh**: `curl -F'file=@setup.sh' https://paste.sh`
- **ix.io**: `cat setup.sh | curl -F 'f:1=<-' ix.io`

⚠️ **Security Note**: These services are less permanent and secure than GitHub

## 🔒 Security Best Practices

### For Script Authors:
1. Always use HTTPS URLs
2. Sign your scripts (GPG)
3. Provide checksums (SHA256)
4. Keep scripts in version control

### For Users:
1. **Never run scripts blindly!** Always review first:
   ```bash
   curl -fsSL https://your-domain.com/setup.sh | less
   ```
2. Download and inspect before running:
   ```bash
   curl -fsSL https://your-domain.com/setup.sh -o setup.sh
   less setup.sh
   chmod +x setup.sh
   ./setup.sh
   ```
3. Verify checksums if provided

## 🛠️ Customization

Edit the script to:
- Add/remove packages in the `apt-get install` sections
- Modify Zsh plugins in the `sed` command
- Change Node.js version (modify the NodeSource URL)
- Add your own dotfiles or configurations

## 📝 Post-Installation

After running the script:

1. **Reload your shell** or log out/in:
   ```bash
   source ~/.zshrc
   # or
   zsh
   ```

2. **Verify Docker permissions** (non-root users):
   ```bash
   # May need to log out/in first
   docker run hello-world
   ```

3. **Test installations**:
   ```bash
   node --version
   npm --version
   python3 --version
   uv --version
   docker --version
   docker-compose --version
   ```

## 🐛 Troubleshooting

**Zsh not default shell?**
```bash
chsh -s $(which zsh)
```

**Docker permission denied?**
```bash
sudo usermod -aG docker $USER
# Then log out and back in
```

**uv not in PATH?**
```bash
export PATH="$HOME/.cargo/bin:$PATH"
source ~/.zshrc
```

## 📋 Requirements

- Debian 10+ or Ubuntu 20.04+
- Internet connection
- sudo access (or root)

## 🤝 Contributing

Feel free to fork and customize for your needs!

## 📄 License

MIT License - use freely!
