{ pkgs ? import <nixpkgs> {}
, iohk-overlay ? {}
, iohk-module ? {}
, haskell
, ...
}:
let
  # our packages
  plan-pkgs = import ./pkgs.nix;

  # packages which will require TH and thus
  # will need -fexternal-interpreter treatment
  # when cross compiling.
  th-packages = [ "math-functions" ];

  # Build the packageset with module support.
  # We can essentially override anything in the modules
  # section.
  #
  #  packages.cbors.patches = [ ./one.patch ];
  #  packages.cbors.flags.optimize-gmp = false;
  #
  compiler = (plan-pkgs.overlay {}).compiler or
             (plan-pkgs.pkgs {}).compiler;

  pkgSet = haskell.mkCabalProjectPkgSet {
    inherit plan-pkgs;
    # The overlay allows extension or restriction of the set of
    # packages we are interested in. By using the stack-pkgs.overlay
    # we restrict our package set to the ones provided in stack.yaml.
    pkg-def-overlays = [
      iohk-overlay.${compiler.nix-name}
      # this one is missing from the plan.json; we can't yet force
      # os/arch with cabal to produce plans that are valid for multiple
      # os/archs. Luckily mac/linux are close enough to have mostly the
      # same build plan for windows however we need some hand holding for
      # now.
      (hackage: { mintty = hackage.mintty."0.1.2".revisions.default; })
    ];
    modules = [
      # the iohk-module will supply us with the necessary
      # cross compilation plumbing to make Template Haskell
      # work when cross compiling.  For now we need to
      # list the packages that require template haskell
      # explicity here.
      (iohk-module { nixpkgs = pkgs;
                     inherit th-packages; })
      ({ config, ...}: {
          packages.hsc2hs.components.exes.hsc2hs.doExactConfig = true;
          packages.bytestring-builder.doHaddock = false;
      })
    ];
  };

in
  pkgSet.config.hsPkgs // { _config = pkgSet.config; }
