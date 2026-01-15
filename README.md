# hytale-packets

Automatic documentation of the packets used in different versions of Hytale servers.

## How It Works

This repository automatically extracts and decompiles packet classes from Hytale server JAR files using GitHub Actions. Each server version gets its own branch with the decompiled Java source code.

### Package Structure

All packets are located in `com.hypixel.hytale.protocol.packets` and organized into subpackages:

| Package | Description |
|---------|-------------|
| `auth` | Authentication and authorization packets |
| `connection` | Connection management (connect, disconnect, ping/pong) |
| `entities` | Entity updates, spawning, animations |
| `interaction` | Player-entity interactions |
| `inventory` | Inventory management |
| `player` | Player-specific packets |
| `world` | World state and updates |
| `worldmap` | World map data |
| ... | And more |

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

### Viewing Extracted Packets

Each version has its own branch:
- `version/1.0.0`
- `version/beta-1`
- etc.

Browse the `packets/` directory to see decompiled sources.

## Local Development

### Prerequisites

- Java 21+
- PowerShell 7+ (or Windows PowerShell 5.1)

### Running Locally

```powershell
# Extract packets from a local JAR
./scripts/Extract-Packets.ps1 -JarPath "HytaleServer.jar" -OutputPath "packets"

# Vineflower will be downloaded automatically
```

### Script Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-JarPath` | Yes | - | Path to the server JAR |
| `-OutputPath` | No | `packets` | Output directory for Java files |
| `-VineflowerPath` | No | `vineflower.jar` | Path to Vineflower decompiler |

## Technical Details

- **Decompiler**: [Vineflower](https://github.com/Vineflower/vineflower) (modern Fernflower fork)
- **Target Package**: `com/hypixel/hytale/protocol/packets`
- **Output Format**: Java source files organized by subpackage

## License

This repository contains decompiled code for documentation purposes only.
