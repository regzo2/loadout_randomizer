local mod = get_mod("loadout_randomizer")

local Items = require("scripts/utilities/items")
local ItemSlotSettings = require("scripts/settings/item/item_slot_settings")
local MasterItems = require("scripts/backend/master_items")
local CrimesCompabilityMap = require("scripts/settings/character/crimes_compability_mapping")
local LoadoutRandomizerProfileUtils = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_utils")

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

local _item_valid_by_current_profile = function (profile, item)
	local archetype = profile.archetype
	local lore = profile.lore
	local backstory = lore.backstory
	local crime = CrimesCompabilityMap[backstory.crime] or backstory.crime
	local archetype_name = archetype.name
	local breed_name = archetype.breed
	local breed_valid = not item.breeds or table.contains(item.breeds, breed_name)
	local crime_valid = not item.crimes or table.contains(item.crimes, crime)
	local no_crimes = item.crimes == nil or table.is_empty(item.crimes)
	local archetype_valid = not item.archetypes or table.contains(item.archetypes, archetype_name)

	if archetype_valid and breed_valid and (no_crimes or crime_valid) then
		return true
	end

	return false
end

local set_nearest_inventory_item = function(profile, inventory_items, profile_preset, slot_name, item_to_find)

    local highest_score = 0
    local best_match_item

    --mod:echo("matching " .. item_to_find.weapon_template .." to slot " .. slot_name)

    for _, item in pairs(inventory_items) do
        local score = 0

        local gear_id = item.__gear_id
        local master_item = item.__master_item

        local is_valid_item = Items.slot_name(master_item) == slot_name 
                              and item_to_find.item_type == master_item.item_type 
                              and item_to_find.parent_pattern == master_item.parent_pattern

        if is_valid_item then
            local favorited = Items.is_item_id_favorited(gear_id)
            local item_level = master_item.itemLevel
            local item_rarity = master_item.rarity
            local weapon_template = master_item.weapon_template
            local levenshtein_score = levenshtein(weapon_template, item_to_find.weapon_template)

            score = favorited and score + 50 or score
            score = score + item_level
            score = score + item_rarity * 10
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

local set_random_inventory_item = function(profile, inventory_items, profile_preset, match_slot)

    local valid_items = {}
    for key, item in pairs(inventory_items) do
        local gear_id = item.__gear_id
        local master_item = item.__master_item

        local contains_slot = function(item)
            local slots = item.slots
            if not item or not slots then return false end

            for _, slot in pairs(slots) do
                if tostring(match_slot.slot_name) == tostring(slot) then 
                    --mod:echo(slot .. " == " .. slot_name)
                    return true 
                end
            end
            return false
        end

        local profile_contains_item = function(item)
            local loadout = profile_preset.loadout
            if not item or not loadout then return false end

            for _, gear_id in pairs(loadout) do
                if tostring(gear_id) == tostring(item.__gear_id) then 
                    return true 
                end
            end
            return false
        end

        local is_valid_item = item and match_slot and contains_slot(item) and _item_valid_by_current_profile(profile, master_item)
        local is_item_equipped = gear_id and profile_preset and profile_preset.loadout and profile_contains_item(item)

        if is_valid_item and not is_item_equipped then
            table.insert(valid_items, item)
        end
    end

    local random_key = math.random(#valid_items)
    local item = random_key and valid_items[random_key]

    if item then
        if match_slot.equip_if_empty == true and not profile_preset.loadout[match_slot.slot_name] then
            profile_preset.loadout[match_slot.slot_name] = item.__gear_id
        elseif not match_slot.equip_if_empty then
            profile_preset.loadout[match_slot.slot_name] = item.__gear_id
        end
    end
end

local apply_random_items_by_slot_to_preset = function(profile, slots, profile_preset, provided_inventory_items)

    for _, slot in pairs(slots) do
        local archetype_name = profile.archetype.mod_name
        local slot_settings = ItemSlotSettings[slot.slot_name]
        local archetype_restrictions = slot_settings.archetype_restrictions

        if archetype_restrictions and archetype_restrictions[archetype_name] then
            set_random_inventory_item(profile, provided_inventory_items, profile_preset, slot)
        else
            set_random_inventory_item(profile, provided_inventory_items, profile_preset, slot)
        end
    end

    local character_id = profile.character_id

    LoadoutRandomizerProfileUtils.save_randomizer_profile(profile_preset, character_id)
end

local fill_if_empty_slots = {
    ["slot_animation_emote_1"] = true,
    ["slot_animation_emote_2"] = true,
    ["slot_animation_emote_3"] = true,
    ["slot_animation_emote_4"] = true,
    ["slot_animation_emote_5"] = true,
    ["slot_animation_end_of_round"] = true,
    ["slot_attachment_1"] = true,
    ["slot_attachment_2"] = true,
    ["slot_attachment_3"] = true,
    ["slot_companion_gear_full"] = true,
    ["slot_primary"] = true,
    ["slot_secondary"] = true,
}

LoadoutRandomizerInventory.apply_inventory_loadout = function(data, profile_preset, character_id, inventory_items)
    local profile = data.profile

    set_nearest_inventory_item(profile, inventory_items, profile_preset, "slot_primary", data.weapons.melee.item)
    set_nearest_inventory_item(profile, inventory_items, profile_preset, "slot_secondary", data.weapons.ranged.item)

    local available_slots = {}

    for slot_name, slot in pairs(ItemSlotSettings) do
        --mod:echo(slot_name)
        if slot.equipped_in_inventory and (mod:get("sett_" .. slot_name .. "_enabled_id") == true or fill_if_empty_slots[slot_name]) then
            local slot_setting = {
                slot_name = slot_name,
                equip_if_empty = fill_if_empty_slots[slot_name],
            }
            --mod:echo(slot_name .. " created")
            table.insert(available_slots, slot_setting)
        end
    end

    apply_random_items_by_slot_to_preset(profile, available_slots, profile_preset, inventory_items)
end


return LoadoutRandomizerInventory