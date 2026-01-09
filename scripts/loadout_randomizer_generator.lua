
local mod = get_mod("loadout_randomizer")

local Archetypes = require("scripts/settings/archetype/archetypes")
local UISettings = require("scripts/settings/ui/ui_settings")
local ITEM_TYPES = UISettings.ITEM_TYPES
local MasterItems = require("scripts/backend/master_items")
local TalentBuilderViewSettings = require("scripts/ui/views/talent_builder_view/talent_builder_view_settings")
local LoadoutRandomizerProfile = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile")
local talent_category_settings = TalentBuilderViewSettings.settings_by_node_type

local LoadoutRandomizerGenerator = {}

local map_talent_tree_to_data = function(archetype, randomizer_data)
	local all_talent_data = archetype.talents
	local talent_tree_path = string.format("scripts/ui/views/talent_builder_view/layouts/%s_tree", archetype.name)
	local exists = Application.can_get_resource("lua", talent_tree_path)
	local tree = require(talent_tree_path)

	if not exists or not tree then return end

	randomizer_data.talents = {}
	local talents = randomizer_data.talents

	for key, node in pairs(tree.nodes) do
		if node.type ~= "start" and all_talent_data[node.talent] then
			if not talents[node.type] then
				talents[node.type] = {}
			end

			talents[node.type][node.talent] = {}
			talents[node.type][node.talent].display_name = all_talent_data[node.talent].display_name
			talents[node.type][node.talent].icon = node.icon
			talents[node.type][node.talent].requirements = node.requirements
		end
	end
end

local get_archetype_patterns = function(archetype)
	local WeaponUnlockSettings = require("scripts/settings/weapon_unlock/weapon_unlock_settings")

	local unlocks = WeaponUnlockSettings[archetype.name]
	local patterns = {}
	for _, unlock in pairs(unlocks) do
		--gbl_ul = unlock
		for __, item in pairs(unlock) do
			local master_item = MasterItems.get_item(item)
			local pattern_id = master_item.parent_pattern
			local pattern = UISettings.weapon_patterns[pattern_id]

			local weapon_data = {}
			weapon_data.pattern = pattern
			weapon_data.item = master_item

			patterns[master_item.parent_pattern] = weapon_data
		end
	end
	return patterns
end

local get_item_data = function(archetype, randomizer_data)
	randomizer_data.weapons = {}
	randomizer_data.weapons.ranged = {}
	randomizer_data.weapons.melee = {}
	
	local ranged_table = randomizer_data.weapons.ranged
	local melee_table = randomizer_data.weapons.melee

	local patterns = get_archetype_patterns(archetype)
	local archetype_name = archetype.name
	local breed_name = archetype.breed

	for pattern_name, pattern in pairs(patterns) do
		if pattern.item.item_type == "WEAPON_MELEE" then
			melee_table[pattern_name] = pattern.pattern
		else
			ranged_table[pattern_name] = pattern.pattern
		end
	end	
end

local select_random_weapon = function(weighted_list)

	local count = 0

	for _, entry in pairs(weighted_list) do
		count = count + entry.weight
	end

	local weighted_count = math.random() * count
	local weighted_index = 0
	local index = 0

	local selected_weapon
	local selected_weapon_item

	while weighted_index < weighted_count do
		selected_weapon = weighted_list[index+1]
		index = (index + 1) % (#weighted_list)

		selected_weapon_item = MasterItems.get_item(selected_weapon.item)
		if selected_weapon_item then
			weighted_index = weighted_index + selected_weapon.weight
		end
	end

	return {item = selected_weapon_item, weight = selected_weapon.weight, totals = count}
end

local get_random_weighted_weapon = function(archetype, weapons_table)
	local weapons = {}

	for _, archetype_weapon in pairs(weapons_table) do
		for __, mark in pairs(archetype_weapon.marks) do
			mark.weight = mod:get("weapon_".. mark.name .. "_weight_id") or 1
			table.insert(weapons, mark)
		end
	end

	return select_random_weapon(weapons)
end

local function random_element(tbl)
    local keys = {}
    for key, value in pairs(tbl) do
		table.insert(keys, key)
    end

    local randomKey = math.random(#keys)
    return keys[randomKey]
end

local random_talent_from_set = function(talent_set)
	local weighted_count = 0

	local weighted_talent_set = {}

	for talent_id, talent in pairs(table.clone(talent_set)) do
		local talent_weight = mod:get("talent_" .. talent_id .. "_weight_id") or 1
		talent.weight = talent_weight
		talent.key = talent_id
		weighted_count = weighted_count + talent_weight
		table.insert(weighted_talent_set, talent)
	end

	local weighted_target = math.random() * weighted_count
	local weighted_index = 0
	local index = 0

	local selected_talent

	while weighted_index < weighted_target do
		selected_talent = weighted_talent_set[index+1]
		index = (index + 1) % (#weighted_talent_set)

		if selected_talent then
			weighted_index = weighted_index + selected_talent.weight
		end
	end

	return selected_talent.key
end

local get_filtered_talent_set = function(archetype, talent_set)
	local talents = talent_set
	local talents_by_ex_group = {}

	if not talents then return talents_by_ex_group end

	local index = 1
	for key, keystone in pairs(talents) do
		local group = keystone.requirements.exclusive_group or ("unique_" .. index)
		index = index + 1

		if talents_by_ex_group[group] == nil then
			talents_by_ex_group[group] = {}
		end
		talents_by_ex_group[group][key] = keystone

		if keystone.requirements.incompatible_talent then
			local incompat_key = keystone.requirements.incompatible_talent
			local excluded_talent = talents[incompat_key]
			talents_by_ex_group[group][incompat_key] = excluded_talent
		end
	end

	return talents_by_ex_group
end

local get_random_talents_from_sets = function(talent_sets, talent_type)
	local talents = {}
	local chance_to_unroll = mod:get("sett_talent_" .. talent_type .. "_unroll_chance_id")
	local max_talents = mod:get("sett_talent_" .. talent_type .. "_max_group_rolls_id")
	local index = 0
	for key, set in pairs(talent_sets) do
		index = index + 1

		if index > max_talents then break end

		local r_key = random_talent_from_set(set)
		local talent = set[r_key]

		if chance_to_unroll then
			talent.unrolled = math.random() <= chance_to_unroll
		end

		talents[r_key] = talent
	end
	--mod:dump(talents, "" , 10)
	return talents
end

local get_talents_mask = function()
	local ordered_nodes = {}

	for node_id, node in pairs(talent_category_settings) do
		local include_talent_group = mod:get("sett_talent_".. node_id .. "_enabled_id") == true or false
		if include_talent_group and node_id ~= "start" then
			node.node_type = node_id
			table.insert(ordered_nodes, node)
		end
	end

	table.sort(ordered_nodes, function(a, b)
		local a_order = mod:get("sett_talent_".. a.node_type .. "_order_id") or a.sort_order or 10
		local b_order = mod:get("sett_talent_".. b.node_type .. "_order_id") or b.sort_order or 10
        return a_order < b_order
	end)

	local talents_mask = {}

	for index, node in ipairs(ordered_nodes) do
		table.insert(talents_mask, tostring(node.node_type))
	end

	return talents_mask
end

local get_best_matching_profile = function(archetype_name)
	local profiles = mod.all_profiles_data and mod.all_profiles_data.profiles

	if not profiles then 
		return nil 
	end

	local best_matching_profile

	for _, profile in pairs(profiles) do
		--mod:dump(profile, "prof", 1)
		if profile.archetype.name == archetype_name then
			best_matching_profile = profile
		end
	end

	return best_matching_profile
end

LoadoutRandomizerGenerator.generate_random_loadout = function(archetype_name)	
	local data = {}
    data.class = {}
    local class_data = data.class

	local talents_mask = get_talents_mask()

	for name, archetype in pairs(Archetypes) do
		class_data[name] = {}

		get_item_data(archetype, class_data[name])
		map_talent_tree_to_data(archetype, class_data[name])
	end

	data.archetype = archetype_name and Archetypes[archetype_name] or Archetypes[random_element(Archetypes)]
	data.profile = get_best_matching_profile(data.archetype.name)
	local arch_id = data.archetype.name

	data.weapons = {}

	data.weapons.ranged = get_random_weighted_weapon(data.archetype, class_data[arch_id].weapons.ranged)
	data.weapons.melee = get_random_weighted_weapon(data.archetype, class_data[arch_id].weapons.melee)

	local selected_talents = {}

	if talents_mask then

		data.talents = {}

		local roll_talents = function(talent_type, index)
			local roll_stoneless = talent_type == "keystone"
			local talent_data = class_data[arch_id].talents[talent_type]

			local filtered_set = get_filtered_talent_set(data.archetype, talent_data)
			if not filtered_set then return end
			local talents = get_random_talents_from_sets(filtered_set, talent_type)
			for talent_id, talent in pairs(talents) do
				selected_talents[talent_id] = talent
				selected_talents[talent_id].type = talent_type
			end

			if talents ~= nil then
				data.talents[talent_type] = talents
			else
				table.remove(talents_mask, index)
				return
			end
		end

		-- get talents
		for index, talent_type in ipairs(table.clone(talents_mask)) do
			roll_talents(talent_type, index)
		end

		::restart::

		for index, talent_type in ipairs(talents_mask) do
			for talent_id, talent in pairs(data.talents[talent_type]) do
				local conflicting_talent = talent.requirements and talent.requirements.incompatible_talent and selected_talents[talent.requirements.incompatible_talent]
				if conflicting_talent then
					selected_talents[talent.requirements.incompatible_talent] = nil
					roll_talents(conflicting_talent.type)
					goto restart
				end
			end
		end
	end

	LoadoutRandomizerProfile.apply_randomizer_loadout_to_profile_preset(data)

	mod.randomizer_data = data

    return data, talents_mask
end

return LoadoutRandomizerGenerator