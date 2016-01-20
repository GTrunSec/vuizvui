{ config, pkgs, lib, ... }:

{
  nixpkgs.config = {
    pulseaudio = true;

    allowUnfree = true;

    systemd = {
      enableKDbus = true;
    };

    conky = {
      weatherMetarSupport = true;
      mpdSupport = true;
      wirelessSupport = true;
      x11Support = false;
    };

    firefox = {
      enableGTK3 = true;
      enableOfficialBranding = true;
    };

    virtualbox = {
      enableExtensionPack = true;
    };

    mpv = {
      youtubeSupport = true;
    };
  };

  environment.systemPackages = with pkgs; [
    #(lib.overrideDerivation mcabber (o: { buildInputs = (o.buildInputs or []) ++ lib.singleton pkgs.gpgme; }))
    abook
    accountsservice
    apg
    arandr
    arc-gtk-theme
    ascii
    aspell
    aspellDicts.de
    aspellDicts.en
    atftp
    atom
    attic
    audacity
    axel
    bc
    biber
    bind
    brotli
    bup
    cacert
    cataclysm-dda
    cava
    ccrypt
    chromaprint
    chromium
    cifs_utils
    cmake
    cmatrix
    colordiff
    compton
    conky
    cryptsetup
    ctodo
    cuetools
    darkstat
    dcfldd
    ddrescue
    dhcping
    dmenu
    dmidecode
    docker
    dos2unix
    duff
    duff
    dynamic-colors
    e2fsprogs
    easytag
    electrum
    emacs
    enhanced-ctorrent
    ethtool
    evince
    fbida
    fdupes
    fdupes
    feh
    ffmpeg-full
    figlet
    file
    firefox
    flac
    foremost
    freerdpUnstable
    gajim
    gcc
    gdb
    ghostscript
    gimp
    gitAndTools.git-annex
    gitAndTools.git-extras
    gitAndTools.git-remote-hg
    gitAndTools.git2cl
    gitAndTools.gitFastExport
    gitAndTools.gitFull
    gitAndTools.gitRemoteGcrypt
    gitAndTools.gitSVN
    gitAndTools.gitflow
    gitAndTools.svn2git
    gitAndTools.tig
    glxinfo
    gnome3.dconf
    gnome3.defaultIconTheme
    gnome3.gnome_themes_standard
    gnufdisk
    gnupg
    gnupg1compat
    gource
    gparted
    gpgme
    gpicview
    gptfdisk
    graphviz
    gstreamer
    hdparm
    heimdall
    hexedit
    hplipWithPlugin
    htop
    i3lock
    i3status
    icedtea_web
    iftop
    imagemagick
    impressive
    inkscape
    iotop
    ipfs
    iptraf-ng
    ipv6calc
    jfsutils
    john
    jwhois
    keepassx
    kpcli
    lftp
    libarchive
    libreoffice
    lm_sensors
    lsof
    lxappearance
    lxc
    lynx
    manpages
    mc
    mcabber
    mdp
    mediainfo
    mmv
    monkeysAudio
    mono
    monodevelop
    mosh
    mp3gain
    mpc_cli
    mpv
    mtr
    ncdu
    ncmpcpp
    nethack
    nethogs
    netkittftp
    netrw
    netsniff-ng
    nitrogen
    nix-prefetch-scripts
    nixops
    nload
    nmap
    ntfs3g
    ntfsprogs
    ntopng
    numix-icon-theme
    obnam
    openssl
    p7zip
    pandoc
    paperkey
    pass
    pasystray
    pavucontrol
    pciutils
    picard
    posix_man_pages
    powertop
    profanity
    profile-cleaner
    profile-sync-daemon
    pv
    python
    python2
    python3
    python34Packages.hovercraft
    pythonPackages.livestreamer
    pythonPackages.rainbowstream
    qrencode
    recode
    reiserfsprogs
    rofi
    ruby
    safecopy
    screen
    scrot
    shntool
    silver-searcher
    sleuthkit
    smartmontools
    sox
    spek
    ssdeep
    stow
    strace
    super-user-spark
    surfraw
    taskwarrior
    telnet
    testdisk
    texLiveFull
    texmacs
    tftp-hpa
    tldr
    tmux
    toilet
    tomahawk
    transmission_remote_gtk
    tree
    tribler
    tty-clock
    udevil
    units
    unrar
    unzip
    valgrind
    vanilla-dmz
    vim_configurable
    virtmanager
    vit
    vlc
    vlock
    vnstat
    vorbisTools
    vorbisgain
    w3m
    wavpack
    weechat
    wget
    which
    wireshark
    xfsprogs
    xlibs.xev
    xmpp-client
    xpdf
    xpra
    xscreensaver
    youtube-dl
    zathura
    zbar
    zip
    zotero
    zsync
  ];
}
