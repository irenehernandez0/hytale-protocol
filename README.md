# hytale-packets

Automatic documentation of the network protocol used in different versions of Hytale servers.

## How It Works

This repository automatically extracts and decompiles the full protocol package from Hytale server JAR files using GitHub Actions. Each server version gets its own branch with the decompiled Java source code.

The wiki documentation focuses on **packets** (the actual network messages), but includes links to related **enums** and **data classes** from the broader protocol package for complete context.

### Package Structure

The full `com.hypixel.hytale.protocol` package is extracted, with packets located in the `packets` subpackage:

| Package | Description |
|---------|-------------|
| `packets/auth` | Authentication and authorization packets |
| `packets/connection` | Connection management (connect, disconnect, ping/pong) |
| `packets/entities` | Entity updates, spawning, animations |
| `packets/interaction` | Player-entity interactions |
| `packets/inventory` | Inventory management |
| `packets/player` | Player-specific packets |
| `packets/world` | World state and updates |
| `packets/worldmap` | World map data |
| ... | And more packet categories |

Additional protocol entities (enums, data classes) are also extracted and documented to provide complete type references.

## Usage

### Extracting Packets from a New Server Version

1. **Go to Actions** → **Upload Server JAR**
2. Enter the version number (e.g., `1.0.0`, `beta-1`)
3. A draft release will be created - upload your JAR file there
4. **Go to Actions** → **Extract Hytale Packets**
5. Enter:
   - **Version**: Same version number
   - **JAR URL**: `https://github.com/<owner>/<repo>/releases/download/jar-<version>/HytaleServer.jar`

Alternatively, provide any direct download URL for the JAR file.

### Viewing Extracted Protocol

Each version has its own branch:
- `version/1.0.0`
- `version/beta-1`
- etc.

Browse the `protocol/` directory to see decompiled sources:
- `protocol/packets/` - Network packet definitions
- `protocol/*/` - Related enums, data classes, and utilities

### Wiki Documentation

The generated wiki documentation is published to the [repository wiki](../../wiki) and includes:
- **Packet documentation** with field types, sizes, and constraints
- **Enum types** with value tables
- **Data types** with field documentation
- **Cross-references** between packets and their related types

## Local Development

### Prerequisites

- Java 21+
- PowerShell 7+ (or Windows PowerShell 5.1)
- Python 3.11+ (for wiki generation)

### Running Locally

```powershell
# Extract protocol from a local JAR
./scripts/Extract-Packets.ps1 -JarPath "HytaleServer.jar" -OutputPath "protocol"

# Vineflower will be downloaded automatically

# Generate wiki documentation
python ./scripts/generate_wiki.py --protocol-dir "./protocol" --output-dir "./wiki" --version "1.0.0"
```

### Script Parameters

**Extract-Packets.ps1:**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-JarPath` | Yes | - | Path to the server JAR |
| `-OutputPath` | No | `protocol` | Output directory for Java files |
| `-VineflowerPath` | No | `vineflower.jar` | Path to Vineflower decompiler |

**generate_wiki.py:**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--protocol-dir` | No | `./protocol` | Directory containing protocol package |
| `--output-dir` | No | `./wiki` | Output directory for wiki pages |
| `--version` | No | `unknown` | Version string for documentation |
| `--json` | No | - | Also generate JSON summary |

## Technical Details

- **Decompiler**: [Vineflower](https://github.com/Vineflower/vineflower) (modern Fernflower fork)
- **Target Package**: `com/hypixel/hytale/protocol` (full package)
- **Documentation Focus**: Packets with links to related entities
- **Output Format**: Java source files organized by subpackage + Markdown wiki

## License

This repository contains decompiled code for documentation purposes only.
