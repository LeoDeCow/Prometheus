# Security Documentation for Prometheus Obfuscator

## Overview
This document outlines the security measures implemented in the Prometheus Obfuscator to protect against various types of attacks and vulnerabilities.

## Security Features Implemented

### 1. Input Validation and Sanitization

#### File Path Validation
- **Path Traversal Protection**: Blocks attempts to access parent directories using `../` patterns
- **Null Byte Protection**: Removes null bytes and control characters from file paths
- **Length Limits**: Enforces maximum path length (260 characters for Windows compatibility)
- **Pattern Blocking**: Blocks dangerous file patterns and Windows reserved names

#### Filename Validation
- **Extension Whitelisting**: Only allows safe file extensions (`.lua`, `.txt`, `.md`, `.cfg`, `.conf`)
- **Reserved Name Blocking**: Prevents use of Windows reserved names (CON, PRN, AUX, NUL, etc.)
- **Character Filtering**: Only allows alphanumeric characters, dots, hyphens, underscores, and slashes

#### String Sanitization
- **Control Character Removal**: Strips control characters (0x00-0x1F) from input strings
- **Length Limiting**: Enforces maximum string length (1000 characters) to prevent buffer overflow attacks
- **Type Validation**: Ensures inputs are of expected types before processing

### 2. Code Execution Security

#### Sandboxed Configuration Loading
- **Strict Sandboxing**: Configuration files run in isolated environments with limited function access
- **Function Whitelisting**: Only safe functions are available in sandbox (string, table, math operations)
- **Dangerous Function Blocking**: Blocks access to:
  - File operations (`io`, `dofile`)
  - System operations (`os`)
  - Code loading (`load`, `loadstring`)
  - Module operations (`require`, `package`)
  - Debug operations (`debug`)
  - Metatable operations (`getmetatable`, `setmetatable`)
  - Global access (`_G`, `_ENV`)

#### Protected Execution
- **Error Handling**: All configuration loading uses `pcall` for safe execution
- **Validation**: Configuration files are validated before execution
- **Isolation**: Each configuration file runs in its own isolated environment

### 3. File Operation Security

#### Secure File Reading
- **Path Validation**: All file paths are validated before opening
- **Size Limits**: Enforces maximum file size (10MB default) to prevent memory exhaustion
- **Error Handling**: Graceful handling of file operation failures

#### Secure File Writing
- **Output Validation**: All output filenames are validated before writing
- **Protected Operations**: File writes use `pcall` for error handling
- **Resource Cleanup**: Ensures file handles are properly closed even on errors

### 4. Command Line Interface Security

#### Argument Validation
- **Whitelist Approach**: Only known safe command line arguments are accepted
- **Input Sanitization**: All arguments are validated and sanitized before processing
- **Type Checking**: Ensures arguments are of expected types

#### Preset Security
- **Preset Validation**: Preset names are validated before lookup
- **Safe Fallbacks**: Provides safe default configurations when invalid options are specified

### 5. Error Handling and Logging

#### Secure Error Reporting
- **Input Sanitization**: All error messages are sanitized before logging
- **Safe Filenames**: Error log filenames are validated before writing
- **Fallback Handling**: Provides safe fallback filenames when validation fails

#### Logging Security
- **Output Sanitization**: All log output is sanitized to prevent injection attacks
- **Length Limits**: Prevents extremely long log messages from causing issues

## Security Configuration

### File Size Limits
```lua
max_file_size = 10 * 1024 * 1024  -- 10MB maximum
max_string_length = 1000           -- 1000 character maximum
```

### Allowed File Extensions
```lua
allowed_extensions = {".lua", ".txt", ".md", ".cfg", ".conf"}
```

### Blocked Patterns
```lua
blocked_patterns = {
    "%.%.",           -- Directory traversal
    "//",             -- Double slashes
    "\\\\",           -- Double backslashes
    "[\0\1-\31]",     -- Control characters
    "CON$", "PRN$",   -- Windows reserved names
    "AUX$", "NUL$",
    "COM%d+$", "LPT%d+$"
}
```

## Threat Model

### Protected Against
1. **Path Traversal Attacks**: Attempts to access files outside intended directories
2. **Code Injection**: Malicious code execution through configuration files
3. **File System Attacks**: Unauthorized file access or modification
4. **Buffer Overflow**: Extremely long input strings causing memory issues
5. **Command Injection**: Malicious command execution through file paths
6. **Resource Exhaustion**: Extremely large files consuming excessive memory

### Security Assumptions
1. **Trusted Environment**: The tool runs in a trusted environment
2. **File System Access**: The tool has legitimate access to specified files
3. **Lua Environment**: The Lua runtime environment is secure

## Best Practices for Users

### Configuration Files
- Only include necessary configuration data
- Avoid complex logic in configuration files
- Use the provided sandbox environment for any custom functions

### File Management
- Keep input files in dedicated directories
- Use descriptive, safe filenames
- Avoid special characters in filenames

### Error Handling
- Review error logs for any suspicious activity
- Monitor file access patterns
- Report any unexpected behavior

## Security Updates

### Version History
- **v0.2**: Initial security implementation
- Added comprehensive input validation
- Implemented sandboxed configuration loading
- Added file operation security measures

### Future Enhancements
- Additional file format validation
- Enhanced logging and monitoring
- Configuration file signing and verification
- Network security for remote configurations

## Reporting Security Issues

If you discover a security vulnerability in the Prometheus Obfuscator:

1. **Do not** disclose it publicly
2. **Do not** create a public issue
3. Contact the maintainers privately
4. Provide detailed reproduction steps
5. Allow time for investigation and fix

## Compliance

This implementation follows security best practices including:
- **OWASP Top 10**: Addresses common web application security risks
- **CWE/SANS Top 25**: Covers critical software weaknesses
- **Secure Coding Standards**: Implements defensive programming practices

## Conclusion

The Prometheus Obfuscator implements multiple layers of security to protect against common attack vectors. Regular security reviews and updates ensure continued protection against emerging threats.