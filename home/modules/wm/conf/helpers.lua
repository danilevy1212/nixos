local naughty = require("naughty")

local H = {}

H.nix_rebuild_and_awesome_restart = function ()
  -- TODO launch 'sudo nixos-rebuild swith'
  -- TODO launch notify it started
  -- TODO launch notify it finished
  -- TODO launch restart awesome
  -- Reference https://awesomewm.org/apidoc/core_components/awesome.html#exit
  -- https://www.nongnu.org/gksu/
  awesome.restart()
end

return H
