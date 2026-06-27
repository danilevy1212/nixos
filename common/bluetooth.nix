{...}: {
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Experimental = true;
        ControllerMode = "dual";
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
}
