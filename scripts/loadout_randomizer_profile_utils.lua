local mod = get_mod("loadout_randomizer")

local Items = require("scripts/utilities/items")
local ItemSlotSettings = require("scripts/settings/item/item_slot_settings")
local MasterItems = require("scripts/backend/master_items")
local ProfileUtils = require("scripts/utilities/profile_utils")
local Promise = require("scripts/foundation/utilities/promise")
local TalentLayoutParser = require("scripts/ui/views/talent_builder_view/utilities/talent_layout_parser")
local CrimesCompabilityMap = require("scripts/settings/character/crimes_compability_mapping")

LoadoutRandomizerProfileUtils = {}

local _get_randomizer_profile_save_data = function(character_id)
    if not character_id then
        local local_player_id = 1
        local player_manager = Managers.player
        local player = player_manager and player_manager:local_player(local_player_id)
        character_id = player and player:character_id()
    end

    -- local save data
    if true then
        return mod.randomizer_profiles[character_id]
    end

    -- cloud save data
	local save_manager = Managers.save
	local character_data = character_id and save_manager and save_manager:character_data(character_id)

	return character_data.randomizer_profile
end

LoadoutRandomizerProfileUtils.save_randomizer_profile = function(profile_preset, character_id)
    if not character_id then
        local local_player_id = 1
        local player_manager = Managers.player
        local player = player_manager and player_manager:local_player(local_player_id)
        character_id = player and player:character_id()
    end

    if true then
        -- local save
        mod.randomizer_profiles[character_id] = profile_preset

        mod:set("data_randomizer_profiles", mod.randomizer_profiles)
    else
        --cloud save
        local save_manager = Managers.save
	    local character_data = character_id and save_manager and save_manager:character_data(character_id)

        character_data.randomizer_profile = profile_preset
        Managers.save:queue_save()
    end
end

local _add_randomizer_profile_preset = function(character_profile)

	local new_profile_preset_id = math.uuid()

    local profiles = ProfileUtils.get_profile_presets()
    local active_profile_preset_id = ProfileUtils.get_active_profile_preset_id()

    local profile_preset

    if not active_profile_preset_id then
        profile_preset = profiles[math.random(#profiles)]
    else
        local found_preset = ProfileUtils.get_profile_preset(active_profile_preset_id)
        if not found_preset then 
            -- wtf
            profile_preset = profiles[math.random(#profiles)]
        else
            profile_preset = found_preset
        end
    end

    local randomizer_profile = table.clone(profile_preset)

	randomizer_profile.id = new_profile_preset_id

    LoadoutRandomizerProfileUtils.save_randomizer_profile(randomizer_profile, character_profile and character_profile.character_id)

	return randomizer_profile
end

LoadoutRandomizerProfileUtils.delete_randomizer_profile = function()

    local local_player_id = 1
	local local_player = Managers.player:local_player(local_player_id)
    local character_id = local_player:character_id()

    LoadoutRandomizerProfileUtils.save_randomizer_profile(nil, character_id)
end

LoadoutRandomizerProfileUtils.save_talent_nodes = function(randomizer_profile, talent_nodes, talents_version)

	local profile_preset = randomizer_profile or LoadoutRandomizerProfileUtils.get_randomizer_profile()

	if not profile_preset then
		return
	end

	if not profile_preset.talents then
		profile_preset.talents = {}
	elseif profile_preset.talents ~= talent_nodes then
		table.clear(profile_preset.talents)
	end

	local talents = profile_preset.talents

	if talent_nodes then
		for talent_node_name, points_spent in pairs(talent_nodes) do
			talents[talent_node_name] = points_spent and points_spent > 0 and points_spent or nil
		end

		profile_preset.talents_version = talents_version
	end

	LoadoutRandomizerProfileUtils.save_randomizer_profile(profile_preset)
end

LoadoutRandomizerProfileUtils.get_randomizer_profile = function(character_profile)

    local profile_preset = _get_randomizer_profile_save_data(character_profile)

    if not profile_preset then
        Managers.event:trigger("event_player_save_changes_to_current_preset")

        profile_preset = _add_randomizer_profile_preset(character_profile)
        profile_preset.is_randomizer_profile = true
        LoadoutRandomizerProfileUtils.save_randomizer_profile(profile_preset, character_profile and character_profile.character_id)
    end

    return profile_preset
end

return LoadoutRandomizerProfileUtils