# Contributing to AI PRD Generator

Thank you for your interest in contributing! This guide will help you get started.

## Code of Conduct

Be respectful, constructive, and professional. We're all here to build something great together.

## How to Contribute

### Reporting Bugs

1. **Search existing issues** - Check if the bug is already reported in [Issues](https://github.com/cdeust/ai-prd-generator/issues)
2. **Create detailed report** - If not found, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce the bug
   - Expected behavior vs actual behavior
   - System information (macOS/Linux version, Swift version, Docker/Colima)
   - Error messages or log output
   - Screenshots if applicable

### Suggesting Features

1. **Check existing suggestions** - Search [Issues](https://github.com/cdeust/ai-prd-generator/issues) for similar ideas
2. **Describe the use case** - Open a new issue explaining:
   - What problem this feature solves
   - Why it would be valuable
   - How it fits with existing features
   - Proposed implementation (optional)

### Submitting Code Changes

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then:
   git clone https://github.com/YOUR_USERNAME/ai-prd-generator.git
   cd ai-prd-generator
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

3. **Follow coding standards**
   - Read `CLAUDE.md` for architecture rules and zero tolerance guidelines
   - Run verification scripts before committing:
     ```bash
     ./scripts/verify-all.sh
     ```
   - All code must pass verification (zero tolerance rules enforced)
   - Files must be ≤ 300 lines
   - Methods must be ≤ 40 lines
   - Follow SOLID principles
   - Maintain clean architecture layers

4. **Write tests**
   - Add tests for new features
   - Ensure existing tests still pass
   - Run tests:
     ```bash
     cd library && swift test
     ```

5. **Update documentation**
   - Update README.md if user-facing changes
   - Update CHANGELOG.md following Keep a Changelog format
   - Add code comments for complex logic
   - Update architecture docs if needed

6. **Commit with clear messages**
   ```bash
   # Use conventional commits format
   git commit -m "feat: add JIRA priority levels to ticket generation"
   git commit -m "fix: resolve RAG indexing deadlock on large codebases"
   git commit -m "docs: update prerequisites for Linux installation"
   ```

   Commit types:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation only
   - `refactor:` - Code change that neither fixes bug nor adds feature
   - `test:` - Adding or updating tests
   - `perf:` - Performance improvement
   - `chore:` - Maintenance tasks

7. **Push and create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```
   - Go to GitHub and click "Compare & pull request"
   - Fill in PR description with:
     - What changed and why
     - How to test the changes
     - Any breaking changes
     - Related issues (e.g., "Fixes #123")

## Development Setup

### Prerequisites
- Swift 5.9+ (Xcode or Swift toolchain)
- Docker or Colima
- Python 3.8+
- AI Provider API key (Anthropic, OpenAI, Gemini, or Apple Intelligence)

### Initial Setup
```bash
# Clone repository
git clone https://github.com/cdeust/ai-prd-generator.git
cd ai-prd-generator

# Run setup script
./scripts/setup.sh

# Set API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Verify build
cd library && swift build

# Run verification scripts
cd ..
./scripts/verify-all.sh
```

### Running Tests
```bash
# Run all tests
cd library && swift test

# Run specific test
swift test --filter TestClassName

# Run with verbose output
swift test --verbose
```

## Code Standards

### Architecture Rules
- **Clean Architecture** - See `docs/architecture/layered-isolation-architecture.md`
- **Domain Layer** - Zero framework dependencies (only Foundation)
- **Application Layer** - Use cases and services
- **Infrastructure Layer** - AI providers, database, external APIs
- **Composition Layer** - Dependency injection

### Zero Tolerance Rules
See `ZERO_TOLERANCE_RULES.md` for complete list:
1. Files ≤ 300 lines
2. One structure per file
3. Methods ≤ 40 lines
4. SOLID principles (no Utils/Helper/Manager god objects)
5. Clean Architecture layers (dependencies point inward)
6. Naming conventions (see `NAMING_CONVENTIONS.md`)
7. Documentation is context (no instant-T snapshots)
8. No backward compatibility hacks
9. No nested types

### Verification Scripts
**Always run before committing:**
```bash
./scripts/verify-all.sh
```

This runs:
- `verify-zero-tolerance.sh` - 9 absolute rules
- `verify-naming.sh` - Naming conventions
- `verify-claude-rules.sh` - Architecture compliance
- `verify-3rs.sh` - Reliability, Readability, Reusability
- `verify-production-tests.sh` - Test quality

**Never commit if verification fails.**

## Pull Request Review Process

1. **Automated Checks** - CI runs verification scripts
2. **Code Review** - Maintainer reviews:
   - Code quality and architecture
   - Test coverage
   - Documentation updates
   - Breaking changes
3. **Feedback** - Address comments or requested changes
4. **Approval** - Once approved, PR will be merged
5. **Release** - Changes included in next version

## Testing Guidelines

### Unit Tests
- Test individual components in isolation
- Mock external dependencies
- Cover edge cases and error paths
- Use descriptive test names

### Integration Tests
- Test interactions between components
- Use real implementations where possible
- Test full workflows (e.g., RAG indexing + search)

### Production Validation Tests
- Large-scale validation (1M+ samples)
- Statistical verification
- Performance benchmarks
- See `CLAUDE.md` section on production testing

## Documentation

### Code Comments
- Explain **why**, not **what**
- Document complex algorithms
- Add examples for public APIs
- Keep comments up-to-date

### Architecture Documentation
- Update ADRs (Architecture Decision Records) for major changes
- Keep architecture diagrams current
- Document design trade-offs

## Need Help?

- **Questions?** Open a discussion or issue
- **Stuck?** Ask in your PR and tag maintainers
- **Found a bug?** Report it with detailed information

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing!** Every contribution, big or small, helps make this project better.
