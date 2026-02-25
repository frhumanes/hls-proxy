# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

hls-proxy is a Python 2.7 tool for downloading or mirroring remote HLS (HTTP Live Streaming) streams. It supports HLS v3 features including Live, VoD, ABR (Adaptive Bitrate), and encrypted streams (AES-128, SAMPLE-AES).

## Running

```shell
# Via start-proxy.sh (auto-downloads Twisted-13.2.0 if missing)
./start-proxy.sh <playlist_url> -o <output_dir> [-d] [-v] [--referer <url>]

# Via pipenv
pipenv run ./hlsproxy.py <playlist_url> -o <output_dir> [-d] [-v]

# Timed download helper
OUTDIR=/var/hls ./download.sh <id> [minutes] [options] [playlist_url]
```

**Key flags:** `-d` download mode (don't delete old segments), `-v` verbose, `-o` output directory, `--referer` set HTTP Referer header, `--dump-durations` compare segment durations, `--save-individual-playlists` save per-sequence playlists.

## Dependencies

- Python 2.7 (uses `print` statements, `urlparse`, `iteritems()`)
- Twisted (async HTTP via `twisted.web.client.Agent`, `twisted.internet.task.react`)
- pyopenssl, service-identity (for HTTPS)
- Managed via Pipfile/pipenv or auto-downloaded Twisted-13.2.0 via `start-proxy.sh`

## Architecture

Single-file application in `hlsproxy.py` with these key classes:

- **HlsPlaylist** — M3U8 parser and serializer. Parses playlist text via `fromStr()`, outputs via `toStr()`. Handles both segment playlists (items) and master/variant playlists (variants + medias).
- **HlsProxy** — Core proxy logic. Periodically fetches the remote playlist (`refreshPlaylist`), downloads new segments, removes stale ones (mirror mode), and writes a local client-facing playlist. For variant/ABR playlists, spawns sub-proxies per bandwidth/media track via `start_subproxy()`.
- **HttpReqQ** — Sequential HTTP request queue wrapping Twisted's Agent. Ensures one request at a time with a 3-minute timeout per request.
- **Data classes** — `HlsItem` (segment), `HlsVarian` (variant stream info), `HlsMedia` (alternate media track), `HlsEncryption` (key info).

**Flow:** `main()` → `argparse` → `react(runProxy)` → `HlsProxy.run()` → polls playlist on `targetDuration` interval → downloads segments → writes local `.m3u8` and `.ts` files. For VoD playlists (with `#EXT-X-ENDLIST`), the proxy stops automatically when all fragments are downloaded. For variant playlists, `DeferredList` waits for all sub-proxies to finish.

## Production Deployment

The tool is triggered via [webhook](https://github.com/adnanh/webhook) (Go) configured in `hooks.json`. The webhook service should run as a systemd unit (`/etc/systemd/system/webhook.service`) for automatic restarts and log management. See README.md for the full configuration.
