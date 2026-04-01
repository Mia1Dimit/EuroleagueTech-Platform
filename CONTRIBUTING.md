# Contributing to EuroleagueTech Cloud Platform

Thank you for your interest in contributing! This document provides guidelines for participating in the project.

## Code of Conduct

Please read our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) - we are committed to providing a welcoming and inclusive environment.

## Getting Started

### Prerequisites
- AWS Account (free tier eligible)
- Git
- Terraform >= 1.0
- Python 3.9+
- Node.js (for frontend development, optional)

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/EuroleagueTech-Cloud-Platform.git
cd EuroleagueTech-Cloud-Platform

# Set up infrastructure
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS account details

# Initialize Terraform
terraform init -backend-config=backend-config-dev.tfvars

# Set up backend environment
cd ../backend
python -m venv venv
source venv/bin/activate  # or: venv\Scripts\activate on Windows
pip install -r requirements.txt
```

## Development Workflow

### 1. Create a Feature Branch
```bash
git checkout -b feature/description-of-feature
```

### 2. Make Your Changes

**For Infrastructure Changes:**
- Update `.tf` files in `infrastructure/`
- Test with `terraform plan`
- Document any new modules

**For Backend Changes:**
- Update `backend/src/` files
- Follow PEP 8 style guide
- Add docstrings to functions

**For Frontend Changes:**
- Update `frontend/` HTML/CSS/JS
- Test in multiple browsers
- Maintain accessibility standards

### 3. Test Your Changes

```bash
# Validate Terraform
cd infrastructure
terraform validate
terraform plan -var-file=terraform.tfvars

# Test backend locally
cd ../backend
python -m pytest

# Test frontend
# Open frontend/index.html in browser or use `python -m http.server`
```

### 4. Commit and Push

```bash
git add .
git commit -m "feat: clear description of changes (closes #123)"
git push origin feature/description-of-feature
```

**Commit message conventions:**
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `refactor:` code restructuring
- `test:` test coverage
- `chore:` build, config, dependencies

### 5. Open a Pull Request

- Link relevant issues
- Describe what changed and why
- Include screenshots/demos if applicable
- Ensure CI/CD checks pass

## Reporting Issues

### Security Issues
⚠️ **Do NOT open public GitHub issues for security vulnerabilities.**  
See [SECURITY.md](SECURITY.md) for responsible disclosure.

### Bug Reports
When reporting bugs, include:
- Description of the bug
- Steps to reproduce
- Expected vs. actual behavior
- Relevant logs or error messages
- Environment (OS, AWS region, etc.)

### Feature Requests
- Describe the proposed feature
- Explain the use case/benefit
- Link to any related issues

## Code Standards

### Python (Backend)
- Follow PEP 8
- Use type hints where possible
- Include docstrings for functions and classes
- Max line length: 100 characters

### JavaScript (Frontend)
- Use `const`/`let`, not `var`
- Use arrow functions
- Use template literals for strings
- No global variables

### Terraform (Infrastructure)
- Use meaningful variable names
- Document inputs and outputs
- Group related resources
- Use modules for reusability
- Follow HashiCorp style guide

## Documentation

- Update relevant `.md` files when changing functionality
- Keep architecture docs current
- Include inline code comments for complex logic
- Update README if adding new features

## Review Process

1. **Automated Checks**: CI/CD pipeline runs tests and linting
2. **Code Review**: Maintainers review code quality, architecture fit
3. **Testing**: We may test changes in dev environment
4. **Merge**: Once approved, changes are merged to main

## Questions?

- 💬 Open a GitHub Discussion for questions
- 📧 Check existing issues before opening a new one
- 📖 Review project documentation first

---

**Thank you for making EuroleagueTech better! 🚀**
