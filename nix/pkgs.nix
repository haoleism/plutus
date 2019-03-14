{
  overlay = hackage:
    {
      packages = {
        "serialise" = (((hackage.serialise)."0.2.1.0").revisions).default;
        "monad-stm" = (((hackage.monad-stm)."0.1.0.2").revisions).default;
        "servant-options" = (((hackage.servant-options)."0.1.0.0").revisions).default;
        "hint" = (((hackage.hint)."0.9.0").revisions).default;
        "exceptions" = (((hackage.exceptions)."0.10.0").revisions).default;
        "purescript-bridge" = (((hackage.purescript-bridge)."0.13.0.0").revisions).default;
        "servant-subscriber" = (((hackage.servant-subscriber)."0.6.0.2").revisions).default;
        "jwt" = (((hackage.jwt)."0.9.0").revisions).default;
        "servant-ekg" = (((hackage.servant-ekg)."0.3").revisions).default;
        } // {
        language-plutus-core = ./language-plutus-core.nix;
        plutus-core-interpreter = ./plutus-core-interpreter.nix;
        plutus-exe = ./plutus-exe.nix;
        plutus-ir = ./plutus-ir.nix;
        plutus-tx = ./plutus-tx.nix;
        plutus-use-cases = ./plutus-use-cases.nix;
        interpreter = ./interpreter.nix;
        marlowe = ./marlowe.nix;
        meadow = ./meadow.nix;
        wallet-api = ./wallet-api.nix;
        plutus-playground-server = ./plutus-playground-server.nix;
        plutus-playground-lib = ./plutus-playground-lib.nix;
        plutus-tutorial = ./plutus-tutorial.nix;
        servant-purescript = ./servant-purescript.nix;
        cardano-crypto = ./cardano-crypto.nix;
        };
      };
  resolver = "lts-12.26";
  }