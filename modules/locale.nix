{ pkgs, ... }:

{
  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    keyMap = "us";
    packages = [ pkgs.terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";
  };

  fonts = {
    fontconfig = {
      enable = true;

      # Only use the Simplified Chinese (SC) variant of the Noto CJK fonts.
      # All five regional variants ship in the same package, and with a
      # non-CJK locale fontconfig picks the JP instance first, which draws
      # Chinese-only glyphs (e.g. 复) with narrow Japanese-style forms.
      # Reject the other variants so SC always wins.
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <selectfont>
            <rejectfont>
              <pattern><patelt name="family"><string>Noto Sans CJK JP</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans CJK KR</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans CJK TC</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans CJK HK</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans Mono CJK JP</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans Mono CJK KR</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans Mono CJK TC</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Sans Mono CJK HK</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Serif CJK JP</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Serif CJK KR</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Serif CJK TC</string></patelt></pattern>
              <pattern><patelt name="family"><string>Noto Serif CJK HK</string></patelt></pattern>
            </rejectfont>
          </selectfont>
        </fontconfig>
      '';
    };

    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
    ];
  };
}
