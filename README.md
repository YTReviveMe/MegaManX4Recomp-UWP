# Mega Man X4 Recomp UWP

This project ports [MegaManX4Recomp](https://github.com/mstan/MegaManX4Recomp) to x64 UWP for Xbox Developer Mode. The retail game is not included.

At first launch, select the game from internal or external storage. Keep the CUE and BIN files together. The launcher verifies and remembers the selected game. Later launches start it automatically; the storage menu returns if the file is unavailable.

Press Xbox **Menu + View** while playing to open Display Settings. Image smoothing and widescreen apply immediately. Internal resolution applies after restarting the app. Settings are saved automatically.

## Build

Use the Mega Man X4 USA MODE2/2352 dump (SLUS-00561) documented in the upstream `DISC.md`. Generated code and disc data are ignored by Git.

```powershell
./tools/generate.ps1 -DiscCue "C:/path/to/Mega Man X4 (USA).cue"
./tools/with-msvc.ps1 cmake -S . -B build/uwp -G Ninja -DCMAKE_BUILD_TYPE=Release -DMMX4_UWP_DEPS="C:/path/to/uwp-deps"
./tools/with-msvc.ps1 cmake --build build/uwp --target mmx4 -j 6
./tools/package_uwp.ps1
./tools/sign_uwp_package.ps1 build/uwp/MegaManX4RecompUWP.appx
./tools/make_release.ps1
```

Install `MegaManX4RecompUWP.appx` through Xbox Device Portal. Add `Dependencies/x64/Microsoft.VCLibs.x64.14.00.appx` if the portal requests it.

## Xbox storage

- **Internal:** place the CUE/BIN files in `LocalState/Game`.
- **External:** select **External Storage** to open `E:\`. A folder picker appears if direct access fails.
- Internal saves use `LocalState`. External saves and settings use the `MegaManX4Recomp` folder beside the game.

## License

See [LICENSE](LICENSE). Mega Man X4 is copyright Capcom. No retail game data is included.

## Credits

- [Matthew Stanley (mstan)](https://github.com/mstan) for MegaManX4Recomp, psxrecomp, and recomp-ui.
- [Daniel Worley (worleydl)](https://github.com/worleydl) for the UWP dependency packages and libuwp.
- [aerisarn](https://github.com/aerisarn/mesa-uwp) for OpenGL support on UWP.
- [SDL](https://github.com/libsdl-org/SDL) contributors for SDL2.
- [Dear ImGui](https://github.com/ocornut/imgui) and its contributors.
- [PCSX-Redux](https://github.com/grumpycoders/pcsx-redux) for OpenBIOS.



Mega Man X4 and all related characters and assets are property of Capcom. This project is not affiliated with or endorsed by Capcom or Microsoft.
