# Contributing to EchoVeil

Thank you for your interest in contributing to EchoVeil! This document provides guidelines and instructions for contributing.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please be respectful and professional in all interactions.

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Use the bug report template
3. Include:
   - Clear description of the issue
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details
   - Error messages/logs

### Suggesting Features

1. Check if feature is already proposed
2. Use the feature request template
3. Explain:
   - Use case and motivation
   - Proposed solution
   - Alternatives considered
   - Implementation complexity

### Pull Requests

1. Fork the repository
2. Create a feature branch (`feat/your-feature`)
3. Make your changes
4. Write/update tests
5. Update documentation
6. Submit pull request

## Development Setup

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install Node.js dependencies
npm install

# Install Circom
npm install -g circom
npm install -g snarkjs
```

### Building

```bash
# Compile contracts
forge build

# Compile circuits
cd circuits && ./compile.sh

# Run tests
forge test

# Run with coverage
forge coverage
```

### Testing

```bash
# Unit tests
forge test

# Integration tests
forge test --match-contract Integration

# Fuzz tests
forge test --fuzz-runs 10000

# Gas snapshot
forge snapshot
```

## Code Style

### Solidity

- Follow [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- Use 4 spaces for indentation
- Maximum line length: 100 characters
- Use NatSpec comments for all public functions
- Run `forge fmt` before committing

```solidity
/**
 * @notice Brief description
 * @dev Implementation details
 * @param paramName Parameter description
 * @return returnName Return value description
 */
function exampleFunction(uint256 paramName) 
    external 
    view 
    returns (uint256 returnName) 
{
    // Implementation
}
```

### JavaScript

- Use ES6+ features
- 2 spaces for indentation
- Semicolons required
- Use `const` and `let`, avoid `var`
- Run `npm run lint` before committing

```javascript
/**
 * Brief description
 * @param {type} paramName - Parameter description
 * @returns {type} Return value description
 */
function exampleFunction(paramName) {
    // Implementation
}
```

## Commit Guidelines

### Format

```
type(scope): subject

body

footer
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `refactor`: Code refactoring
- `chore`: Maintenance tasks
- `perf`: Performance improvements

### Examples

```
feat(core): add reputation decay mechanism

Implement time-based reputation decay to incentivize
continued activity and prevent score stagnation.

Closes #123
```

```
fix(oracle): prevent update cooldown bypass

Add additional check in executeRootUpdate to ensure
cooldown period has elapsed even after timelock.

Fixes #456
```

## Testing Guidelines

### Unit Tests

- Test all public functions
- Test edge cases and error conditions
- Use descriptive test names
- Aim for >90% coverage

```solidity
function testCannotClaimWithInsufficientReputation() public {
    vm.expectRevert("Insufficient reputation");
    airdrop.claim(lowRepProof, nullifier);
}
```

### Integration Tests

- Test contract interactions
- Test realistic user flows
- Test multi-step processes

### Fuzz Testing

- Use for numeric parameters
- Test boundary conditions
- Add assumptions when needed

```solidity
function testFuzzScoreCalculation(uint256 score) public {
    vm.assume(score > 0 && score < 10000);
    uint256 result = calculator.calculate(score);
    assertGt(result, 0);
}
```

## Documentation

### Required Documentation

- NatSpec comments for all contracts
- README for new features
- API documentation updates
- Architecture diagrams (if applicable)

### Documentation Style

- Clear and concise
- Include examples
- Explain "why" not just "what"
- Link to related documentation

## Review Process

### What We Look For

1. **Functionality**: Does it work as intended?
2. **Security**: Are there vulnerabilities?
3. **Gas Optimization**: Is it gas-efficient?
4. **Code Quality**: Is it readable and maintainable?
5. **Tests**: Are there comprehensive tests?
6. **Documentation**: Is it well-documented?

### Review Checklist

- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] New tests added
- [ ] Documentation updated
- [ ] No compiler warnings
- [ ] Gas costs acceptable
- [ ] Security considerations addressed

## Security

### Security-Critical Changes

Changes affecting security require:
- Detailed security analysis
- Additional review by security team
- Extended testing period
- Audit before deployment

### Reporting Vulnerabilities

DO NOT create public issues for security vulnerabilities.

Email: security@echoveil.io

## Community

### Communication Channels

- **Discord**: Development discussions
- **GitHub Issues**: Bug reports and features
- **Twitter**: Announcements
- **Forum**: Community discussions

### Getting Help

- Check documentation first
- Search existing issues
- Ask in Discord #dev-help
- Tag maintainers if urgent

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Credited in release notes
- Eligible for contributor badges
- Invited to contributor events

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to reach out:
- Discord: https://discord.gg/echoveil
- Email: dev@echoveil.io
- Twitter: @EchoVeil

Thank you for contributing to EchoVeil! 🎉

