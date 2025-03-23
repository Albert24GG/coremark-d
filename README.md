## Building

To build using both `ldc2` and `gdc`:

```bash
make
```

The targets can also be build individually:

```bash
make coremark_ldc
make coremark_gdc
```

To clean up the build files:

```bash
make clean
```

### Building for arm using docker + qemu

1. Install all dependencies for emulating arm on x86_64:

- Arch Linux:

```bash
pacman -S qemu-base qemu-user-static qemu-user-binfmt
```

- Ubuntu:

```bash
apt install qemu binfmt-support qemu-user-static
```

2. Register the qemu binary format interpreter:

```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

3. Build and run the arm docker image:

```bash
docker build -f Dockerfile.arm --platform linux/arm64/v8 -t coremark-arm .
docker run --rm -v ./:/coremark-d-source -v ./arm-bins:/output coremark-arm:latest
```
