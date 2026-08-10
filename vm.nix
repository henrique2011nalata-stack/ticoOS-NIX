{ ... }: {
  ticoOS.isVm = true;
  ticoOS.enableNvidia = false;

  users.users.tico = {
    initialPassword = "vm";
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "tico";
  };
}
