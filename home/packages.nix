{ customPkgs, pkgs, ... }:

{
  home.packages = [
    pkgs.brightnessctl
    pkgs.claude-code
    customPkgs.codex-with-wayland-clipboard-fallback
    pkgs.curl
    pkgs.deadnix
    pkgs.dotnet-sdk_10
    pkgs.fastfetch
    pkgs.fd
    pkgs.ffmpeg
    pkgs.file-roller
    pkgs.gcc
    customPkgs.go-musicfox-latest
    pkgs.google-chrome
    pkgs.hyperfine
    pkgs.inter
    pkgs.jetbrains.pycharm
    pkgs.jetbrains.rust-rover
    pkgs.jq
    pkgs.just
    pkgs.libreoffice
    pkgs.loupe
    customPkgs.rider-with-avalonia-libs
    pkgs.micromamba
    pkgs.mpv
    # Video wallpaper renderer used by Noctalia's official mpvpaper plugin.
    pkgs.mpvpaper
    pkgs.nautilus
    pkgs.nixd
    pkgs.nixfmt
    pkgs.nix-output-monitor
    pkgs.nix-tree
    pkgs.obs-studio
    pkgs.p7zip
    pkgs.papers
    pkgs.pavucontrol
    pkgs.playerctl
    customPkgs.qq-xwayland-with-working-source
    pkgs.ripgrep
    pkgs.rustup
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.splayer
    pkgs.statix
    pkgs.typora
    pkgs.unzip
    (pkgs.vscode-with-extensions.override {
      vscode = pkgs.vscode;
      vscodeExtensions = with pkgs.vscode-extensions; [
        james-yu.latex-workshop
      ];
    })
    (pkgs.texliveMedium.withPackages (tex: [
      tex.biblatex
      tex.biblatex-ieee
      tex.csquotes
      tex.placeins
      tex.titlesec
    ]))
    pkgs.biber
    customPkgs.wechat-with-fcitx
    pkgs.wget
    pkgs.wl-clipboard
    pkgs.wl-mirror
    pkgs.zip
  ];

  # Prefer the locally patched musicfox even before a system-level
  # nixos-rebuild updates /etc/profiles/per-user.
  home.sessionPath = [ "${customPkgs.go-musicfox-latest}/bin" ];
}
