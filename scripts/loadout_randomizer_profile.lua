local mod = get_mod("loadout_randomizer")

local LoadoutRandomizerInventory    = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_inventory")
local LoadoutRandomizerProfileUtils = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_utils")

LoadoutRandomizerProfile = {}

LoadoutRandomizerProfile.apply_randomizer_loadout_to_profile_preset = function(data)

    --mod:echo("applying profile")

    local profile = data.profile
    local character_id = profile.character_id
    local profile_preset = LoadoutRandomizerProfileUtils.get_randomizer_profile(profile)

    Managers.data_service.gear:fetch_inventory(character_id):next(function (inventory_items)
        LoadoutRandomizerInventory.apply_loadout(data, profile_preset, character_id, inventory_items)
        LoadoutRandomizerProfileUtils.save_randomizer_profile(profile_preset, character_id)
    end)
end

return LoadoutRandomizerProfile