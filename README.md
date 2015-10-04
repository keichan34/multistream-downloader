# MSD

Multistream Downloader is a small tool to download multiple live streams of
audio, probably streamed by Icecast.

## Configuration

A configuration is required to tell MSD where the config files and output files
are. Copy `config/config.example.exs` to `config/config.exs`.

`msd` uses a simple DSL for configuration. The following is a sample
`msd_config.exs` configuration file.

```elixir
use MSD.Config

stream "http://localhost:8000/listen", name: "Local"
```
