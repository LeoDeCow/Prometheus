# :fire: Prometheus
[![Test](https://github.com/prometheus-lua/Prometheus/actions/workflows/Test.yml/badge.svg)](https://github.com/prometheus-lua/Prometheus/actions/workflows/Test.yml)

## Description
Prometheus is a powerful Lua obfuscator written in pure Lua, designed to protect your Lua code while maintaining compatibility with Lua 5.1 and Roblox's LuaU.

This project was inspired by the amazing [javascript-obfuscator](https://github.com/javascript-obfuscator/javascript-obfuscator) and provides comprehensive code obfuscation capabilities.

## Features

### 🔒 **Security Features**
- **Variable Renaming**: Advanced variable and function name obfuscation
- **String Encryption**: Encrypt string literals to prevent easy reading
- **Control Flow Obfuscation**: Transform code flow to make reverse engineering difficult
- **Anti-Tamper Protection**: Detect and prevent code modification
- **VM-based Protection**: Virtual machine-based code execution

### ⚡ **Performance Features**
- **Memory Management**: Efficient memory usage with configurable limits
- **Performance Monitoring**: Built-in profiling and statistics
- **Batch Processing**: Handle large files efficiently
- **Caching System**: Optimize repeated operations

### 🛠 **Developer Experience**
- **Multiple Presets**: Pre-configured obfuscation levels (Minify, Light, Medium, Heavy)
- **Custom Configurations**: Fine-tune obfuscation settings
- **Comprehensive Logging**: Detailed logging with multiple levels
- **Error Handling**: Robust error handling and validation
- **Cross-Platform**: Works on Windows, macOS, and Linux

### 🔧 **Compatibility**
- **Lua 5.1**: Full compatibility with Lua 5.1
- **Roblox LuaU**: Support for Roblox's LuaU dialect
- **Pure Lua**: No external dependencies required

## Installation

### From Source
```bash
git clone https://github.com/levno-710/Prometheus.git
cd Prometheus
```

### Requirements
- LuaJIT or Lua 5.1
- Download Lua 5.1 binaries from [here](https://sourceforge.net/projects/luabinaries/files/5.1.5/Tools%20Executables/)

## Quick Start

### Basic Usage
```bash
# Obfuscate with Medium preset
lua ./cli.lua --preset Medium ./your_file.lua

# Obfuscate with custom output file
lua ./cli.lua --preset Heavy --out result.lua ./your_file.lua

# Target specific Lua version
lua ./cli.lua --Lua51 --preset Light ./your_file.lua
```

### Advanced Usage
```bash
# Use custom configuration
lua ./cli.lua --config myconfig.lua ./your_file.lua

# Enable pretty printing
lua ./cli.lua --pretty --preset Medium ./your_file.lua

# Save error logs
lua ./cli.lua --saveerrors --preset Heavy ./your_file.lua

# Disable colored output
lua ./cli.lua --nocolors --preset Medium ./your_file.lua
```

### Command Line Options
```
--preset, -p <name>        Use predefined obfuscation preset
--config, -c <file>        Use custom configuration file
--out, -o <file>           Specify output file
--nocolors                 Disable colored output
--Lua51                    Target Lua 5.1
--LuaU                     Target Roblox LuaU
--pretty                   Enable pretty printing
--saveerrors               Save error messages to file
--help, -h                 Show help message
--version                  Show version information
```

## Configuration

### Presets
Prometheus comes with several pre-configured presets:

- **Minify**: Basic code minification
- **Light**: Light obfuscation for performance
- **Medium**: Balanced obfuscation (recommended)
- **Heavy**: Maximum obfuscation for security

### Custom Configuration
Create a custom configuration file:

```lua
return {
    LuaVersion = "Lua51",  -- or "LuaU"
    PrettyPrint = false,
    Seed = 12345,  -- Random seed for reproducible results
    VarNamePrefix = "_",
    Steps = {
        {
            Name = "EncryptStrings",
            Settings = {
                Enabled = true,
                Key = "mysecretkey"
            }
        },
        {
            Name = "AntiTamper",
            Settings = {
                Enabled = true
            }
        }
    }
}
```

## Available Obfuscation Steps

### Core Steps
- **Variable Renaming**: Rename variables and functions
- **String Encryption**: Encrypt string literals
- **Control Flow Obfuscation**: Transform code structure
- **Anti-Tamper**: Detect code modification
- **VM Protection**: Virtual machine execution

### Advanced Steps
- **Constant Array**: Convert constants to array lookups
- **Number Expressions**: Convert numbers to expressions
- **String Splitting**: Split long strings
- **Proxy Functions**: Wrap functions in proxies
- **Watermarking**: Add invisible watermarks

## Performance Monitoring

Prometheus includes built-in performance monitoring:

```lua
local Prometheus = require("prometheus")

-- Get performance report
local report = Prometheus.getPerformanceReport()
print("Total time:", report.profiler.totalTime)
print("Memory usage:", report.profiler.peakMemory)

-- Print detailed report
Prometheus.printPerformanceReport()
```

## Error Handling

The obfuscator includes comprehensive error handling:

- **Input Validation**: Validate files, code, and configurations
- **Memory Limits**: Prevent memory exhaustion
- **Error Collection**: Collect and report multiple errors
- **Graceful Degradation**: Continue processing when possible

## Examples

### Basic Obfuscation
```lua
-- Input: simple.lua
local function greet(name)
    print("Hello, " .. name .. "!")
end

greet("World")
```

```bash
lua ./cli.lua --preset Medium simple.lua
```

### Advanced Configuration
```lua
-- config.lua
return {
    LuaVersion = "Lua51",
    PrettyPrint = false,
    Seed = 42,
    Steps = {
        {Name = "EncryptStrings", Settings = {Enabled = true}},
        {Name = "AntiTamper", Settings = {Enabled = true}},
        {Name = "VMify", Settings = {Enabled = true}}
    }
}
```

## Building

### Windows Build
Prometheus can be built on Windows using:
```batch
build.bat
```

This creates a `build` folder containing `prometheus.exe` and required files.

### Requirements for Building
- [srlua.exe](https://github.com/LuaDist/srlua)
- [glue.exe](https://github.com/LuaDist/srlua)
- lua51.dll (if dynamically linked)

## Testing

Run the test suite:
```bash
lua ./tests.lua
```

## Documentation

For detailed documentation, visit: [https://levno-710.gitbook.io/prometheus/](https://levno-710.gitbook.io/prometheus/)

## Community

- **Discord**: [Join our Discord server](https://discord.gg/U8h4d4Rf64)
- **Issues**: Report bugs and request features on GitHub
- **Contributions**: Pull requests are welcome!

## Changelog

### v0.2 (Latest)
- ✨ Added comprehensive validation system
- ⚡ Improved performance monitoring
- 🔧 Enhanced error handling
- 📝 Better documentation and examples
- 🛠 Improved CLI with help system
- 🔒 Enhanced security features

### v0.1
- Initial release with basic obfuscation features

## License

This project is licensed under the GNU Affero General Public License v3.0. See [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Acknowledgments

- Inspired by [javascript-obfuscator](https://github.com/javascript-obfuscator/javascript-obfuscator)
- Built with pure Lua for maximum compatibility
- Community-driven development

---

**Made with ❤️ by the Prometheus team**
