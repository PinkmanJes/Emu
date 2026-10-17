# NOVA implementation notes

- Product name: NOVA Emulator
- Design: original dark interface with violet/blue accents; not a Nagori copy
- Initial target: iPhone 13 Pro, iOS 27.x
- Desired systems: GameCube and PlayStation 2
- Desired mode: no-JIT baseline; optional JIT only if supported and explicitly enabled
- Build environment: cloud macOS through GitHub Actions

## Constraints
- This starter contains only the SwiftUI frontend; it does not emulate any console yet.
- The first workflow verifies a simulator build; it does not create a signed IPA.
- iOS does not provide a reliable app-wide hard cap on all system RAM. NOVA can limit its own caches and respond to memory pressure.
- Core licenses and iOS integration details must be reviewed before bundling.
- Breath of the Wild is a Wii U/Switch title, not GameCube or PS2, so it is outside the current system scope.
