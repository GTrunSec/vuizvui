{ lib, runCommand, writeText, python3, libnotify, sfttime }:

let
  name = "display-infos-0.1.0";
  script = writeText (name + "-script") ''
    #!@python3@

    import sys
    import glob
    import subprocess as sub
    import os.path as path
    import statistics as st

    def readint(fn):
        with open(fn, 'r') as f:
            return int(f.read())

    full = 0
    now  = 0
    for bat in glob.iglob("/sys/class/power_supply/BAT*"):

        full += readint(path.join(bat, "energy_full"))
        now  += readint(path.join(bat, "energy_now" ))

    bat = round( now/full, 2 )
    ac = "🗲" if readint("/sys/class/power_supply/AC/online") else ""
    date = sub.run(["date", "+%d.%m. %a %T"], stdout=sub.PIPE).stdout.strip().decode()
    sfttime = sub.run(["${sfttime}/bin/sfttime"], stdout=sub.PIPE).stdout.strip().decode()
    notify = "BAT: {}% {} | {} | {}".format(int(bat*100), ac, date, sfttime)
    sub.run(["@notify-send@", notify])
  '';

in
  with lib; runCommand "display-infos" {
    meta.description = "Script to display time & battery";
  } ''
    substitute ${script} script \
      --replace "@python3@" "${getBin python3}/bin/python3" \
      --replace "@notify-send@" "${getBin libnotify}/bin/notify-send"
    install -D script $out/bin/display-infos
  ''
