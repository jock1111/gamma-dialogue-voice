# G.A.M.M.A. Dialogue Voice-over 1.0.0

Spoken dialogue for S.T.A.L.K.E.R. GAMMA's conversation lines in Russian, Ukrainian or English, with the game text and subtitles left in English.

Three separate packs, 5,555 clips each, an MCM page and a launcher that mounts exactly one language at a time.

## Download

GitHub limits a release asset to 2 GiB, so the 3.6 GB package is split into four parts. Download all four into the same folder.

- `GAMMA-Dialogue-Voice-1.0.0.zip.part1`
- `GAMMA-Dialogue-Voice-1.0.0.zip.part2`
- `GAMMA-Dialogue-Voice-1.0.0.zip.part3`
- `GAMMA-Dialogue-Voice-1.0.0.zip.part4`

Rejoin them:

**Windows (cmd):**

```bat
copy /b GAMMA-Dialogue-Voice-1.0.0.zip.part1 + GAMMA-Dialogue-Voice-1.0.0.zip.part2 + GAMMA-Dialogue-Voice-1.0.0.zip.part3 + GAMMA-Dialogue-Voice-1.0.0.zip.part4 GAMMA-Dialogue-Voice-1.0.0.zip
```

**PowerShell:**

```powershell
cmd /c 'copy /b "GAMMA-Dialogue-Voice-1.0.0.zip.part1" + "GAMMA-Dialogue-Voice-1.0.0.zip.part2" + "GAMMA-Dialogue-Voice-1.0.0.zip.part3" + "GAMMA-Dialogue-Voice-1.0.0.zip.part4" "GAMMA-Dialogue-Voice-1.0.0.zip"'
```

**Linux / macOS:**

```bash
cat GAMMA-Dialogue-Voice-1.0.0.zip.part1 GAMMA-Dialogue-Voice-1.0.0.zip.part2 GAMMA-Dialogue-Voice-1.0.0.zip.part3 GAMMA-Dialogue-Voice-1.0.0.zip.part4 > GAMMA-Dialogue-Voice-1.0.0.zip
```

Verify before extracting:

```text
SHA-256: c96fbfe6b029cdf2913f96c88e5da5b3321fe723326bf111cd6f556ca166ae8a
Size:    3,632,349,338 bytes
```

## Install

1. Close GAMMA and Mod Organizer 2.
2. Extract the rejoined zip and run `Install.ps1` (right-click -> **Run with PowerShell**). Point it at the folder containing `ModOrganizer.exe`.
3. Start the game from the new **GAMMA - Dialogue Voice** shortcut.
4. Switch languages later in **MCM -> Dialogue voice**, then relaunch from the same shortcut.

The installer backs up `profiles\G.A.M.M.A\modlist.txt`, enables the Russian pack by default and creates the desktop shortcut. `-Language uk` and `-Language en` are also available.

## Notes

- Synthetic speech, not voice actors: Silero for Russian/Ukrainian, Kokoro-82M for English, Supertonic 3 character presets.
- Ukrainian follows HalavicH's GAMMA localization where it exists; remaining lines were machine-translated and hand-corrected.
- The English pack has 16 lines translated from Russian because GAMMA has no English text for them.
- Only conversation/dialogue lines are voiced; ambient chatter and combat barks are separate GAMMA mods.
- Non-commercial fan release. Do not sell it. See `LICENSE.txt` in the repository.

## Credits

Silero Models, Kokoro-82M, Supertonic 3, HalavicH's Ukrainian localization, Helsinki-NLP OPUS-MT, and GSC Game World / GAMMA / Anomaly for the original dialogue and game content. Full links and licences are in the README.
