# NOVA Emulator — starter shell

An original SwiftUI iOS interface prototype for a GameCube + PS2 emulator frontend.

## Current status
- Original dark UI with game library, filters, search, and file import.
- Copies selected game files into the app's Documents/Games directory.
- GitHub Actions workflow is intended to verify a simulator build.
- **No emulation cores are integrated yet.** Imported games are library entries only; they do not run yet.
- This workflow does not produce an IPA. Device packaging requires a device target, signing configuration, and subsequent testing.

## Next steps
1. Create a private GitHub repository named `NOVA`.
2. Upload the contents of this folder to the repository root.
3. Open **Actions** and run **NOVA iOS build**. Review the result.
4. Once the shell builds, review core licenses/build instructions and integrate GameCube and PS2 cores one at a time.
5. Configure device signing after the bundle ID and signing route are agreed.
