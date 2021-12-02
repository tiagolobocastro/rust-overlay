{ channel ? "stable", profile ? "default" }:
with import <nixpkgs> { overlays = [ (import ../..) ]; };
mkShell {
  nativeBuildInputs = [ rust-bin.${channel}.latest.${profile} ];
}
