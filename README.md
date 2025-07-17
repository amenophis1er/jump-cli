# Jump CLI

**Enhanced Directory Shortcut Manager** - Navigate your projects efficiently.

Jump CLI is a powerful command-line tool that lets you create shortcuts to your frequently used directories with optional actions. Eliminate the need for typing long paths and enable instant navigation to your projects.

## Requirements

- **Shell**: Bash 4.0+ or Zsh
- **OS**: macOS, Linux, or Windows (via WSL)
- **Dependencies**: Standard Unix utilities (grep, cut, sed)

## Features

- **Quick Navigation** - Jump to any directory with a simple shortcut
- **Custom Actions** - Run commands automatically when jumping (activate venv, git status, etc.)
- **Fuzzy Search** - Find shortcuts even with partial names
- **Colored Output** - Clear, readable terminal output
- **Statistics** - Track your shortcuts usage
- **Backup/Restore** - Export and import your shortcuts
- **Easy Management** - Add, update, remove shortcuts effortlessly

## Installation

### Quick Install (Recommended)

**Install from latest stable release:**

```bash
curl -fsSL https://github.com/amenophis1er/jump-cli/releases/latest/download/install.sh | bash
```

### Alternative Installation Methods

**Install from main branch (development version):**

```bash
curl -fsSL https://raw.githubusercontent.com/amenophis1er/jump-cli/main/install.sh | bash
```

**Manual installation:**

```bash
git clone https://github.com/amenophis1er/jump-cli.git
cd jump-cli
chmod +x install.sh
./install.sh
```

## Quick Start

```bash
# Add your first shortcut
j add myproject ~/path/to/project

# Jump to it
j myproject

# Add a shortcut with an action
j add server ~/server 'source venv/bin/activate'

# Jump and run the action
j server run
```

## Command Reference

### Navigation Commands
- `j <name>` - Jump to directory
- `j <name> run` - Jump to directory and execute stored action
- `j <name> action` - Same as run
- `j <name> do` - Same as run

### Shortcut Management
- `j add <name> <path> [action]` - Create a new shortcut
- `j update <name> <path> [action]` - Update an existing shortcut
- `j remove <name>` or `j rm <name>` - Delete a shortcut
- `j list` or `j ls` - Display all shortcuts
- `j search <query>` or `j find <query>` - Search shortcuts (fuzzy matching)

### Advanced Commands
- `j edit` - Open shortcuts file in default editor
- `j stats` - Display usage statistics
- `j export [filename]` - Export shortcuts to file (default: jump_shortcuts_backup.txt)
- `j import <filename>` - Import shortcuts from file
- `j help` or `j --help` or `j -h` - Show help
- `j version` or `j --version` or `j -v` - Show version

### Action Syntax

Actions support any shell command. Use single quotes to prevent premature expansion:

```bash
# Single command
j add myproject ~/project 'npm start'

# Multiple commands (use semicolons or &&)
j add fullstack ~/app 'cd frontend; npm start'
j add server ~/backend 'source venv/bin/activate && python app.py'

# Complex commands with pipes
j add logs ~/logs 'tail -f app.log | grep ERROR'
```

## Examples

### Development Workflow
```bash
# Add your main projects
j add frontend ~/Projects/my-app/frontend 'npm install && npm start'
j add backend ~/Projects/my-app/backend 'source venv/bin/activate'
j add docs ~/Projects/my-app/docs 'mkdocs serve'

# Quick navigation
j frontend          # Jump to frontend
j backend run       # Jump to backend AND activate virtual environment
j docs run          # Jump to docs AND start documentation server
```

### Project Management
```bash
# Add project with git status check
j add webapp ~/code/webapp 'git status && git pull'

# Jump and automatically check status
j webapp run
```

## How It Works

Jump CLI creates two simple files:
- `~/.jump_shortcuts` - Your shortcuts database
- `~/.jump_config` - Configuration settings

The `j` command is a shell function that:
1. Manages shortcuts through the `jump` binary
2. Changes directories seamlessly
3. Executes optional actions when requested

## Output Example

```
$ j list
Available shortcuts:
  frontend        -> /Users/dev/Projects/my-app/frontend [npm start]
  backend         -> /Users/dev/Projects/my-app/backend [source venv/bin/activate]
  docs            -> /Users/dev/Projects/my-app/docs [mkdocs serve]

$ j frontend
📁 /Users/dev/Projects/my-app/frontend

$ j backend run
📁 /Users/dev/Projects/my-app/backend
Virtual environment activated!
```

## Configuration

Jump CLI stores its data in:
- `~/.jump_shortcuts` - Your shortcuts database
- `~/.jump_config` - Configuration settings (reserved for future features)

To manually edit shortcuts:
```bash
j edit              # Opens in your default editor
```

Shortcut format in the file:
```
name:path:action
```

## Uninstallation

To remove Jump CLI completely:

```bash
# From latest release
curl -fsSL https://github.com/amenophis1er/jump-cli/releases/latest/download/uninstall.sh | bash

# Or from main branch
curl -fsSL https://raw.githubusercontent.com/amenophis1er/jump-cli/main/uninstall.sh | bash
```

## Troubleshooting

### Common Issues

**"Command not found: j"**
- Restart your terminal or run: `source ~/.bashrc` (or `~/.zshrc` for zsh)
- Verify installation: `type j` should show the function definition
- Check PATH: `echo $PATH` should include `~/bin`

**"jump: command not found"**
- Ensure `~/bin/jump` exists and is executable: `ls -la ~/bin/jump`
- Reinstall if missing: `curl -fsSL https://github.com/amenophis1er/jump-cli/releases/latest/download/install.sh | bash`

**Shortcuts not persisting**
- Check file permissions: `ls -la ~/.jump_shortcuts`
- Verify file isn't corrupted: `cat ~/.jump_shortcuts`

**Actions not executing**
- Use single quotes for complex commands: `j add project ~/project 'cd && npm start'`
- Check action syntax: `j list` shows actions in brackets
- Test action manually first to ensure it works

**Fuzzy search not working**
- Fuzzy search is automatic when exact match isn't found
- Search command uses grep patterns: `j search "web.*app"`

### Shell Compatibility

**Bash**
- Fully supported (4.0+)
- Works with `.bashrc` or `.bash_profile`

**Zsh**
- Fully supported
- Works with `.zshrc`

**Other Shells**
- Basic support via `.profile`
- Some features may be limited

## Platform Notes

### macOS
- Works with Terminal, iTerm2, and other terminal emulators
- Tested on macOS 10.15+

### Linux
- Compatible with all major distributions
- Tested on Ubuntu, Debian, Fedora, Arch

### Windows
- Requires WSL (Windows Subsystem for Linux)
- Not compatible with Command Prompt or PowerShell
- Use WSL terminal for full functionality

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/amenophis1er/jump-cli/issues)
- **Discussions**: [GitHub Discussions](https://github.com/amenophis1er/jump-cli/discussions)
- **Email**: jump-cli@amouzou.net

---

**Author**: [Amen AMOUZOU](https://github.com/amenophis1er)

**Repository**: https://github.com/amenophis1er/jump-cli
