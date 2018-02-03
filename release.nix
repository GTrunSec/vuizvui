{ vuizvuiSrc ? null
, nixpkgsSrc ? <nixpkgs>
, supportedSystems ? [ "i686-linux" "x86_64-linux" ]
}:

let
  nixpkgsRevCount = nixpkgsSrc.revCount or 12345;
  nixpkgsShortRev = nixpkgsSrc.shortRev or "abcdefg";
  nixpkgsVersion = "pre${toString nixpkgsRevCount}.${nixpkgsShortRev}-vuizvui";

  nixpkgs = nixpkgsSrc;

  vuizvuiRevCount = vuizvuiSrc.revCount or 12345;
  vuizvuiShortRev = vuizvuiSrc.shortRev or "abcdefg";
  vuizvuiVersion = "pre${toString vuizvuiRevCount}.${vuizvuiShortRev}";

  vuizvui = let
    patchedVuizvui = (import nixpkgs {}).stdenv.mkDerivation {
      name = "vuizvui-${vuizvuiVersion}";
      inherit nixpkgsVersion;
      src = vuizvuiSrc;
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        cp -r --no-preserve=ownership "${nixpkgs}/" nixpkgs
        chmod -R u+w nixpkgs
        echo -n "$nixpkgsVersion" > nixpkgs/.version-suffix
        echo "echo '$nixpkgsVersion'" \
          > nixpkgs/nixos/modules/installer/tools/get-version-suffix
        echo -n ${nixpkgs.rev or nixpkgsShortRev} > nixpkgs/.git-revision
        echo './nixpkgs' > nixpkgs-path.nix
        cp -r . "$out"
      '';
    };
  in if vuizvuiSrc == null then ./. else patchedVuizvui;

  system = "x86_64-linux";
  pkgsUpstream = import nixpkgs { inherit system; };
  root = import vuizvui { inherit system; };

  mpath = if vuizvuiSrc == null then ./machines else "${vuizvui}/machines";
  allMachines = import mpath;

  allTests = with import ./lib; getVuizvuiTests ({
    inherit system nixpkgs;
    excludeVuizvuiGames = true;
  } // pkgsUpstream.lib.optionalAttrs (vuizvuiSrc != null) {
    vuizvuiTests = "${vuizvui}/tests";
  });

  pkgs = with pkgsUpstream.lib; let
    noGames = flip removeAttrs [ "games" ];
    releaseLib = import "${nixpkgs}/pkgs/top-level/release-lib.nix" {
      inherit supportedSystems;
      packageSet = attrs: noGames (import vuizvui attrs).pkgs;
      nixpkgsArgs.config = {
        allowUnfree = false;
        inHydra = true;
        allowBroken = true;
      };
    };

    packagePlatforms = mapAttrs (name: value: let
      brokenOr = if value.meta.broken or false then const [] else id;
      platforms = value.meta.hydraPlatforms or (value.meta.platforms or []);
      isRecursive = value.recurseForDerivations or false
                 || value.recurseForRelease or false;
      result = if isDerivation value then brokenOr platforms
               else if isRecursive then packagePlatforms value
               else [];
      tried = builtins.tryEval result;
    in if tried.success then tried.value else []);

  in with releaseLib; mapTestOn (packagePlatforms releaseLib.pkgs);

in with pkgsUpstream.lib; with builtins; {

  machines = let
    # We need to expose all the real builds within vuizvui.lazyPackages to make
    # sure they don't get garbage collected on the Hydra instance.
    wrapLazy = machine: pkgsUpstream.runCommand machine.build.name {
      fakeRuntimeDeps = machine.eval.config.vuizvui.lazyPackages;
      product = machine.build;
    } ''
      mkdir -p "$out/nix-support"
      echo "$product" > "$out/nix-support/fake-runtime-dependencies"
      for i in $fakeRuntimeDeps; do
        echo "$i" >> "$out/nix-support/fake-runtime-dependencies"
      done
    '';
  in mapAttrsRecursiveCond (m: !(m ? eval)) (const wrapLazy) allMachines;

  isoImages = let
    buildIso = attrs: let
      name = attrs.iso.config.networking.hostName;
      cond = attrs.iso.config.vuizvui.createISO;
    in if !cond then {} else pkgsUpstream.runCommand "vuizvui-iso-${name}" {
      meta.description = "Live CD/USB stick of ${name}";
      iso = attrs.iso.config.system.build.isoImage;
      passthru.config = attrs.iso.config;
    } ''
      mkdir -p "$out/nix-support"
      echo "file iso" $iso/iso/*.iso* \
        >> "$out/nix-support/hydra-build-products"
    '';
  in mapAttrsRecursiveCond (m: !(m ? iso)) (const buildIso) allMachines;

  tests = let
    machineList = collect (m: m ? eval) allMachines;
    activatedTests = unique (concatMap (machine:
      machine.eval.config.vuizvui.requiresTests
    ) machineList);
    mkTest = path: setAttrByPath path (getAttrFromPath path allTests);
  in fold recursiveUpdate {} (map mkTest activatedTests) // {
    inherit (allTests) vuizvui;
  };

  inherit pkgs;

  channels = let
    mkChannel = attrs: root.pkgs.mkChannel (rec {
      name = "vuizvui-channel-${attrs.name or "generic"}-${vuizvuiVersion}";
      src = vuizvui;
      patchPhase = ''
        touch .update-on-nixos-rebuild
      '';
    } // removeAttrs attrs [ "name" ]);

    gatherTests = active: map (path: getAttrFromPath path allTests) active;

  in {
    generic = mkChannel {
      constituents = concatMap (collect isDerivation) [
        allTests.vuizvui pkgs
      ];
    };

    machines = mapAttrsRecursiveCond (m: !(m ? eval)) (path: attrs: mkChannel {
      name = "machine-${last path}";
      constituents = singleton attrs.eval.config.system.build.toplevel
                  ++ gatherTests attrs.eval.config.vuizvui.requiresTests;
    }) allMachines;
  };

  manual = let
    modules = import "${nixpkgs}/nixos/lib/eval-config.nix" {
      modules = import "${vuizvui}/modules/module-list.nix";
      check = false;
      inherit system;
    };

    patchedDocbookXSL = overrideDerivation pkgsUpstream.docbook5_xsl (drv: {
      # Don't chunk off <preface/>
      postPatch = (drv.postPatch or "") + ''
        sed -i -e '
          /<xsl:when.*preface/d
          /<xsl:for-each/s!|//d:preface \+!!g
          /<xsl:variable/s!|[a-z]\+::d:preface\[1\] \+!!g
        ' xhtml/chunk-common.xsl

        sed -i -e '
          /<xsl:when.*preface/,/<\/xsl:when>/d
          /<xsl:template/s!|d:preface!!g
        ' xhtml/chunk-code.xsl
      '';
    });

    isVuizvui = opt: head (splitString "." opt.name) == "vuizvui";
    filterDoc = filter (opt: isVuizvui opt && opt.visible && !opt.internal);
    optionsXML = toXML (filterDoc (optionAttrSetToDocList modules.options));
    optionsFile = toFile "options.xml" (unsafeDiscardStringContext optionsXML);
  in pkgsUpstream.stdenv.mkDerivation {
    name = "vuizvui-options";

    buildInputs = singleton pkgsUpstream.libxslt;

    xsltFlags = ''
      --param section.autolabel 1
      --param section.label.includes.component.label 1
      --param html.stylesheet 'style.css'
      --param xref.with.number.and.title 1
      --param admon.style '''
    '';

    buildCommand = ''
      cp -r "${./doc}" doc
      chmod -R +w doc
      xsltproc -o doc/options-db.xml \
        "${nixpkgs}/nixos/doc/manual/options-to-docbook.xsl" \
        ${optionsFile}

      dest="$out/share/doc/vuizvui"
      mkdir -p "$dest"

      xsltproc -o "$dest/" $xsltFlags -nonet -xinclude \
        ${patchedDocbookXSL}/xml/xsl/docbook/xhtml/chunk.xsl \
        doc/index.xml

      cp "${nixpkgs}/nixos/doc/manual/style.css" "$dest/style.css"

      mkdir -p "$out/nix-support"
      echo "doc manual $dest" > "$out/nix-support/hydra-build-products"
    '';
  };
}
