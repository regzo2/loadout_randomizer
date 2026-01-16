local mod = get_mod("loadout_randomizer")

local weight_range = { 0, 10 }

local default_enabled_talents = {
    ["ability"] = true,
    ["tactical"] = true,
    ["aura"] = true,
}

local default_talent_group_weight = {
    ["ability_modifier"] = 1.4,
    ["keystone_modifier"] = 1.2,
    ["tactical_modifier"] = 1,
    ["aura_modifier"] = 1,
    ["default"] = 0.9,
    ["stat"] = 0.7,
    ["broker_stimm"] = 3,
}

local map_talent_tree_to_data = function(archetype, randomizer_data)
	local all_talent_data = archetype.talents
	local talent_tree_path = string.format("scripts/ui/views/talent_builder_view/layouts/%s_tree", archetype.name)
	local exists = Application.can_get_resource("lua", talent_tree_path)
	local tree = require(talent_tree_path)

	if not exists or not tree then return end

	local talents = {}
    local conflict_counts = {}
    local conflict_groups = {}

    -- first pass, map conflicts
    for key, node in pairs(tree.nodes) do
		if node.type ~= "start" and all_talent_data[node.talent] then
            local incompat_key = node.requirements and node.requirements.incompatible_talent
            local conflict_group = node.requirements and node.requirements.exclusive_group or ("unique_" .. key .. "_" .. node.talent)
            if incompat_key and not conflict_groups[conflict_group] then
                conflict_counts[incompat_key] = conflict_counts[incompat_key] and conflict_counts[incompat_key] + 1 or 1
                conflict_groups[conflict_group] = true
            end
		end
	end

	for key, node in pairs(tree.nodes) do
		if node.type ~= "start" and all_talent_data[node.talent] then
			if not talents[node.type] then
				talents[node.type] = {}
			end

			talents[node.type][node.talent] = {}
            talents[node.type][node.talent].conflict_counts = conflict_counts[node.talent] or nil
		end
	end

    return talents
end

local TalentBuilderViewSettings = require("scripts/ui/views/talent_builder_view/talent_builder_view_settings")
local talent_category_settings = TalentBuilderViewSettings.settings_by_node_type

local talent_settings_subwidgets = function()
    local widget = {}

    for node_id, node in pairs(talent_category_settings) do

        if node_id ~= "start" then
            local talent_subwidgets = {
                {
                    setting_id      = "sett_talent_".. node_id .."_enabled_id",
                    title           = "loc_talent_enabled_id",
                    type            = "checkbox",
                    default_value   = default_enabled_talents[node_id] and true or false,
                },
                {
                    setting_id      = "sett_talent_".. node_id .. "_max_group_rolls_id",
                    title           = "loc_talent_max_group_rolls_id",
                    type            = "numeric",
                    default_value   = 3,
                    range           = { 1, 10 },
                    decimals_number = 0,
                },
                {
                    setting_id      = "sett_talent_".. node_id .. "_unroll_chance_id",
                    title           = "loc_talent_unroll_chance_id",
                    type            = "numeric",
                    default_value   = 0,
                    range           = { 0, 1 },
                    decimals_number = 2
                },
                {
                    setting_id      = "sett_talent_".. node_id .. "_weight_id",
                    title           = "loc_talent_group_weight_id",
                    type            = "numeric",
                    default_value   = default_talent_group_weight[node_id] or 1,
                    range           = weight_range,
                    decimals_number = 2
                },
                --[[
                {
                    setting_id    = "sett_talent_".. node_id .. "_freeroll_chance_id",
                    title           = "loc_talent_freeroll_chance_id",
                    type            = "numeric",
                    default_value   = 0,
                    range           = { 0, 1 },
                    decimals_number = 2
                },
                ]]
            }

            local talent_parent_widget = {
                setting_id          = "talent_" .. node_id .. "_group_id",
                type                = "group",
                sub_widgets         = talent_subwidgets,
                localized_identity  = Localize(node.display_name),
                category_id         = node_id,
            }

            table.insert(widget, talent_parent_widget)
        end
    end 

    table.sort(widget, function(a, b)
        if not a.localized_identity then
            return true
        elseif not b.localized_identity then
            return false
        end
        if a.localized_identity == b.localized_identity then
            return a.category_id < b.category_id
        end
        return a.localized_identity < b.localized_identity
    end)

    return widget
end

local talent_weight_subwidgets = function()
    local Archetypes = require("scripts/settings/archetype/archetypes")

    local widget = {}
    local existing_talents = {}
    local generic_archetype = {
        setting_id          = "archetype_generic_group_id",
        type                = "group",
        sub_widgets         = {},
    }

    table.insert(widget, generic_archetype)

    for _, archetype in pairs(Archetypes) do
        local talent_categories = map_talent_tree_to_data(archetype)

        local talent_group_subwidgets = {}

        for category_id, category in pairs(talent_categories) do

            local talent_subwidgets = {}

            for talent_id, talent in pairs(category) do

                if not existing_talents[talent_id] then

                    local talent_subwidget = {
                        setting_id    = "talent_".. talent_id .. "_weight_id",
                        type            = "numeric",
                        default_value   = talent.conflict_counts and (1 + talent.conflict_counts ^ 0.25) or 1,
                        range           = weight_range,
                        decimals_number = 2
                    }

                    if category_id == "stat" then
                        table.insert(generic_archetype.sub_widgets, talent_subwidget) 
                    else
                        table.insert(talent_subwidgets, talent_subwidget)                  
                    end

                    existing_talents[talent_id] = true
                end
            end

            local talent_category_subwidget = {
                setting_id          = "group_".. archetype.name .. "_talent_" .. category_id .. "_id",
                type                = "group",
                sub_widgets         = talent_subwidgets,
                localized_identity  = Localize(talent_category_settings[category_id].display_name),
                category_id         = category_id,
            }
            if #talent_category_subwidget.sub_widgets > 0 then
                table.insert(talent_group_subwidgets, talent_category_subwidget)
            end
        end

        table.sort(talent_group_subwidgets, function(a, b)
            if a.localized_identity == b.localized_identity then
                return a.category_id < b.category_id
            end
            return a.localized_identity < b.localized_identity
        end)

        local class_subwidget = {
            setting_id          = "group_".. archetype.name .. "_talent_weight_id",
            type                = "group",
            sub_widgets         = talent_group_subwidgets,
        }
        table.insert(widget, class_subwidget)
    end

    return widget
end

local weapon_weight_subwidgets = function()
    local Archetypes = require("scripts/settings/archetype/archetypes")
    local UISettings = require("scripts/settings/ui/ui_settings")
    local WeaponTemplates = require("scripts/settings/equipment/weapon_templates/weapon_templates")
    local patterns = UISettings.weapon_patterns
    local widget = {}

    for pattern_name, pattern in pairs(patterns) do
        local pattern_subwidgets = {}
        for _, mark in pairs(pattern.marks) do
            if WeaponTemplates[mark.name] then
                local weapon_widget = {
                    setting_id    = "weapon_".. mark.name .. "_weight_id",
                    type            = "numeric",
                    default_value   = 1/#pattern.marks,
                    range           = weight_range,
                    decimals_number = 2
                }

                table.insert(pattern_subwidgets, weapon_widget)
            end
        end
        local pattern_group = {
            setting_id          = "pattern_".. pattern_name .. "_group_id",
            type                = "group",
            localized_identity  = Localize(pattern.display_name),
            sub_widgets         = pattern_subwidgets,
        }
        table.insert(widget, pattern_group)
    end

    table.sort(widget, function(a, b)
        return a.localized_identity < b.localized_identity
    end)

	return widget
end

local randomize_cosmetics_subwidgets = function()
    local ItemSlotSettings = require("scripts/settings/item/item_slot_settings")

    local widget = {}

    for slot_name, slot in pairs(ItemSlotSettings) do
        if slot.equipped_in_inventory then
            local slot_subwidget = {
                setting_id      = "sett_".. slot_name .. "_enabled_id",
                type            = "checkbox",
                default_value   = true,
            }
            table.insert(widget, slot_subwidget)
        end
    end

    table.sort(widget, function(a,b)
        return a.setting_id > b.setting_id
    end)

	return widget
end

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id      = "view_randomize_loadout_id",
                tooltip         = "view_randomize_loadout_tip_id",
                type            = "keybind",
                default_value   = {},
                keybind_trigger = "pressed",
                keybind_type    = "function_call",
                function_name   = "open_view",
            },
            {
                setting_id      = "sett_debug_enabled_id",
                type            = "checkbox",
                default_value   = false,
            },
            {
                setting_id    = "weapon_group_id",
                type          = "group",
                sub_widgets   = {
                    {
                        setting_id      = "sett_weapon_display_format_id",
                        type            = "dropdown",
                        default_value   = "condensed",
                        options = {
                            { text = "weapon_mark_family_id", value = "condensed" },
                            { text = "weapon_pattern_mark_family_id", value = "full" },
                        },
                    },
                    {
                        setting_id      = "sett_randomize_weapons_id",
                        type            = "checkbox",
                        default_value   = true,
                    },
                    {
                        setting_id      = "sett_weapon_chance_id",
                        type            = "checkbox",
                        default_value   = true,
                    },
                },
            },
            {
                setting_id    = "talent_tree_group_id",
                type          = "group",
                sub_widgets   = {
                    {
                        setting_id      = "sett_talent_layout_file_path_cost_randomization_id",
                        type            = "checkbox",
                        default_value   = false,
                    },
                    {
                        setting_id      = "sett_specialization_talent_layout_file_path_cost_randomization_id",
                        type            = "checkbox",
                        default_value   = true,
                    },
                },
            },
            {
                setting_id    = "talent_group_id",
                type          = "group",
                sub_widgets   = talent_settings_subwidgets(),
            },
            {
                setting_id    = "cosmetic_group_id",
                type          = "group",
                sub_widgets   = randomize_cosmetics_subwidgets(),
            },
            {
                setting_id    = "weapon_weight_group_id",
                type          = "group",
                sub_widgets   = weapon_weight_subwidgets()
            },
            {
                setting_id    = "talent_weight_group_id",
                type          = "group",
                sub_widgets   = talent_weight_subwidgets()
            },
        },
    },
}