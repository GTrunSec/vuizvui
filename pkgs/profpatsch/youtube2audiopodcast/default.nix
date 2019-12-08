{ pkgs, lib, writeExecline, getBins, runInEmptyEnv, sandbox }:

let
  bins = getBins pkgs.hello [ "hello" ]
    // getBins pkgs.coreutils [ "echo" "env" "cat" "printf" "wc" "tr" "cut" "mktemp" ]
    // getBins pkgs.youtube-dl [ "youtube-dl" ]
    // getBins pkgs.s6-networking [ "s6-tcpserver" ]
    // getBins pkgs.execline [ "fdmove" "backtick" "importas" "if" "redirfd" "pipeline" ];

  youtube-dl-audio = writeExecline "youtube-dl-audio" { readNArgs = 1; } [
    bins.youtube-dl
      "--verbose"
      "--extract-audio"
      "--audio-format" "opus"
      "--output" "./audio.opus" "https://www.youtube.com/watch?v=\${1}"
  ];

  # minimal CGI request parser for use as UCSPI middleware
  yolo-cgi = pkgs.writers.writePython3 "yolo-cgi" {} ''
    import sys
    import os


    def parse_ass(bool):
        if not bool:
            sys.exit(1)


    inbuf = sys.stdin.buffer

    first_line = inbuf.readline().rstrip(b"\n").split(sep=b" ")
    parse_ass(len(first_line) == 3)
    parse_ass(first_line[2].startswith(b"HTTP/"))

    os.environb[b"REQUEST_METHOD"] = first_line[0]
    os.environb[b"REQUEST_URI"] = first_line[1]

    cmd = sys.argv[1]
    args = sys.argv[2:] if len(sys.argv) > 2 else []
    os.execlp(cmd, cmd, *args)
  '';

  envvar-to-stdin = writeExecline "envvar-to-stdin" { readNArgs = 1; } [
    "importas" "VAR" "$1"
    "pipeline" [ bins.printf "%s" "$VAR" ] "$@"
  ];

  serve-audio = writeExecline "audio-server" {} [
    (runInEmptyEnv [])
    bins.s6-tcpserver "::1" "8888"
    (sandbox { extraMounts = [ "/etc" ]; })
    yolo-cgi
    # bins.fdmove "1" "2" bins.env
    bins.${"if"} [
      # remove leading slash
      bins.backtick "-i" "yt-video-id" [
        envvar-to-stdin "REQUEST_URI"
        bins.cut "-c2-"
      ]
      bins.importas "yt-video-id" "yt-video-id"
      bins.fdmove "-c" "1" "2"
      youtube-dl-audio "$yt-video-id"
    ]
    bins.backtick "-i" "-n" "filesize" [
      bins.redirfd "-r" "0" "./audio.opus"
      bins.wc "--bytes"
    ]
    bins.importas "filesize" "filesize"
    bins.${"if"} [ bins.printf ''
      HTTP/1.1 200 OK
      Content-Type: audio/ogg
      Content-Length: %u

    '' "$filesize" ]
    bins.redirfd "-r" "0" "./audio.opus" bins.cat
  ];

# in printFeed
in serve-audio
# in youtube-dl-audio