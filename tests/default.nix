{ system ? builtins.currentSystem
, nixpkgsPath ? import ../nixpkgs-path.nix
, ...
}:

let
  callTest = path: import ./make-test.nix (import path) {
    inherit system nixpkgsPath;
  };

in {
  aszlig.dnyarri.luks2-bcache = callTest ./aszlig/dnyarri/luks2-bcache.nix;
  aszlig.programs.psi = callTest aszlig/programs/psi.nix;
  games = {
    starbound = callTest ./games/starbound.nix;
  };
  programs = {
    gnupg = callTest ./programs/gnupg;
  };
  sandbox = callTest ./sandbox.nix;
  system = {
    kernel.bfq = callTest ./system/kernel/bfq.nix;
  };
}
