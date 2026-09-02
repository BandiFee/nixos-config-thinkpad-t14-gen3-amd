{ customPkgs, lib, ... }:

{
  programs.bat.enable = true;

  programs.btop.enable = true;

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;

    # Keep the traditional ls command and its existing behavior available.
    enableFishIntegration = false;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.gh.enable = true;

  programs.git.enable = true;

  programs.lazygit = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.nh = {
    enable = true;
    osFlake = "/etc/nixos";
  };

  programs.vim.enable = true;

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # Terminal file manager. The Fish integration provides `y`, which returns
  # the shell to Yazi's current directory when Yazi exits.
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    settings.mgr = {
      # Give the current directory and preview more room than the parent pane.
      ratio = [
        1
        3
        4
      ];
      sort_by = "natural";
      sort_sensitive = false;
      sort_reverse = false;
      sort_dir_first = true;
      linemode = "size";
      show_hidden = false;
      show_symlink = true;
      scrolloff = 5;
    };
  };

  programs.fish = {
    enable = true;
    # mkOrder keeps this block after Home Manager's own shell integrations
    # (fzf, zoxide, starship, kitty), matching the order Fish sourced them in
    # before this file was split out of home.nix.
    interactiveShellInit = lib.mkOrder 1400 ''
      set -g fish_greeting

      # Pick up the patched musicfox immediately, even when this shell inherited
      # session variables from before the latest Home Manager activation.
      if not contains -- ${customPkgs.go-musicfox-latest}/bin $PATH
        set -gx PATH ${customPkgs.go-musicfox-latest}/bin $PATH
      end

      # Micromamba
      set -gx MAMBA_ROOT_PREFIX $HOME/.mamba
      micromamba shell hook --shell fish | source
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ../config/starship.toml);
  };
}
