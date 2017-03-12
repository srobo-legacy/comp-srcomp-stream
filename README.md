# srcomp-stream

This is a Node application that gives a live stream of events from srcomp.

## Configuration

You can add local configuration by create a `config.local.coffee`, see
`config.local.coffee.example` for an example.

If that file doesn't exist, configuration comes from two environment variables:
`PORT` and `SRCOMP_URL`.

## Running

Run with `node main.js`.

The output from the stream can be seen via `curl`, for example:
 `curl http://localhost:5001`.
