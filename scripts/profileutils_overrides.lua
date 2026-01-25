local mod = get_mod("loadout_randomizer")

local ViewElementProfilePresetsSettings = require("scripts/ui/view_elements/view_element_profile_presets/view_element_profile_presets_settings")
local LoadoutRandomizerProfileUtils  = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_utils")

local ProfileUtilsPath = "scripts/utilities/profile_utils"
local SaveData = require("scripts/managers/save/save_data")

mod:hook_require(ProfileUtilsPath, function(ProfileUtils)

    mod:hook_safe(ProfileUtils, "save_item_id_for_profile_preset", function(profile_preset_id, slot_id, item_gear_id)
        local profile_preset = LoadoutRandomizerProfileUtils.get_randomizer_profile()

        if profile_preset and profile_preset.id == profile_preset_id then
            local loadout = profile_preset.loadout
            loadout[slot_id] = item_gear_id

            LoadoutRandomizerProfileUtils.save_randomizer_profile(profile_preset)
        end
    end)
end)