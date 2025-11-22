# 🎯 Quick Examples & Common Scenarios

## Example 1: Fresh Ubuntu VM on DigitalOcean

```bash
# SSH into your new droplet
ssh root@your-server-ip

# Run the setup script (using your hosted URL)
curl -fsSL https://gist.githubusercontent.com/YOUR_USERNAME/HASH/raw/setup.sh | bash

# Verify installation
curl -fsSL https://gist.githubusercontent.com/YOUR_USERNAME/HASH/raw/verify.sh | bash

# Start using Zsh
zsh
```

## Example 2: Docker Container Setup

```dockerfile
FROM ubuntu:22.04

# Install prerequisites
RUN apt-get update && apt-get install -y curl sudo

# Run setup script
RUN curl -fsSL https://your-url.com/setup.sh | bash

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]
```

## Example 3: LXC Container

```bash
# Create container
lxc launch ubuntu:22.04 dev-container

# Enter container
lxc exec dev-container -- bash

# Run setup
curl -fsSL https://your-url.com/setup.sh | bash

# Exit and re-enter with zsh
exit
lxc exec dev-container -- zsh
```

## Example 4: WSL2 (Windows Subsystem for Linux)

```bash
# Open Ubuntu from WSL
wsl

# Run setup
curl -fsSL https://your-url.com/setup.sh | bash

# Restart WSL
exit
wsl --shutdown
wsl

# Should now be in Zsh
```

## Example 5: Vagrant VM

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  
  config.vm.provision "shell", inline: <<-SHELL
    curl -fsSL https://your-url.com/setup.sh | bash
  SHELL
  
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    # Run as user (for Oh My Zsh)
    curl -fsSL https://your-url.com/setup.sh | bash
  SHELL
end
```

## Example 6: GitHub Codespaces

Create `.devcontainer/devcontainer.json`:

```json
{
  "name": "Development Container",
  "image": "ubuntu:22.04",
  "postCreateCommand": "curl -fsSL https://your-url.com/setup.sh | bash",
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.defaultProfile.linux": "zsh"
      }
    }
  }
}
```

## Example 7: Ansible Playbook

```yaml
---
- name: Setup development environment
  hosts: all
  become: yes
  tasks:
    - name: Download and run setup script
      shell: curl -fsSL https://your-url.com/setup.sh | bash
      args:
        executable: /bin/bash
```

## Example 8: Terraform with Cloud-Init

```hcl
resource "aws_instance" "dev_server" {
  ami           = "ami-ubuntu-22.04"
  instance_type = "t3.micro"
  
  user_data = <<-EOF
              #!/bin/bash
              curl -fsSL https://your-url.com/setup.sh | bash
              EOF
  
  tags = {
    Name = "dev-server"
  }
}
```

## Example 9: Multipass (Local VMs)

```bash
# Launch VM with cloud-init
multipass launch --name dev-vm --cloud-init - <<EOF
#cloud-config
runcmd:
  - curl -fsSL https://your-url.com/setup.sh | sudo bash
EOF

# Enter the VM
multipass shell dev-vm
```

## Example 10: Minimal Setup for CI/CD

```bash
# Use the minimal script for faster builds
curl -fsSL https://your-url.com/setup-minimal.sh | bash

# Or install only what you need
curl -fsSL https://your-url.com/setup.sh | bash -s -- --skip-zsh --skip-extras
```

## Example 11: Team Onboarding

Create a custom onboarding script:

```bash
#!/bin/bash
# company-setup.sh

# Run base setup
curl -fsSL https://your-url.com/setup.sh | bash

# Clone company repos
git clone https://github.com/company/repo1.git ~/projects/repo1
git clone https://github.com/company/repo2.git ~/projects/repo2

# Install company-specific tools
npm install -g @company/cli-tool

# Setup company dotfiles
curl -fsSL https://company-dotfiles.com/.zshrc >> ~/.zshrc

echo "🎉 Welcome to the team!"
```

## Example 12: Quick Test Before Deployment

```bash
# Test in a temporary Docker container
docker run -it --rm ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y curl &&
  curl -fsSL https://your-url.com/setup.sh | bash &&
  zsh -c 'node --version && python3 --version && docker --version'
"
```

## Example 13: Update Existing System

The script is idempotent - safe to run multiple times:

```bash
# Update your setup
curl -fsSL https://your-url.com/setup.sh | bash

# It will:
# - Skip already installed packages
# - Update Oh My Zsh plugins
# - Upgrade system packages
```

## Example 14: Custom Alias

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Quick VM setup alias
alias vm-setup='curl -fsSL https://your-url.com/setup.sh | bash'

# Then just run:
vm-setup
```

## Example 15: Verify Installation Remotely

```bash
# SSH and verify in one command
ssh user@server "curl -fsSL https://your-url.com/verify.sh | bash"
```

---

## 🔧 Environment-Specific Tips

### For Production Servers:
- Review the script first
- Use the minimal version
- Skip Oh My Zsh if not needed
- Consider security hardening

### For Development Machines:
- Use the full version
- Customize Oh My Zsh theme
- Add your personal dotfiles
- Install language-specific tools

### For CI/CD:
- Cache dependencies
- Use the minimal script
- Pin versions for reproducibility
- Skip interactive tools

### For Containers:
- Use multi-stage builds
- Minimize layer size
- Consider Alpine alternatives
- Remove build dependencies

---

## 💡 Pro Tips

1. **Version pinning**: Fork the script and pin tool versions for consistency
2. **Custom domains**: Use `setup.yourdomain.com` for branding
3. **Short URLs**: Create `vm.yourdomain.com` that redirects
4. **QR codes**: Generate a QR code for mobile access
5. **Documentation**: Keep a wiki of your custom setup procedures

---

Need more examples? Check the README.md for detailed information!
