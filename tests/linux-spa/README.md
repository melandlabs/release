# Ubuntu 22.04 SPA compatibility

The release runners must stay on Ubuntu 22.04. Moving them to 24.04 can
introduce newer glibc and other shared-library requirements into the artifacts.

`xcap = 0.9.4` pulls in `libspa = 0.9.2`, whose video wrapper unconditionally
expects `spa_video_info_raw.flags` and an unsigned `modifier`. Jammy's
PipeWire 0.3.48 headers do not have those definitions.

`scripts/install-spa-headers.sh` installs only the header-only SPA interface
from PipeWire 0.3.65 into an isolated prefix, with an archive SHA-256 check.
It provides a `libspa-0.2.pc` override, not a `libpipewire-0.3.pc` override.
No shared libraries, system headers, apt sources, or runtime packages are
replaced. Cargo still compiles and links against Jammy's PipeWire 0.3.48 and
glibc 2.35. The prefix is a build input and must not be bundled with the app.

Run from the repository root:

```sh
docker build --progress plain -f tests/linux-spa/Dockerfile .
```

The smoke test compiles the failing Rust dependency chain, checks the affected
video accessors, initializes the stock PipeWire library, and captures an Xvfb
X11 monitor through xcap. `LD_BIND_NOW=1` forces immediate dynamic symbol
resolution. Both release architectures run this test on pull requests.

This is not a full Tauri packaging or Wayland desktop integration test.
Keep the smoke dependency pins aligned with the application's capture stack;
remove the header override once upstream supports Jammy headers directly.
