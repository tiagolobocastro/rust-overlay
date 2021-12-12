{ lib, pkgs, stdenv, makeRustPlatform, fetchFromGitHub, runCommand, writeShellScriptBin
, toRustTarget, rustc, cargo, rust-std, rust-src, miri-preview
}:
let
  rustc' = writeShellScriptBin "rustc"  ''
    if [[ " --sysroot " == " $* " ]]; then
      exec ${rustc}/bin/rustc "$@"
    else
      exec ${rustc}/bin/rustc --sysroot ${rust-std} "$@"
    fi
  '';

  rustPlatform = makeRustPlatform {
    inherit cargo;
    rustc = rustc';
    # Follow nixpkgs' rustc to make `makeRustPlatform` happy.
    # rustc = rustc // { meta.platforms = pkgs.rustc.meta.platforms; };
  };

  rustHostPlatform = toRustTarget stdenv.hostPlatform;
  rustHostPlatform' = lib.replaceStrings ["-"] ["_"] (lib.toUpper rustHostPlatform);

  xargo = rustPlatform.buildRustPackage rec {
    pname = "xargo";
    version = "0.3.24";

    src = fetchFromGitHub {
      owner = "japaric";
      repo = "xargo";
      rev = "v${version}";
      hash = "sha256-9+9EXzx/nySJj0z6hgW8MGrr2JdafEPZMLWJznC83TA=";
    };

    cargoHash = "sha256-Vd3e5lDoDhckaID5FMQrUXx51qbL1O53FMYWyUKIjMo=";

    # RUSTFLAGS = [ "--sysroot" rust-std ];

    # The default script passes `--target <HOST>`, which eliminates the effect of RUSTFLAGS.
    # https://doc.rust-lang.org/cargo/reference/config.html#buildrustflags
    # buildPhase = ''
    #   cargo build -j $NIX_BUILD_CORES --frozen --release
    # '';

    dontCargoCheck = true;

    # installPhase = ''
    #   install -Dt $out/bin target/release/xargo{,-check}
    # '';

    meta.license = with lib.licenses; [ mit asl20 ];
    meta.platforms = pkgs.rustc.meta.platforms;
  };

  std-cargo-deps = rustPlatform.fetchCargoTarball {
    src = "";
  };

  miri-sysroot = runCommand "miri-sysroot" {
    nativeBuildInputs = [ rustc' cargo xargo miri-preview pkgs.breakpointHook ];
    # RUSTFLAGS = [ "--sysroot" rust-std ];
    XARGO_RUST_SRC = "${rust-src}/lib/rustlib/src/rust/library";
  } ''
    mkdir -p home
    export HOME="$(pwd)/home"
    cargo miri setup

    sysroot="$(cargo miri setup --print-sysroot)"
    cp -rT "$sysroot" "$out"
  '';

in
  miri-sysroot
