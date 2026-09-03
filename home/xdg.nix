{
  xdg = {
    enable = true;

    mimeApps = {
      enable = true;
      defaultApplications = {
        "image/avif" = [ "org.gnome.Loupe.desktop" ];
        "image/bmp" = [ "org.gnome.Loupe.desktop" ];
        "image/gif" = [ "org.gnome.Loupe.desktop" ];
        "image/heic" = [ "org.gnome.Loupe.desktop" ];
        "image/heif" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
        "image/tiff" = [ "org.gnome.Loupe.desktop" ];
        "image/webp" = [ "org.gnome.Loupe.desktop" ];
        "application/pdf" = [ "org.gnome.Papers.desktop" ];
        "text/html" = [ "google-chrome.desktop" ];
        "x-scheme-handler/http" = [ "google-chrome.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome.desktop" ];
        "x-scheme-handler/terminal" = [ "kitty.desktop" ];
      };
    };

    configFile."go-musicfox/config.toml".text = ''
      [main.notification]
      enable = false
      inApp = false

      [main.lyric.cover]
      show = true
      widthRatio = 0.22
      cornerRadius = 10
      spin = false

      [theme]
      centerEverything = true
    '';
    configFile."fastfetch/config.jsonc".source = ../config/fastfetch/config.jsonc;
    configFile."fastfetch/logo.png".source = ../config/fastfetch/logo.png;
  };
}
