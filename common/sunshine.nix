{unstable, ...}: {
  services.sunshine = {
    enable = true;
    package = unstable.sunshine;
    openFirewall = true;
    capSysAdmin = true;
  };
}
