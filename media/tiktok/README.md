# Reference videos drop folder

Put downloaded TikTok reference videos here as `.mp4` files, one per video, named
by their short code so they can be matched back to the links:

```
media/tiktok/ZPLRw3ubt.mp4
media/tiktok/ZPLRwG4Co.mp4
media/tiktok/ZPLRwXx6J.mp4
media/tiktok/ZPLRwqGrt.mp4
media/tiktok/ZPLRKPFKv.mp4
media/tiktok/ZPLRKfLP1.mp4
media/tiktok/ZPLRKjEf2.mp4
```

How to get the files: open each link on a phone or computer, use TikTok's own
"Save video" (watermarked is fine), or any TikTok downloader site, then add the
files here and push to the `claude/alien-system-research` branch.

They are processed with `tools/watch_video.py`, which extracts frames into a
contact sheet, pulls the audio, and writes a transcript into
`media/tiktok/out/<code>/`. Outputs are committed so the notes are reproducible.
