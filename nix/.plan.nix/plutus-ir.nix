{ system, compiler, flags, pkgs, hsPkgs, pkgconfPkgs, ... }:
  {
    flags = { development = false; };
    package = {
      specVersion = "1.18";
      identifier = { name = "plutus-ir"; version = "0.1.0.0"; };
      license = "BSD-3-Clause";
      copyright = "Copyright: (c) 2018 Input Output";
      maintainer = "michael.peyton-jones@iohk.io";
      author = "Michael Peyton Jones";
      homepage = "";
      url = "";
      synopsis = "Plutus IR language";
      description = "Plutus IR language library and compiler to Plutus Core.";
      buildType = "Simple";
      };
    components = {
      "library" = {
        depends = [
          (hsPkgs.base)
          (hsPkgs.bytestring)
          (hsPkgs.hedgehog)
          (hsPkgs.containers)
          (hsPkgs.language-plutus-core)
          (hsPkgs.lens)
          (hsPkgs.mtl)
          (hsPkgs.mmorph)
          (hsPkgs.prettyprinter)
          (hsPkgs.serialise)
          (hsPkgs.text)
          (hsPkgs.transformers)
          (hsPkgs.algebraic-graphs)
          (hsPkgs.megaparsec)
          ];
        };
      tests = {
        "plutus-ir-test" = {
          depends = [
            (hsPkgs.base)
            (hsPkgs.hedgehog)
            (hsPkgs.plutus-ir)
            (hsPkgs.language-plutus-core)
            (hsPkgs.megaparsec)
            (hsPkgs.mtl)
            (hsPkgs.mmorph)
            (hsPkgs.prettyprinter)
            (hsPkgs.serialise)
            (hsPkgs.tasty)
            (hsPkgs.tasty-hedgehog)
            (hsPkgs.text)
            ];
          };
        };
      };
    } // rec { src = (pkgs.lib).mkDefault .././../plutus-ir; }