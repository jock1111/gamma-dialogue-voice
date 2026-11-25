# G.A.M.M.A. Dialogue Voice-over 1.0.0

**Download:** [v1.0.0 release](https://github.com/jock1111/gamma-dialogue-voice/releases/tag/v1.0.0) - four parts, rejoin commands below.
**Size:** about 3.6 GB (`GAMMA-Dialogue-Voice-1.0.0.zip`, 3,632,349,338 bytes)
**SHA-256:** `c96fbfe6b029cdf2913f96c88e5da5b3321fe723326bf111cd6f556ca166ae8a`

GAMMA's conversations are text-only by default. This adds spoken dialogue for those lines in three separate packs - Russian, Ukrainian or English - while the game text and subtitles stay in English. Pick a language in MCM, restart once, done.

## Download and rejoin

GitHub limits each release asset to 2 GiB, so the package is split into four parts. Download all four, put them in one folder, then:

**Windows (cmd):**

```bat
copy /b GAMMA-Dialogue-Voice-1.0.0.zip.part1 + GAMMA-Dialogue-Voice-1.0.0.zip.part2 + GAMMA-Dialogue-Voice-1.0.0.zip.part3 + GAMMA-Dialogue-Voice-1.0.0.zip.part4 GAMMA-Dialogue-Voice-1.0.0.zip
```

**Linux / macOS:**

```bash
cat GAMMA-Dialogue-Voice-1.0.0.zip.part1 GAMMA-Dialogue-Voice-1.0.0.zip.part2 GAMMA-Dialogue-Voice-1.0.0.zip.part3 GAMMA-Dialogue-Voice-1.0.0.zip.part4 > GAMMA-Dialogue-Voice-1.0.0.zip
```

Check the SHA-256 before extracting.

## What's in it

- 5,555 dialogue clips per language: Russian (~1.3 GB), Ukrainian (~1.3 GB), English (~0.9 GB).
- An MCM page under **Dialogue voice** for language and 0-200% volume.
- A launcher that mounts exactly one pack at a time; switching takes one restart.
- Nothing else is touched: saves, graphics, UI language, ambient barks, combat lines and other mods stay as they are.

The three languages are independent packs. For English text with Russian or Ukrainian audio you only need one of those two; the English pack is only if you also want spoken English.

## Install

1. Close GAMMA and Mod Organizer 2.
2. Rejoin the two parts, verify the SHA-256, and extract the zip.
3. Run `Install.ps1` (right-click -> **Run with PowerShell**). Point it at the folder containing `ModOrganizer.exe`.
4. Start the game from the new **GAMMA - Dialogue Voice** shortcut.
5. To switch later: **MCM -> Dialogue voice**, pick a language, apply, quit, then relaunch from the same shortcut.

If Windows blocked the download, right-click the zip -> **Properties** -> **Unblock** before extracting. The installer backs up `profiles\G.A.M.M.A\modlist.txt` and enables the Russian pack by default. Use `-Language uk` or `-Language en` to start with another one.

## What it sounds like

Synthetic speech, not voice actors: Silero for Russian/Ukrainian, Kokoro-82M for English, Supertonic 3 character presets. Ukrainian follows HalavicH's GAMMA localization where it exists; the rest is machine-translated and hand-corrected. The English pack has 16 lines translated from Russian because GAMMA has no English text for them.

## Notes

- Only conversation/dialogue lines are voiced. Ambient chatter and combat barks are separate GAMMA mods.
- One language at a time, by design - the engine mounts one dialogue sound set.
- Non-commercial fan release (Silero is CC BY-NC-SA 4.0). Do not sell it.
- Requires GAMMA 0.9.2 with the standard `G.A.M.M.A` Mod Organizer 2 profile.
- Audio stays at 44.1 kHz mono; the volume slider rewrites only the Ogg gain header, never the audio.

## Credits

Silero Models, Kokoro-82M, Supertonic 3, HalavicH's Ukrainian localization, Helsinki-NLP OPUS-MT, and GSC Game World / GAMMA / Anomaly for the original dialogue and game content. Full links and licences are in the README.

*No video yet - I will add a short comparison clip when I get a clean recording.*
