# Contributing to GitOps Demo Project

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (AKS version, Argo CD version, etc.)

### Suggesting Enhancements

1. Check existing issues and pull requests
2. Create an issue with:
   - Clear description of the enhancement
   - Use case and benefits
   - Potential implementation approach

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly:
   - Helm chart linting: `helm lint helm/`
   - YAML validation
   - Deploy to dev environment
5. Commit with clear messages (`git commit -m 'feat: add amazing feature'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Commit Message Convention

Follow conventional commits:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring
- `test:` - Test updates
- `ci:` - CI/CD changes

### Code Style

- Python: Follow PEP 8
- YAML: 2-space indentation
- Bash: Use shellcheck for validation
- Helm: Follow Helm best practices

## Development Setup

1. Clone the repository
2. Set up Azure infrastructure (see infrastructure/README.md)
3. Test changes in dev environment first
4. Validate Helm charts: `helm template helm/ -f environments/dev/values.yaml`

## Questions?

Feel free to open an issue for questions or discussion.
