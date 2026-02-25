# Hls Proxy
hls-proxy is a tool that allows for easy downloading or mirroring of remote HLS streams.

## How to use

### Mirroring a remote live HLS stream
```shell
./start-proxy.sh http://server.com/live-stream.m3u8 -o .
```
The content of `http://server.com/live-stream.m3u8` will be downloaded to the output directory (specified by `-o`). The playlist will be constantly refreshed and when new content is available it will be also downloaded while old content will be removed. This will practically mirror the remote hls stream in the output directory (`-o`). The downloaded stream itself can be served using any HTTP server.

### Downloading a remote live HLS stream
```shell
./start-proxy.sh http://server.com/live-stream.m3u8 -o . -d
```
This will behave just as the above command except that old content will not be deleted effectively downloading the live stream in the output directory (`-o`). This is useful for downloading a long sample of a live stream that can latter be used for debugging and testing puposes.

### Downloading a remote VoD HLS stream
```shell
./start-proxy.sh http://server.com/vod-stream.m3u8 -o . -d
```
The VoD stream will be downloaded in the output directory (`-o`). The proxy detects `#EXT-X-ENDLIST` in the playlist and **stops automatically** once all segments have been downloaded. For VoD streams the `-d` parameter is effectively ignored. In this example it is provided for clarity.

### Batch downloading via webhook
`download.sh` is a helper script designed to be triggered via [webhook](https://github.com/adnanh/webhook). It receives a video ID and duration, and downloads the HLS stream into a structured directory.

```shell
# Manual usage
OUTDIR=/var/hls ./download.sh <video_id> <minutes> [options] [playlist_url]
```

Example webhook configuration (`hooks.json`):
```json
[
  {
    "id": "clone-m3u8",
    "execute-command": "download.sh",
    "pass-environment-to-command": [
      { "source": "string", "envname": "OUTDIR", "name": "/mnt/volume_ams3_01/videos/hls" }
    ],
    "pass-arguments-to-command": [
      { "source": "payload", "name": "ID" },
      { "source": "payload", "name": "duration" },
      { "source": "payload", "name": "options" },
      { "source": "payload", "name": "playlist" }
    ],
    "command-working-directory": "/root/hls-proxy"
  }
]
```

### Running webhook as a systemd service

Instead of running webhook with `nohup`, create a systemd unit for automatic restarts and log management:

```ini
# /etc/systemd/system/webhook.service
[Unit]
Description=Webhook HLS Proxy
After=network.target

[Service]
ExecStart=/root/go/bin/webhook -hooks /root/hooks.json -verbose
WorkingDirectory=/root/hls-proxy
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```shell
systemctl daemon-reload
systemctl enable --now webhook
# Check logs with: journalctl -u webhook -f
```

## Supported features
 * All HLS v3 features are supported including Live, VoD, ABR, and encrypted streams
 * VoD playlists (with `#EXT-X-ENDLIST`) are detected and the proxy stops automatically after downloading all segments
 * ABR/variant playlists: all quality levels and alternate tracks (audio, subtitles) are downloaded in parallel

## Dependencies
`hls-proxy` requires python-2.7, Twisted-13.2 and zope.interface. `start-proxy.sh` will download and setup Twisted. The only things that need to be installed manually are python and [zope.interface](https://pypi.python.org/pypi/zope.interface#download). Most linux distros provide these as packages. For detailed information on how to install them refer to your distro manual. Alternatively you can use `pip` or `pipenv` (a `Pipfile` is provided).

## License
MIT
