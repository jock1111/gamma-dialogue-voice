# G.A.M.M.A. Dialogue Voice-over

**Download:** [v1.0.0 release](https://github.com/jock1111/gamma-dialogue-voice/releases/tag/v1.0.0)

Spoken dialogue for S.T.A.L.K.E.R. GAMMA's conversation lines in **Russian**, **Ukrainian** or **English**, while the game text and subtitles stay in English.

Three separate packs, 5,555 voice clips each, plus an MCM page and a launcher that mounts exactly one language at a time. Existing GAMMA barks, combat lines, saves, graphics and other mods are untouched.

## Download and rejoin

GitHub limits a release asset to 2 GiB, so the 3.6 GB package is attached as two parts. Download both into the same folder, then rejoin them:

**Windows (cmd):**

```bat
copy /b GAMMA-Dialogue-Voice-1.0.0.zip.part1 + GAMMA-Dialogue-Voice-1.0.0.zip.part2 GAMMA-Dialogue-Voice-1.0.0.zip
```

**PowerShell:**

```powershell
cmd /c 'copy /b "GAMMA-Dialogue-Voice-1.0.0.zip.part1" + "GAMMA-Dialogue-Voice-1.0.0.zip.part2" "GAMMA-Dialogue-Voice-1.0.0.zip"'
```

**Linux / macOS:**

```bash
cat GAMMA-Dialogue-Voice-1.0.0.zip.part1 GAMMA-Dialogue-Voice-1.0.0.zip.part2 > GAMMA-Dialogue-Voice-1.0.0.zip
```

Verify the result before extracting:

```text
SHA-256: c96fbfe6b029cdf2913f96c88e5da5b3321fe723326bf111cd6f556ca166ae8a
Size:    3,632,349,338 bytes
```

## What's in the package

- 5,555 dialogue clips per language: Russian (~1.3 GB), Ukrainian (~1.3 GB), English (~0.9 GB).
- An MCM page under **Dialogue voice** for language and 0-200% volume.
- A launcher that mounts exactly one pack at a time; switching takes one restart.
- Nothing else is touched: saves, graphics, UI language, ambient barks, combat lines and other mods stay as they are.

The three languages are independent packs. For English text with Russian or Ukrainian audio you only need one of those two; the English pack is only if you also want spoken English.

## Requirements

- S.T.A.L.K.E.R. GAMMA 0.9.2 with the standard `G.A.M.M.A` Mod Organizer 2 profile.
- Windows 10/11 and PowerShell 5.1.
- About 4 GB free on the GAMMA drive.

## Install

1. Close GAMMA and Mod Organizer 2.
2. Rejoin the two parts, verify the SHA-256, and extract the zip.
3. Right-click `Install.ps1` and choose **Run with PowerShell**.
   If Windows blocks it, open PowerShell in that folder and run:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
   ```

   The installer asks for the GAMMA folder (the one containing `ModOrganizer.exe`), copies the mods and launcher, backs up `profiles\G.A.M.M.A\modlist.txt`, enables the Russian pack, and creates a **GAMMA - Dialogue Voice** desktop shortcut.
4. Start the game from **GAMMA - Dialogue Voice**.

Non-default options:

```powershell
.\Install.ps1 -GammaRoot "D:\Games\STALKER GAMMA\GAMMA" -Language uk -NoDesktopShortcut
```

## Switching language

1. In game: **MCM -> Dialogue voice -> Dialogue voice language** and pick Russian, Ukrainian or English. Apply.
2. Quit the game and Mod Organizer 2.
3. Relaunch from **GAMMA - Dialogue Voice**.

Starting from the normal GAMMA shortcut (or `ModOrganizer.exe`) keeps whichever pack was mounted last. Double-clicking `Start GAMMA (Dialogue Voice).cmd` opens a language picker instead.

## Volume

**MCM -> Dialogue voice -> Dialogue voice volume** (0-200%, default 100). It is applied to the selected pack on the next launch. The gain is written into the Ogg header, so nothing is re-encoded and repeated changes are lossless.

## Notes

- These are synthetic voices, not a studio dub. Russian and Ukrainian use Silero, English uses Kokoro-82M, and character voices use Supertonic 3 presets. Expect TTS delivery.
- Ukrainian follows HalavicH's GAMMA localization where a match exists. Remaining lines were machine-translated with OPUS-MT and manually corrected.
- The English pack contains 16 lines translated from Russian because GAMMA has no English text for them.
- No lip sync is added; X-Ray does not animate dialogue from audio.
- The packs cover conversation/dialogue lines only. Ambient chatter, combat barks and the player's voiced actor are separate GAMMA mods.

## Repository layout

The repository contains the installer, the MCM selector and the launcher source. The voice packs are only in the release assets because of their size.

- `src/Install.ps1` - installer used by the release package
- `src/mods/G.A.M.M.A. Dialogue Voice Language` - MCM page and language selector
- `src/tools/dialogue_voice` - launcher, volume tool and Ogg gain helper
- `src/Start GAMMA (Dialogue Voice).cmd` - manual language picker

## Credits and licence

Fan-made, non-commercial release. Do not sell it. See `LICENSE.txt`.

- Silero Models - Russian/Ukrainian TTS, CC BY-NC-SA 4.0 - https://github.com/snakers4/silero-models
- Kokoro-82M - English TTS, Apache-2.0 - https://huggingface.co/hexgrad/Kokoro-82M
- Supertonic 3 - character voice presets, OpenRAIL-M - https://huggingface.co/Supertone/supertonic-3
- HalavicH - Ukrainian GAMMA localization - https://github.com/HalavicH/stalker-gamma-ukr-localization
- Helsinki-NLP OPUS-MT ru-uk - fallback translation, CC BY 4.0 - https://huggingface.co/Helsinki-NLP/opus-mt-ru-uk
- GSC Game World / GAMMA / Anomaly - original dialogue and game content. You need your own legal copy of the game.

## Uninstall

1. Close GAMMA and Mod Organizer 2.
2. Delete these folders from `GAMMA\mods`: `G.A.M.M.A. Dialogue Voice Language`, `Russian Dialogue Voice-over`, `Ukrainian Dialogue Voice-over`, `English Dialogue Voice-over`.
3. Delete `GAMMA\tools\dialogue_voice` and `GAMMA\Start GAMMA (Dialogue Voice).cmd`, plus the desktop shortcut.
4. Restore `profiles\G.A.M.M.A\modlist.txt` from `tools\dialogue_voice\backups`, or remove the four mod lines in MO2.

## Troubleshooting

- **"Close GAMMA and Mod Organizer 2 before switching"** - the launcher refuses to edit the profile while either is running.
- **Nothing changed after picking a language** - launch from **GAMMA - Dialogue Voice**, not the normal shortcut.
- **What did the launcher do?** - see `GAMMA\tools\dialogue_voice\launcher.log`.
- **Check the current state** - run `Start GAMMA (Dialogue Voice).cmd -Status` to print the selected language, mounted pack and clip counts.
