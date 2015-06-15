# MSD

Multistream Downloader is a small tool to download multiple live streams of
audio, probably streamed by Icecast.

## Configuration

`msd` uses a simple DSL for configuration. The following is a sample
`msd_config.exs` configuration file.

```elixir
use MSD.Config

stream "http://localhost:8000/listen", name: "Local"
```

## Building

```
$ env MIX_ENV=prod mix escript.build
```

This creates an escript called "msd".

