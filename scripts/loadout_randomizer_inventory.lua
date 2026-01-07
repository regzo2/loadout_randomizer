local mod = get_mod("loadout_randomizer")

local Items = require("scripts/utilities/items")
local ItemSlotSettings = require("scripts/settings/item/item_slot_settings")
local MasterItems = require("scripts/backend/master_items")
local ProfileUtils = require("scripts/utilities/profile_utils")
local Promise = require("scripts/foundation/utilities/promise")
local TalentLayoutParser = require("scripts/ui/views/talent_builder_view/utilities/talent_layout_parser")

local LoadoutRandomizerInventory = {}

function levenshtein(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}
	local cost = 0
	
        -- quick cut-offs to save time
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end
	
        -- initialise the base matrix values
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end
	
        -- actual Levenshtein algorithm
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (str1:byte(i) == str2:byte(j)) then
				cost = 0
			else
				cost = 1
			end
			
			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end
	
        -- return the last value - this is the Levenshtein distance
	return matrix[len1][len2]
end

local set_nearest_inventory_item = function(inventory_items, profile_preset, slot_name, item_to_find)

    local highest_score = 0
    local best_match_item

    --mod:echo("matching " .. item_to_find.weapon_template .." to slot " .. slot_name)

    for _, item in pairs(inventory_items) do
        local score = 0

        local gear_id = item.__gear_id
        local master_item = item.__master_item

        local is_valid_item = Items.slot_name(master_item) == slot_name and item_to_find.item_type == master_item.item_type and item_to_find.parent_pattern == master_item.parent_pattern

        if is_valid_item then
            local favorited = Items.is_item_id_favorited(gear_id)
            local item_level = master_item.itemLevel
            local item_rarity = master_item.rarity
            local weapon_template = master_item.weapon_template

            score = favorited and score + 50 or score
            score = score + item_level
            score = score + item_rarity * 10
            local levenshtein_score = levenshtein(weapon_template, item_to_find.weapon_template)
            score = score - levenshtein_score * 50

            if master_item.traits then
                for _, trait in pairs(master_item.traits) do
                    local trait_rarity = trait.rarity
                    score = score + trait_rarity * 10
                end
            end

            if master_item.perks then
                for _, perk in pairs(master_item.perks) do
                    local perk_rarity = perk.rarity
                    score = score + perk_rarity * 10
                end
            end

            if score > highest_score then
                highest_score = score
                best_match_item = item
            end
        end
    end

    if best_match_item then
        profile_preset.loadout[slot_name] = best_match_item.__gear_id
    end
end

LoadoutRandomizerInventory.get_randomizer_profile = function()

    local local_player_id = 1
	local local_player = Managers.player:local_player(local_player_id)
    local archetype_name = local_player:archetype_name()

    local profile_presets_base = ProfileUtils.get_profile_presets()

    local profile_preset

    for index, preset in ipairs(profile_presets_base) do
        is_randomizer_profile = preset.is_randomizer_profile
        if is_randomizer_profile then
            profile_preset = preset
        end
    end

    if not profile_preset then
        Managers.event:trigger("event_player_save_changes_to_current_preset")

        -- no existing randomizer profiles
        local profile_preset_id = ProfileUtils.add_profile_preset()
        profile_preset = ProfileUtils.get_profile_preset(profile_preset_id)
        profile_preset.is_randomizer_profile = true

        Managers.event:trigger("event_on_player_preset_created", profile_preset_id)
    end

    Managers.save:queue_save()
    return profile_preset
end

LoadoutRandomizerInventory.apply_randomizer_loadout_to_profile_preset = function(data)

    --mod:echo("applying profile")

    local profile_preset = LoadoutRandomizerInventory.get_randomizer_profile()

    local local_player_id = 1
	local player = Managers.player:local_player(local_player_id)
    local archetype_name = player:archetype_name()
	local character_id = player:character_id()

    Managers.data_service.gear:fetch_inventory(character_id):next(function (inventory_items)

        --mod:echo("applying items")

        set_nearest_inventory_item(inventory_items, profile_preset, "slot_primary", data.weapons.melee.item)
        set_nearest_inventory_item(inventory_items, profile_preset, "slot_secondary", data.weapons.ranged.item)

        Managers.save:queue_save()
	end)
end

return LoadoutRandomizerInventory