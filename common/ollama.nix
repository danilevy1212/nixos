{pkgs, ...}: {
  services.ollama = with pkgs; {
    enable = true;
    package = ollama-vulkan;
    environmentVariables = {
      # NOTE  See https://www.amplenote.com/plugins/WykvBZZSXReMcVFRrjrhk4mS
      OLLAMA_ORIGINS = "amplenote-handler://*,https://plugins.amplenote.com";
      OLLAMA_FLASH_ATTENTION = "true";
      OLLAMA_KV_CACHE_TYPE = "q5_0";
    };
  };
}
