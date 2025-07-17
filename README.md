# Jump CLI

**Enhanced Directory Shortcut Manager** - Navigate your projects efficiently.

Jump CLI is a powerful command-line tool that lets you create shortcuts to your frequently used directories with optional actions. Eliminate the need for typing long paths and enable instant navigation to your projects.

## Features

- **Quick Navigation** - Jump to any directory with a simple shortcut
- **Custom Actions** - Run commands automatically when jumping (activate venv, git status, etc.)
- **Fuzzy Search** - Find shortcuts even with partial names
- **Colored Output** - Clear, readable terminal output
- **Statistics** - Track your shortcuts usage
- **Backup/Restore** - Export and import your shortcuts
- **Easy Management** - Add, update, remove shortcuts effortlessly

## Installation

**One-liner installation:**

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

## Usage

### Basic Commands

```bash
# Add shortcuts
j add myproject ~/path/to/project
j add web ~/Projects/Web 'ls -la'
j add server ~/server-project 'source venv/bin/activate && echo "Server env ready!"'

# Jump to directories
j myproject          # Jump to project
j web               # Jump to web projects
j server run        # Jump to server project AND run the stored action

# List all shortcuts
j list

# Search shortcuts
j search web

# Remove shortcuts
j remove myproject
```

### Advanced Features

```bash
# Statistics and management
j stats             # Show usage statistics
j export            # Backup shortcuts
j import backup.txt # Restore shortcuts
j edit              # Edit shortcuts file directly

# Get help
j help              # Show full help
j version           # Show version info
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

Jump CLI works out of the box, but you can customize it:

```bash
# Edit shortcuts directly
j edit

# View configuration
j config
```

## Uninstallation

To remove Jump CLI completely:

```bash
curl -fsSL https://raw.githubusercontent.com/amenophis1er/jump-cli/main/uninstall.sh | bash
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

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
