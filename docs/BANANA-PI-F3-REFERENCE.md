# Banana Pi BPI-F3 Technical Reference

**Source**: [Official Banana Pi Wiki](https://wiki.banana-pi.org/Banana_Pi_BPI-F3)

This document provides technical reference information from the official Banana Pi F3 wiki that's relevant to our GitHub runner setup.

## Hardware Specifications

### Processor
- **SoC**: SpacemiT K1 (8-core RISC-V)
- **Architecture**: RISC-V64 (RV64GC)
- **AI Capability**: 2.0 TOPs integrated
- **Use Cases**: Single board computer, network storage, cloud computer, smart robot, industrial control, edge computer, **CI/CD runner**

### Memory Configurations
Our unit: **16GB LPDDR4**
- Available options: 2GB / 4GB / 8GB / 16GB LPDDR4

### Storage Configurations
Our unit: **128GB eMMC**
- eMMC options: 8GB / 16GB / 32GB / 128GB
- MicroSD card slot (for boot/expansion)
- M.2 slot supporting NVMe SSD expansion (PCIe 2.1, 2-lane × 2)

### Connectivity
- **Ethernet**: 2x Gigabit Ethernet (PoE capable)
- **USB**:
  - 4x USB 3.0 Type-A
  - 1x USB 2.0 Type-C (OTG capable)
- **Display**: HDMI 1.4 (up to 1080p@60fps)
- **Camera**: Dual MIPI-CSI interfaces (16M and 8M modules available)

### GPIO Header
- **Pinout**: 40-pin GPIO header
- **Interfaces**: UART, SPI, I2C
- **Voltage levels**: 3.3V and 5V supply available
- **GPIO pins**: GPIO_70-74, GPIO_91-92, GPIO_49-50 (among others)

## Power Requirements

### Power Input
- **USB Type-C**: Primary power input
- **DC input**: Alternative power option
- **PoE**: Available on Ethernet ports (optional)

### Recommended Power Supply
- **Voltage**: 5V
- **Current**: 3A minimum (5A recommended for stability under load)
- **Connector**: USB Type-C

**For GitHub Runner Use:**
- Use quality 5V/5A power supply for stability
- USB-C PD power supplies work well
- Avoid cheap/underpowered adapters (can cause instability under Docker builds)

## Operating Temperature

### Temperature Range
- **Operating**: -40°C to 85°C
- **Industrial-grade**: Suitable for server room environments

### Thermal Considerations
- **Passive cooling**: Board can run without fan in low-load scenarios
- **Active cooling**: Fan recommended for sustained high loads (like continuous CI/CD)
- **Our setup**: Using included 30mm active cooling fan

**For GitHub Runner:**
- Active cooling highly recommended
- Docker builds generate sustained CPU load
- Fan prevents thermal throttling during long compilations

## Operating System Support

### Supported Linux Distributions

1. **Bianbu** (SpacemiT's official distribution)
   - Default credentials: `root` / `bianbu`
   - Optimized for K1 chip

2. **Armbian** (Our choice)
   - Debian Trixie / Ubuntu Noble
   - Community-supported
   - Better for standard Linux workflows

3. **Fedora RISC-V**
   - Available as alternative
   - Bleeding-edge RISC-V support

### Why We Chose Armbian Debian Trixie

- ✅ Debian ecosystem (excellent package availability)
- ✅ Minimal images available (reduced bloat)
- ✅ Active Armbian community support
- ✅ Well-documented
- ✅ Stable kernel (6.6.99-current-spacemit)
- ✅ Perfect for headless server/runner use

## Boot Process

### Boot Priority
1. MicroSD card (if present)
2. eMMC (onboard storage)
3. USB (if configured)

**Our Strategy:**
1. Boot from SD card initially (Armbian installer)
2. Transfer system to eMMC using `nand-sata-install`
3. Remove SD card and boot from faster eMMC

## Application Suitability

### Designed For
According to official documentation, SpacemiT K1 is optimized for:
- Single board computers ✅
- Network storage ✅
- Cloud computers ✅
- Smart robots
- **Industrial control** ✅
- **Edge computing** ✅
- **CI/CD runners** ✅ (our use case)

### Why It's Good for GitHub Actions Runner

**Hardware advantages:**
- 8 RISC-V cores for parallel compilation
- 16GB RAM sufficient for Docker builds
- 128GB eMMC for build caches and images
- Gigabit Ethernet for fast Docker pulls
- Industrial temperature range (reliable in server rooms)
- Low power consumption vs x86 servers

**RISC-V advantages:**
- Native RISC-V64 builds (no emulation)
- Growing ecosystem (Docker, Go, Rust all support RISC-V)
- Open ISA (no licensing concerns)
- Ideal for building RISC-V software packages

## Network Configuration

### Dual Gigabit Ethernet
- **eth0**: Primary network interface
- **eth1**: Secondary interface (bonding, failover, or separate network)
- **PoE**: Power-over-Ethernet capable (requires PoE switch/injector)

**For GitHub Runner:**
- Single ethernet connection sufficient
- Use eth0 for primary connectivity
- Consider eth1 for isolated build network (advanced)

## Expansion Capabilities

### M.2 Slot
- **Type**: PCIe 2.1 (2-lane × 2)
- **Use**: NVMe SSD expansion
- **Benefit**: Additional fast storage for build cache

**Future Enhancement:**
- Add M.2 NVMe SSD for Docker build cache
- Mount to `/var/lib/docker` for faster builds
- 256GB-512GB recommended for heavy CI/CD

### USB 3.0 Expansion
- 4x USB 3.0 ports available
- External USB storage possible
- USB network adapters supported

## GPIO Pinout (40-pin Header)

```
Pin  Function         Pin  Function
1    3.3V             2    5V
3    I2C_SDA          4    5V
5    I2C_SCL          6    GND
7    GPIO_70          8    UART_TX
9    GND              10   UART_RX
11   GPIO_71          12   GPIO_91
13   GPIO_72          14   GND
15   GPIO_73          16   GPIO_92
17   3.3V             18   GPIO_74
19   SPI_MOSI         20   GND
21   SPI_MISO         22   GPIO_49
23   SPI_CLK          24   SPI_CS
25   GND              26   GPIO_50
```

**For GitHub Runner:**
- GPIO not typically needed for runner operation
- Available for custom automation (LED indicators, etc.)
- Fan control could be wired via GPIO if needed

## Known Considerations

### For CI/CD / GitHub Runner Use

**Recommendations based on hardware specs:**

1. **Power Supply**: Use quality 5V/5A supply
   - Prevents brownouts during intense builds
   - Ensures stability under full 8-core load

2. **Cooling**: Active fan strongly recommended
   - Docker builds are CPU-intensive
   - Prevents thermal throttling
   - Extends hardware lifespan

3. **Storage**: Use eMMC for OS/runner
   - Faster than SD card
   - Better endurance than SD
   - 128GB sufficient for most use cases

4. **Network**: Wired Ethernet required
   - WiFi available but Ethernet preferred for runner
   - More stable for long-running jobs
   - Lower latency for Docker pulls

5. **Memory**: 16GB is optimal
   - 8GB minimum for basic builds
   - 16GB comfortable for Docker + parallel builds
   - Allows multiple concurrent containers

## Comparison to Other SBCs

### vs Raspberry Pi 4
- ✅ More cores (8 vs 4)
- ✅ More RAM options (up to 16GB vs 8GB)
- ✅ Larger eMMC (128GB vs SD only)
- ✅ More USB 3.0 ports (4 vs 2)
- ✅ Dual Gigabit Ethernet
- ✅ Industrial temperature range
- ⚠️ RISC-V (less software than ARM, but growing fast)

### For RISC-V Development
- **Native builds**: No cross-compilation needed
- **Ecosystem**: Docker, Go, Rust, Node.js all support RISC-V
- **Performance**: Competitive with ARM SBCs in same class

## Official Resources

- **Wiki**: https://wiki.banana-pi.org/Banana_Pi_BPI-F3
- **GitHub**: https://github.com/BPI-SINOVOIP/BPI-F3-bsp
- **Forum**: https://forum.banana-pi.org/
- **Purchase**: [Banana Pi Official Store](http://www.banana-pi.org/)

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Our system architecture
- [SECURITY.md](SECURITY.md) - Security considerations
- [Hardware Setup Guides](hardware/) - Step-by-step setup

---

**Last Updated**: 2025-11-30
**Hardware Revision**: BPI-F3 (16GB RAM, 128GB eMMC)
