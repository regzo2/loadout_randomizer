
local mod = get_mod("loadout_randomizer")

local Archetypes = require("scripts/settings/archetype/archetypes")
local UISettings = require("scripts/settings/ui/ui_settings")
local ITEM_TYPES = UISettings.ITEM_TYPES
local MasterItems = require("scripts/backend/master_items")
local TalentBuilderViewSettings = require("scripts/ui/views/talent_builder_view/talent_builder_view_settings")
local LoadoutRandomizerProfile = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile")
local talent_category_settings = TalentBuilderViewSettings.settings_by_node_type

local LoadoutRandomizerGenerator = {}

local function get_node_depth_graph(node_map, target_widget_name)

    if not node_map.start_node then return -1 end

    local queue = {{node = node_map.start_node, depth = 1}}
    local visited = {}

    while #queue > 0 do
        local current = table.remove(queue, 1)
        
        if current.node.widget_name == target_widget_name then
            return current.depth
        end

        if not visited[current.node.widget_name] then
            visited[current.node.widget_name] = true
            for _, child_name in ipairs(current.node.children or {}) do
                if node_map.nodes[child_name] then
                    table.insert(queue, {node = node_map.nodes[child_name], depth = current.depth + 1})
                end
            end
        end
    end
    return -1
end

local map_talent_tree_to_data = function(archetype, randomizer_data)
	local all_talent_data = archetype.talents
	local talent_tree_path = string.format("scripts/ui/views/talent_builder_view/layouts/%s_tree", archetype.name)
	local exists = Application.can_get_resource("lua", talent_tree_path)
	local tree = require(talent_tree_path)

	if not exists or not tree then return end

	randomizer_data.talents = {}
	local talents = randomizer_data.talents

	local node_map = {}
		  node_map.nodes = {}
		  node_map.start_node = nil

    for _, node in ipairs(tree.nodes) do
        node_map.nodes[node.widget_name] = node
        if node.type == "start" then 
			node_map.start_node = node 
		end
    end

	for key, node in pairs(tree.nodes) do
		if node.type ~= "start" and all_talent_data[node.talent] then
			if not talents[node.type] then
				talents[node.type] = {}
			end

			talents[node.type][node.talent] = {}
			talents[node.type][node.talent].display_name = all_talent_data[node.talent].display_name
			talents[node.type][node.talent].icon = node.icon
			talents[node.type][node.talent].requirements = node.requirements
			talents[node.type][node.talent].node_id = node.widget_name
			talents[node.type][node.talent].node_depth = get_node_depth_graph(node_map, node.widget_name)
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
    local talents_by_ex_group = {}
    if not talent_set then return talents_by_ex_group end

    local index = 1
    for key, talent_node in pairs(talent_set) do
        local group = talent_node.requirements and talent_node.requirements.exclusive_group 
                      or ("unique_" .. key .. "_" .. index)
        index = index + 1

        if not talents_by_ex_group[group] then
            talents_by_ex_group[group] = {}
        end
        
        talents_by_ex_group[group][key] = talent_node
    end

    return talents_by_ex_group
end

local random_talent_from_set = function(talent_set)
    local weighted_talent_set = {}
    local weighted_count = 0

    for talent_id, talent in pairs(talent_set) do
        local talent_weight = mod:get("talent_" .. talent_id .. "_weight_id") or 1
        if talent_weight > 0 then
            weighted_count = weighted_count + talent_weight
            table.insert(weighted_talent_set, {id = talent_id, weight = talent_weight})
        end
    end

    if weighted_count <= 0 then return nil end

    local target = math.random() * weighted_count
    local current = 0
    for _, entry in ipairs(weighted_talent_set) do
        current = current + entry.weight
        if target <= current then
            return entry.id
        end
    end
    return weighted_talent_set[#weighted_talent_set].id
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

local get_group_weight_sum = function(talent_id, all_categories)
    for _, category in pairs(all_categories) do
        if category[talent_id] then
            local sum = 0
            for id, _ in pairs(category) do
                sum = sum + (mod:get("talent_" .. id .. "_weight_id") or 1)
            end
            return sum
        end
    end
    return 1
end

LoadoutRandomizerGenerator.generate_random_loadout = function(archetype_name)   
    local data = { class = {}, talents = {}, weapons = {} }
    
    -- 1. Setup Archetype Data
    for name, arch in pairs(Archetypes) do
        data.class[name] = {}
        get_item_data(arch, data.class[name])
        map_talent_tree_to_data(arch, data.class[name])
    end

    data.archetype = archetype_name and Archetypes[archetype_name] or Archetypes[random_element(Archetypes)]
    local arch_id = data.archetype.name
    local all_arch_talents = data.class[arch_id].talents
    local forbidden_ids = {}

    local conflict_map = {}
    for cat_name, category_set in pairs(all_arch_talents) do
        for t_id, t_node in pairs(category_set) do
            local enemy_id = t_node.requirements and t_node.requirements.incompatible_talent
            if enemy_id then
                conflict_map[t_id] = enemy_id
                conflict_map[enemy_id] = t_id
            end
        end
    end

    local talents_mask = get_talents_mask()

	for _, talent_type in ipairs(talents_mask) do
		local category_data = all_arch_talents[talent_type]
		if category_data then
			local filtered_groups = get_filtered_talent_set(data.archetype, category_data)
			data.talents[talent_type] = data.talents[talent_type] or {}

			for group_id, group_set in pairs(filtered_groups) do
				local rollable_candidates = {}
				local forced_winner = nil
				
				for t_id, t_node in pairs(group_set) do
					if not forbidden_ids[t_id] then
						local enemy_id = conflict_map[t_id]
						
						if enemy_id and not forbidden_ids[enemy_id] then
							local weight_a = mod:get("talent_" .. t_id .. "_weight_id") or 1
							local weight_b = mod:get("talent_" .. enemy_id .. "_weight_id") or 1
							
							if math.random() * (weight_a + weight_b) < weight_a then
								rollable_candidates[t_id] = t_node
								forbidden_ids[enemy_id] = true
								forced_winner = t_id
							else
								forbidden_ids[t_id] = true
							end
						else
							rollable_candidates[t_id] = t_node
						end
					end
				end

				local selected_key = nil
				if forced_winner and rollable_candidates[forced_winner] then
					selected_key = forced_winner
				else
					selected_key = random_talent_from_set(rollable_candidates)
				end

				if selected_key then
					data.talents[talent_type][selected_key] = group_set[selected_key]
					
					local enemy = conflict_map[selected_key]
					if enemy then
						forbidden_ids[enemy] = true
					end
				end
			end
		end
	end

    data.weapons.ranged = get_random_weighted_weapon(data.archetype, data.class[arch_id].weapons.ranged)
    data.weapons.melee = get_random_weighted_weapon(data.archetype, data.class[arch_id].weapons.melee)
	data.profile = get_best_matching_profile(arch_id)

	if data.profile then
    	LoadoutRandomizerProfile.apply_randomizer_loadout_to_profile_preset(data)
	end
    
    return data, talents_mask
end

return LoadoutRandomizerGenerator