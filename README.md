# transcribe

Transcribe audio and video via [ElevenLabs Scribe](https://elevenlabs.io/) — **diarized** (speaker-separated), with timestamps, defaulting to Portuguese. A self-contained shell command.

Built for transcribing meetings, voice memos and screen recordings — local or straight from a remote machine over SSH. Ships with the companion [`dictate`](#dictate--record-the-microphone), which records the microphone in the terminal and transcribes on the spot.

```bash
transcribe meeting.mp4
  → meeting.transcript/
      ├── meeting.md     # "Speaker 1 [00:03:21]: ..."
      ├── meeting.txt    # plain text
      └── meeting.json   # raw ElevenLabs response
```

## Requirements (macOS)

- **`ELEVENLABS_API_KEY`** — your ElevenLabs key (everyone uses their own)
- **`jq`** — `brew install jq`
- **`ffmpeg`** — `brew install ffmpeg` (only needed for video or large audio)
- `curl` and `ssh` ship with macOS

## Install

```bash
git clone https://github.com/me-thiago/transcribe.git
cd transcribe
./install.sh
```

`install.sh` symlinks `transcribe` and `dictate` into `~/.local/bin`, checks the dependencies and scaffolds a config template. Make sure `~/.local/bin` is on your `PATH` (in `~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## API key

Everyone sets their **own** `ELEVENLABS_API_KEY` (the key never lives in the repo):

```bash
# option A — environment variable (e.g. in ~/.zshrc)
export ELEVENLABS_API_KEY=sk_your_key

# option B — config file (install.sh creates an empty template)
echo 'ELEVENLABS_API_KEY=sk_your_key' > ~/.config/transcribe/env
chmod 600 ~/.config/transcribe/env
```

## Usage

```bash
transcribe meeting.mp4                       # local video → extracts the audio, transcribes
transcribe note.m4a                          # small audio → uploaded directly
transcribe macmini:~/Downloads/call.webm     # remote file → streamed over SSH
transcribe call.mp4 -l en                    # language (default: pt; "auto" detects)
transcribe sales.mp4 -k "Acme,Gauss" -s 4    # boost accuracy + speaker hint
transcribe meeting.mp4 -o ~/Transcripts --open
transcribe --help
```

| Option | Meaning |
|---|---|
| `-l, --lang <code>` | language (default `pt`; ISO code or `auto`) |
| `-o, --out <dir>` | parent dir for the output subfolder |
| `-k, --keyterms <list>` | comma-separated terms/names to boost accuracy |
| `-s, --speakers <n>` | expected number of speakers (better diarization) |
| `--open` | open the output folder when done |

### Output

Always creates the subfolder `<name>.transcript/` (next to the file; in the current dir if remote; or inside `-o <dir>`):

| file | contents |
|---|---|
| `<name>.md` | diarized, with per-segment timestamps |
| `<name>.txt` | plain text |
| `<name>.json` | raw ElevenLabs response (word-level timing) |

## `dictate` — record the microphone

Companion that records the mic right in the terminal and transcribes it (reusing `transcribe`).

```bash
dictate                       # record → q to stop → transcribe. Saves to ~/VoiceMemos/
dictate quick-note            # set the base name
dictate -a memo               # record only, do NOT transcribe
dictate -o ~/Desktop note     # choose where to save
dictate -l en                 # transcription language (default: pt)
dictate -k "Gauss" -s 2       # same accuracy flags as transcribe
dictate -d 1                  # another microphone (--list shows the indices)
```

While recording: press **`q`** to stop & transcribe, or **`Ctrl-C`** to cancel (the recording is discarded). Output: `<dir>/<name>.opus` and, unless `-a`, `<dir>/<name>.transcript/`.

> **Permission:** macOS requires your terminal app to have microphone access (*Settings → Privacy → Microphone*). The first recording prompts for it; if denied, `dictate` tells you nothing was captured.

## How it works

1. **Video / large audio / remote** → `ffmpeg` extracts and compresses just the audio to mono Opus (a 1.7 GB video becomes ~40 MB; the video is discarded). **Small local audio** → uploaded as-is, no ffmpeg.
2. Posts to ElevenLabs `/v1/speech-to-text` (`model_id=scribe_v2`, `diarize=true`, configurable language / keyterms / speakers).
3. Formats the JSON into a readable, diarized transcript (via `jq`), grouped by speaker.

Scribe limits: up to **3 GB** per file and **10 hours** of audio — a whole meeting fits in a single request (diarization isn't consistent across chunks, so the file is never split).

## Notes

- Tested on macOS / Apple Silicon. On Linux, swap `stat -f%z` for `stat -c%s` in the script.
- Remote files use the `host:path` syntax (scp style); the `host` must be in your `~/.ssh/config`.
