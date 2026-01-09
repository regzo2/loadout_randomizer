local mod = get_mod("loadout_randomizer")

local LoadoutRandomizerInventory    = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_inventory")
local LoadoutRandomizerTalents      = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_talents")
local LoadoutRandomizerProfileUtils = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_utils")

LoadoutRandomizerProfile = {}

LoadoutRandomizerProfile.apply_randomizer_loadout_to_profile_preset = function(data)

    --mod:echo("applying profile")

    local profile = data.profile
    local character_id = profile.character_id
    local profile_preset = LoadoutRandomizerProfileUtils.get_randomizer_profile(profile)

    LoadoutRandomizerInventory.apply_inventory_loadout(data, profile_preset, character_id)
    LoadoutRandomizerTalents.apply_talents_loadout(data, profile_preset, character_id)
end

return LoadoutRandomizerProfile