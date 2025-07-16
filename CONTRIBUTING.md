# Contributing to Jump CLI

Thank you for your interest in contributing to Jump CLI! 🎉

## How to Contribute

### Reporting Bugs
- Use the GitHub Issues tab
- Include your OS and shell information
- Provide steps to reproduce the issue
- Include error messages if any

### Suggesting Features
- Open a GitHub Issue with the "enhancement" label
- Describe the feature and its use case
- Explain how it would benefit users

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Test your changes thoroughly
4. **Commit your changes**
   ```bash
   git commit -m "Add amazing feature"
   ```
5. **Push to your branch**
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request**

### Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/jump-cli.git
cd jump-cli

# Test the installation
./install.sh

# Test your changes
./jump help
```

### Code Style
- Use bash best practices
- Add error handling with meaningful messages
- Use the existing color scheme for output
- Keep functions focused and well-named
- Add comments for complex logic

### Testing
Before submitting a PR, please test:
- Installation on a fresh system
- All commands work as expected
- Error handling works properly
- Shell integration functions correctly

## Questions?

Feel free to open an issue for any questions about contributing!
