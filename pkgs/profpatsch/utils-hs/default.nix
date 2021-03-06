{ lib, fetchFromGitHub, haskellPackages, haskell }:

let
  utilsSrc = fetchFromGitHub {
    owner = "Profpatsch";
    repo = "utils.hs";
    rev = "163ca78213a9fd0ecaa015051cb95d66d7019343";
    sha256 = "0bvw5ps9v9a64q445jxlcfn2l43mkg061hm3n150kkfwzr13vdm8";
  };
  version = "git";

  # TODO: make it possible to override the hps fixpoint again
  # without removing the overrides in here
  hps =
    let hlib = haskell.lib; in
    haskellPackages.override {
      overrides = (hself: hsuper: {

        # shell stub
        shellFor = f: # self -> { buildDepends, buildTools }
          let args = f hself;
          in hsuper.mkDerivation {
            pname = "pkg-env";
            src = "/dev/null";
            version = "none";
            license = "none";
            inherit (args) buildDepends;
            buildTools = with hself; [
              ghcid
              cabal-install
              hpack
              (hoogleLocal {
                packages = args.buildDepends;
              })
            ] ++ args.buildTools or [];
          };

        # hoogleLocal should never use the builders
        hoogleLocal = args: (hsuper.hoogleLocal args).overrideAttrs (_: {
          preferLocalBuild = true;
          allowSubstitutes = false;
        });

        these = hlib.doJailbreak hsuper.these;

        hnix = hlib.overrideCabal
          (hsuper.hnix.override {
            inherit (hself) these;
          }) (old: {
          src = fetchFromGitHub {
            owner = "haskell-nix";
            repo = "hnix";
            rev = "e7efbb4f0624e86109acd818942c8cd18a7d9d3d";
            sha256 = "0dismb9vl5fxynasc2kv5baqyzp6gpyybmd5p9g1hlcq3p7pfi24";
          };
          broken = false;
          buildDepends = old.buildDepends or [] ++ (with hself; [
            dependent-sum prettyprinter (hlib.doJailbreak ref-tf)
          ]);
        });
      });
    };

  haskellDrv = { name, subfolder, deps }: hps.mkDerivation {
    pname = name;
    inherit version;
    src = "${utilsSrc}/${subfolder}";
    # TODO make utils.hs buildable from the project itself
    # src = "${/home/philip/code/haskell/utils.hs}/${subfolder}";
    license = lib.licenses.gpl3;
    isExecutable = true;
    hydraPlatforms = [ "x86_64-linux" ];
    buildDepends = deps;

    # justStaticExecutables
    enableSharedExecutables = false;
    enableLibraryProfiling = false;
    isLibrary = false;
    doHaddock = false;
    postFixup = "rm -rf $out/lib $out/nix-support $out/share/doc";
  };


  nix-gen = haskellDrv {
    name = "nix-gen";
    subfolder = "nix-gen";
    deps = with hps; [ hnix ansi-wl-pprint protolude data-fix ];
  };

  until = haskellDrv {
    name = "until";
    subfolder = "until";
    deps = with hps; [ optparse-applicative data-fix time];
  };

  watch-server = haskellDrv {
    name = "watch-server";
    subfolder = "watch-server";
    deps = with hps; [ directory protolude fsnotify regex-tdfa optparse-generic ];
  };

in {
  inherit nix-gen until watch-server;
  haskellPackages = hps;
}
