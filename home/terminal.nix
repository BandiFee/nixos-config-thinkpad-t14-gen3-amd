{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };

    shellIntegration.enableFishIntegration = true;

    settings = {
      # A dark glass-like surface: black tint with the wallpaper showing through.
      background_opacity = 0.70;
      background_blur = 1;
      window_padding_width = 10;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      enabled_layouts = "splits:split_axis=auto;equalize_on_close=true,stack";

      # Keep Nerd Font icons consistent across Linux and macOS. Without this,
      # the patched JetBrains Mono face may render private-use glyphs itself
      # instead of letting Kitty use its bundled Symbols Nerd Font.
      symbol_map = "U+e000-U+e00a,U+e0a0-U+e0a2,U+e0a3,U+e0b0-U+e0b3,U+e0b4-U+e0c8,U+e0ca,U+e0cc-U+e0d7,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b7,U+e700-U+e8ef,U+ea60-U+ec1e,U+ed00-U+efce,U+f000-U+f2ff,U+f300-U+f381,U+f400-U+f533,U+f0001-U+f1af0 Symbols Nerd Font Mono";

      background = "#000000";
      foreground = "#cdd6f4";
      cursor = "#f5e0dc";
      # Animate jumps of the text cursor so movement stays easy to follow.
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.4";
      cursor_trail_start_threshold = 2;
      selection_background = "#45475a";
      selection_foreground = "#cdd6f4";
      active_border_color = "#cba6f7";
      inactive_border_color = "#45475a";

      color0 = "#45475a";
      color1 = "#f38ba8";
      color2 = "#a6e3a1";
      color3 = "#f9e2af";
      color4 = "#89b4fa";
      color5 = "#f5c2e7";
      color6 = "#94e2d5";
      color7 = "#bac2de";
      color8 = "#585b70";
      color9 = "#f38ba8";
      color10 = "#a6e3a1";
      color11 = "#f9e2af";
      color12 = "#89b4fa";
      color13 = "#f5c2e7";
      color14 = "#94e2d5";
      color15 = "#a6adc8";
    };

    keybindings = {
      "ctrl+shift+o" = "launch --cwd=current --location=vsplit";
      "ctrl+shift+e" = "launch --cwd=current --location=hsplit";
      "ctrl+alt+left" = "neighboring_window left";
      "ctrl+alt+down" = "neighboring_window down";
      "ctrl+alt+up" = "neighboring_window up";
      "ctrl+alt+right" = "neighboring_window right";
      "ctrl+shift+enter" = "toggle_layout stack";
    };
  };
}
