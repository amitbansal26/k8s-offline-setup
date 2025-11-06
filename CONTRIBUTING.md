# Contributing to k8s-offline-setup

Thank you for your interest in contributing to this project! This document provides guidelines for contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear title and description
- Steps to reproduce the issue
- Expected vs actual behavior
- Your environment details (OS version, Ansible version, etc.)
- Relevant logs or error messages

### Suggesting Enhancements

Enhancement suggestions are welcome! Please open an issue with:
- A clear title and description
- The use case for the enhancement
- Any implementation ideas you have

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following the guidelines below
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Development Guidelines

### Ansible Best Practices

1. **Idempotency**: All tasks should be idempotent (can be run multiple times safely)
2. **Variables**: Use descriptive variable names and define them in `group_vars/all.yml`
3. **Documentation**: Add comments for complex tasks
4. **Error Handling**: Use `ignore_errors`, `failed_when`, and `when` clauses appropriately
5. **Tags**: Add tags to tasks for selective execution when appropriate

### Code Style

1. **YAML Formatting**:
   - Use 2 spaces for indentation
   - Add a space after the colon in key-value pairs
   - Use single quotes for strings when possible
   
2. **Task Naming**:
   - Use descriptive names that explain what the task does
   - Start with a capital letter
   - Use present tense ("Install package" not "Installing package")

3. **File Organization**:
   - Keep related tasks in the same role
   - Use `tasks/main.yml` as the entry point for roles
   - Split complex roles into multiple task files if needed

### Testing

Before submitting a pull request:

1. Test your changes in a local environment
2. Verify the playbook is idempotent (can be run twice without errors)
3. Ensure backward compatibility where possible
4. Update documentation if needed

### Documentation

When adding new features:

1. Update the README.md with any new usage instructions
2. Add or update examples in the documentation
3. Document any new variables in `group_vars/all.yml` with comments
4. Update TROUBLESHOOTING.md if adding solutions to known issues

## Project Structure

```
k8s-offline-setup/
├── roles/                  # Ansible roles
│   ├── prerequisites/      # System prerequisites
│   ├── container-runtime/  # Container runtime setup
│   ├── kubernetes/         # Kubernetes installation
│   ├── cluster-init/       # Master node initialization
│   ├── cluster-join/       # Worker node join
│   └── cni-plugin/         # CNI plugin installation
├── group_vars/             # Variables
├── inventory/              # Inventory files
├── download-packages.yml   # Package download playbook
├── site.yml                # Main playbook
└── README.md               # Documentation
```

## Commit Message Guidelines

- Use clear and meaningful commit messages
- Start with a verb in present tense (Add, Update, Fix, Remove)
- Keep the first line under 50 characters
- Add detailed description if needed after a blank line

Example:
```
Add support for custom CNI configurations

- Allow users to specify custom CNI plugin versions
- Add validation for CNI configuration
- Update documentation with examples
```

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive experience for everyone.

### Our Standards

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Publishing others' private information
- Other conduct which could reasonably be considered inappropriate

## Questions?

If you have questions about contributing, feel free to:
- Open an issue with your question
- Reach out to the maintainers

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
