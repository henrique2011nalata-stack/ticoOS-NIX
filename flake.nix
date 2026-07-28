{
  description = "Configuracao centralizada do ticoOS NIX";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.ticoOS = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # --- CONFIGURAÇÕES DO SISTEMA (DESEMPENHO MÁXIMO & ÁUDIO) ---
        ({ ... }: {
          environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];
          fonts.fontDir.enable = true;

          # Infraestrutura de Áudio PipeWire
          security.rtkit.enable = true; 
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
            wireplumber.enable = true;
          };

          # Liberação Total de CPU para a Compilação da ISO voar
          nix.settings = {
            auto-optimise-store = false;
            max-jobs = "auto"; 
            cores = 0; 
          };

          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };
        }) # Fechamento perfeito e alinhado do bloco do sistema

        # --- BLOCO DO HOME MANAGER ---
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.tico = { pkgs, ... }: {
            home.stateVersion = "24.11";

            home.packages = with pkgs; [
              btop
              fastfetch
              figlet
              nerd-fonts.jetbrains-mono
              hyprshot
              slurp
              pavucontrol
              blueman
              dunst
              libnotify
              brightnessctl
              swww
              kdePackages.dolphin

              # Compilação limpa da fonte VCR OSD Mono
              (stdenv.mkDerivation {
                pname = "vcr-osd-mono";
                version = "1.001";
                src = fetchFromGitHub {
                  owner = "jabes";
                  repo = "terrace";
                  rev = "master";
                  sha256 = "sha256-hiJcbShJ/ob2Q2Iwe0QguNGKRZ3xwSq0ChUNukYQt+4=";
                };
                dontUnpack = true;
                installPhase = ''
                  mkdir -p $out/share/fonts/truetype
                  cp $src/Terrace/resources/fonts/VCR-OSD-Mono.ttf $out/share/fonts/truetype/VCR_OSD_MONO.ttf
                '';
              })
            ];

            fonts.fontconfig.enable = true;

            programs.neovim = {
              enable = true;
              defaultEditor = true;
            };

            programs.firefox.enable = true;

            programs.kitty = {
              enable = true;
              font = {
                name = "VCR OSD Mono";
                size = 13;
              };
              settings = {
                background_opacity = "0.9";
                disable_ligatures = "never";
              };
            };

            programs.bash = {
              enable = true;
              initExtra = ''
                clear
                echo "___________________________________________________"
                figlet -f slant "ticoOS NIX"
                echo "TICO.CO todos direitos reservados (2019©2026)"
                echo "___________________________________________________"
                echo "BETA v0.1.0"
                echo ""
              '';
            };

            programs.rofi = {
              enable = true;
              font = "JetBrainsMono Nerd Font 12";
              extraConfig = {
                modi = "drun,run";
                show-icons = true;
                drun-display-format = "{name}";
                disable-history = false;
                sidebar-mode = false;
              };
            };

            programs.waybar = {
              enable = true;
              settings = {
                mainBar = {
                  layer = "top";
                  position = "top";
                  height = 30;
                  modules-left = [ "hyprland/workspaces" ];
                  modules-center = [ "hyprland/window" ];
                  modules-right = [ "pulseaudio" "battery" "clock" ];
                  "clock" = { format = "{:%H:%M - %d/%m}"; };
                  "battery" = { format = "{capacity}% 🔋"; };
                  "pulseaudio" = { format = "{volume}% 🔊"; };
                };
              };
              style = ''
                window#waybar {
                  background-color: rgba(20, 20, 30, 0.9);
                  border-bottom: 2px solid #3b4252;
                  color: #ffffff;
                  font-family: "JetBrainsMono Nerd Font", sans-serif;
                  font-size: 13px;
                }
                #clock, #battery, #pulseaudio { padding: 0 10px; }
              '';
            };

            wayland.windowManager.hyprland = {
              enable = true;
              settings = {
                "$mainMod" = "SUPER";
                "$terminal" = "kitty";

                monitor = ",preferred,auto,1";

                input = {
                  kb_layout = "br";
                  kb_variant = "abnt2";
                  kb_model = "abnt2";
                };

                exec-once = [
                  "dbus-update-activation-environment --systemd --all"
                  "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
                  "waybar"
                  "dunst"
                  "swww-daemon"
                  "sleep 1 && swww img /home/tico/Pictures/wallpaper.png"
                ];

                bind = [
                  "$mainMod, Q, exec, $terminal"
                  "$mainMod, SPACE, exec, rofi -show drun" 
                  "$mainMod, C, exec, hyprctl dispatch killactive"
                  "$mainMod, M, exit,"
                  "$mainMod, E, exec, $terminal -e yazi"
                  
                  # Hardware
                  ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
                  ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
                  ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                  ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
                  ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"

                  # Capturas de tela (Print)
                  ", PRINT, exec, hyprshot -m output -o ~/Pictures"
                  "$mainMod, PRINT, exec, hyprshot -m region -o ~/Pictures"

                  # Workspaces (Mudar Desktop)
                  "$mainMod, 1, workspace, 1"
                  "$mainMod, 2, workspace, 2"
                  "$mainMod, 3, workspace, 3"
                  "$mainMod, 4, workspace, 4"
                  "$mainMod, 5, workspace, 5"
                  "$mainMod, 6, workspace, 6"
                  "$mainMod, 7, workspace, 7"
                  "$mainMod, 8, workspace, 8"
                  "$mainMod, 9, workspace, 9"

                  # Mover janela para outro Desktop
                  "$mainMod SHIFT, 1, movetoworkspace, 1"
                  "$mainMod SHIFT, 2, movetoworkspace, 2"
                  "$mainMod SHIFT, 3, movetoworkspace, 3"
                  "$mainMod SHIFT, 4, movetoworkspace, 4"
                  "$mainMod SHIFT, 5, movetoworkspace, 5"
                  "$mainMod SHIFT, 6, movetoworkspace, 6"
                  "$mainMod SHIFT, 7, movetoworkspace, 7"
                  "$mainMod SHIFT, 8, movetoworkspace, 8"
                  "$mainMod SHIFT, 9, movetoworkspace, 9"
                ];
              };
            };
          };
        }
      ];
    };
  };
}

