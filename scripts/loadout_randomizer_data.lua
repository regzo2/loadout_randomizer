local mod = get_mod("loadout_randomizer")

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
                    range           = { 0, 10 },
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
            --[[
            {
                setting_id      = "randomizer_tests",
                type            = "keybind",
                default_value   = {},
                keybind_trigger = "pressed",
                keybind_type    = "function_call",
                function_name   = "generate_randomization_dataset",
            },
            ]]
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
                setting_id    = "talent_group_id",
                type          = "group",
                sub_widgets   = {
                    {
                        setting_id      = "sett_randomize_talent_ability_id",
                        type            = "checkbox",
                        default_value   = true,
                    },
                    {
                        setting_id      = "sett_randomize_talent_blitz_id",
                        type            = "checkbox",
                        default_value   = true,
                    },
                    {
                        setting_id      = "sett_randomize_talent_keystone_id",
                        type            = "checkbox",
                        default_value   = true,
                    },
                    {
                        setting_id      = "sett_randomize_talent_aura_id",
                        type            = "checkbox",
                        default_value   = true,
                    },
                    {
                        setting_id      = "sett_keystoneless_chance_id",
                        type            = "numeric",
                        default_value   = 0.1,
                        range           = { 0, 1 },
                        decimals_number = 2
                    },
                    --[[
                    {
                        setting_id      = "sett_talent_exclusion_weight_boost_id",
                        type            = "numeric",
                        default_value   = 0.3,
                        range           = { 0, 1 },
                        decimals_number = 2
                    },
                    ]]
                },
            },
            {
                setting_id    = "weapon_weight_group_id",
                type          = "group",
                sub_widgets   = weapon_weight_subwidgets()
            },
        },
    },
}