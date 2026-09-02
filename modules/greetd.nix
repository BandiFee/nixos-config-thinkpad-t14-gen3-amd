{ config, pkgs, ... }:

{
  environment.etc."tuigreet/config.toml".text = ''
    [display]
    show_time = true
    time_format = "[ %Y-%m-%d || %H:%M ]"
    greeting = """
    [+] Welcome back to NixOS on ThinkPad T14 [+]
    Enter your password to sign in.
    """
    align_greeting = "center"

    [layout]
    width = 80
    window_padding = 1
    container_padding = 2
    prompt_padding = 1

    [layout.widgets]
    time_position = "center"
    status_position = "hidden"

    [remember]
    username = true
    session = false
    user_session = true

    [secret]
    mode = "characters"
    characters = "*"

    [theme]
    border = "green"
    text = "white"
    time = "green"
    container = "black"
    title = "green"
    greet = "green"
    prompt = "white"
    input = "green"
  '';

  services.greetd = {
    enable = true;

    # tuigreet is a TUI greeter
    useTextGreeter = true;

    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --config /etc/tuigreet/config.toml --cmd ${config.programs.niri.package}/bin/niri-session";

      user = "greeter";
    };
  };
}
