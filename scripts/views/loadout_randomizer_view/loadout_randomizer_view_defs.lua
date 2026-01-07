local mod = get_mod("loadout_randomizer")

local UIWidget = require("scripts/managers/ui/ui_widget")
local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local ColorUtilities = require("scripts/utilities/ui/colors")
local TalentBuilderViewSettings = require("scripts/ui/views/talent_builder_view/talent_builder_view_settings")
local archetype_backgrounds_by_name = TalentBuilderViewSettings.archetype_backgrounds_by_name
local archetype_badge_texture_by_name = TalentBuilderViewSettings.archetype_badge_texture_by_name


--local node_definitions = require("scripts/ui/views/talent_builder_view/talent_builder_view_node_definitions")

local background_size = {900, 400}
local talent_node_size = {150, 150}
local weapon_icon_size = {128 * 2.33, 128 * 2.33}

local aura_gradient_map = "content/ui/textures/color_ramps/talent_aura"
local ability_gradient_map = "content/ui/textures/color_ramps/talent_ability"
local keystone_gradient_map = "content/ui/textures/color_ramps/talent_keystone"
local blitz_gradient_map = "content/ui/textures/color_ramps/talent_blitz"
local default_gradient_map = "content/ui/textures/color_ramps/talent_default"

local scenegraph_definition = {
	screen = {
		scale = "fit",
		size = {
			1920,
			1080,
		},
	},
    screen_blackout = {
        parent = "screen",
        horizontal_alignment = "center",
		vertical_alignment = "center",
        size = { 10000, 10000 },
        position = { 0, 0, 0 }
    },
    background = {
        parent = "screen",
        horizontal_alignment = "center",
		vertical_alignment = "center",
        --scale = "fit",
        size = { background_size[1], background_size[2] },
        position = { 0, 0, 1 }
    },
    layout_background = {
        parent = "background",
        horizontal_alignment = "center",
		vertical_alignment = "top",
        size = { background_size[1], background_size[2] },
        --scale = "fit",
        position = { 0, -50, 10 }
    },
    weapon_divider = {
        parent = "background",
        horizontal_alignment = "center",
		vertical_alignment = "center",
        --scale = "fit",
        size = { background_size[1], 50 },
        position = { 0, -225, 10 }
    },
    talent_divider = {
        parent = "background",
        horizontal_alignment = "center",
		vertical_alignment = "center",
        --scale = "fit",
        size = { background_size[1], 50 },
        position = { 0, 120, 10 }
    },
    randomize_button = {
        parent = "background",
        horizontal_alignment = "center",
		vertical_alignment = "bottom",
        --scale = "fit",
        size = { 375, 75 },
        position = { 0, 75/2, 10 }
    },
    randomize_weapon = {
        parent = "background",
        horizontal_alignment = "center",
		vertical_alignment = "center",
        --scale = "fit",
        size = {500, 150},
        position = { 0, 0, 1 }
    },
    randomize_talents = {
        parent = "background",
        horizontal_alignment = "center",
		vertical_alignment = "center",
        --scale = "fit",
        size = {500, 150},
        position = { 0, 240, 1 }
    },
    randomize_talents_sub = {
        parent = "randomize_talents",
        horizontal_alignment = "center",
		vertical_alignment = "center",
        --scale = "fit",
        size = {500, 150},
        position = { 125, 0, 1 }
    },
    randomize_weapon_ranged_icon = {
        parent = "randomize_weapon",
        horizontal_alignment = "center",
		vertical_alignment = "center",
        --scale = "fit",
        size = {400, 150},
        position = { -200, 0, 1 }
    },
    randomize_weapon_melee_icon = {
        parent = "randomize_weapon",
        horizontal_alignment = "center",
		vertical_alignment = "center",
        --scale = "fit",
        size = {400, 150},
        position = { 200, 0, 1 }
    },
    --[[
    node_keystone_icon = {
        parent = "randomize_talents",
        horizontal_alignment = "center",
        vertical_alignment = "center",
        --scale = "fit",
        size = {200, 150},
        position = { -325, 0, 1 }
    },
    node_aura_icon = {
        parent = "randomize_talents",
        horizontal_alignment = "center",
        vertical_alignment = "center",
        --scale = "fit",
        size = {200, 150},
        position = { -325, 0, 1 }
    },
    node_blitz_icon = {
        parent = "randomize_talents",
        horizontal_alignment = "center",
        vertical_alignment = "center",
        --scale = "fit",
        size = {200, 150},
        position = { -325, 0, 1 }
    },
    node_ability_icon = {
        parent = "randomize_talents",
        horizontal_alignment = "center",
        vertical_alignment = "center",
        --scale = "fit",
        size = {200, 150},
        position = { -325, 0, 1 }
    },
    ]]--
	canvas = {
		parent = "screen",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		size = {
			1920,
			1080,
		},
		position = {
			0,
			0,
			0,
		},
	},
    randomize_archetype_text = {
        parent = "background",
        vertical_alignment = "top",
        horizontal_alignment = "center",
        size = { 650, 42 },
        position = { 0, 25, 10 }
    },
    loadout_randomizer_header = {
        parent = "screen",
        vertical_alignment = "top",
        horizontal_alignment = "left",
        size = { 300, 42 },
        position = { 0, 0, 0 }
    },
}

local change_function_weapon_icon = function(content, style)
    --[[
    if content.icon_load_id then
        Managers.ui:unload_item_icon(content.icon_load_id)
    end
    ]]--

    local cb_on_item_icon_unloaded = function()
        local material_values = style.material_values

        material_values.use_placeholder_texture = 1
        material_values.use_render_target = 0
        material_values.rows = nil
        material_values.columns = nil
        material_values.render_target = nil
    end

    local cb_on_item_icon_loaded = function(grid_index, rows, columns, render_target)

        local material_values = style.material_values

        material_values.use_placeholder_texture = 0
        material_values.use_render_target = 1
        material_values.rows = rows
        material_values.columns = columns
        material_values.grid_index = grid_index - 1
        material_values.render_target = render_target
    end

    local load_cb = callback(cb_on_item_icon_loaded)
    local unload_cb = callback(cb_on_item_icon_unloaded)

    local item = content.item

    local render_context = {
			size = weapon_icon_size,
		}

    if item then
        content.icon_load_id = Managers.ui:load_item_icon(item, load_cb, render_context, nil, nil, unload_cb)
    end
end

local change_function_weapon_text = function(content, style)
    if not content or not content.item then
        return
    end

    local item = content.item

    if item.display_name == "n/a" then
        content.text = "Attachment"
        return
    end

    local display_name = Localize(item.display_name)
    if mod.sett_weapon_display_format == "condensed" and item.weapon_template then
        local weapon_family_name = "loc_weapon_family_" .. item.weapon_template
        local weapon_pattern_name = "loc_weapon_pattern_" .. item.weapon_template
        local weapon_mark_name = "loc_weapon_mark_" .. item.weapon_template
        display_name = Localize(weapon_mark_name) .. " • " .. Localize(weapon_family_name)
    elseif mod.sett_weapon_display_format == "full" and item.weapon_template then
        local weapon_family_name = "loc_weapon_family_" .. item.weapon_template
        local weapon_pattern_name = "loc_weapon_pattern_" .. item.weapon_template
        local weapon_mark_name = "loc_weapon_mark_" .. item.weapon_template
        display_name = Localize(weapon_pattern_name) .. " • " .. Localize(weapon_mark_name) .. "\n" .. Localize(weapon_family_name)
    end

    content.text = display_name

    if #content.text > 25 then
        --style.font_size = math.max(14, -0.8 * (#content.text - 25) + 22)
    end
end

local widget_definitions = {
    background = UIWidget.create_definition({
        {
            pass_type = "texture",
            value = "content/ui/materials/backgrounds/terminal_basic",
            style = {
                horizontal_alignment = "center",
                scale_to_material = true,
                vertical_alignment = "center",
                size_addition = {
                    18,
                    24,
                },
                color = Color.terminal_grid_background(nil, true),
            },
        },
        {
            pass_type = "texture",
            value = "content/ui/materials/dividers/horizontal_frame_big_upper",
            style = {
                horizontal_alignment = "center",
                scale_to_material = false,
                vertical_alignment = "top",
                offset = {0, -12, 0},
                size = { background_size[1], 36 },
                --color = Color.terminal_grid_background(hide_background and 0 or nil, true),
            },
        },
        {
            pass_type = "texture",
            value = "content/ui/materials/dividers/horizontal_frame_big_lower",
            style = {
                horizontal_alignment = "center",
                scale_to_material = false,
                vertical_alignment = "bottom",
                offset = {0, 12, 0},
                size = { background_size[1], 36 },
                --color = Color.terminal_grid_background(hide_background and 0 or nil, true),
            },
        },
    }, "background"),
    screen_blackout = UIWidget.create_definition({
        {
            pass_type = "rect",
            style_id = "rect",
            value_id = "rect",
            style = {
                horizontal_alignment = "center",
                vertical_alignment = "center",
                color = Color.black(0, true),
                offset = {0, 0, 0},
            },
        },
    }, "screen_blackout"),
    layout_background = UIWidget.create_definition({
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_bg_top_gradient_zealot",
			value_id = "image",
            style_id = "image",
			style = {
				horizontal_alignment = "center",
				vertical_alignment = "top",
				size = {
                    1696 * 0.66,
					1074 * 0.66,
                    --[[
					1696,
					1074,
                    ]]--
				},
				color = {
					192, 128, 128, 128,
				},
				offset = {
					0,
					background_size[2]/8,
					-10,
				},
			},
            change_function = function(content, style)
                if not content or not content.archetype then
                    return
                end
                content.image = archetype_backgrounds_by_name[content.archetype.name]
            end,
		},
        --[[
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_bg_top_gradient_zealot",
			value_id = "image_l",
			style = {
				horizontal_alignment = "left",
				vertical_alignment = "top",
				size = {
                    1696 * 2,
					1074 * 2,
				},
				color = {
					192, 128, 128, 128,
				},
				offset = {
					-2400,
					0,
					-10,
				},
			},
            change_function = function(content, style)
                if not content or not content.archetype then
                    return
                end
                content.image_l = archetype_backgrounds_by_name[content.archetype.name]
            end,
		},
        ]]--
	}, "layout_background"),
    weapon_divider = UIWidget.create_definition({
        {
			pass_type = "texture",
			style_id = "divider",
			value = "content/ui/materials/dividers/horizontal_frame_big_middle",
            style = {
            },
		},
    }, "weapon_divider"),
    talent_divider = UIWidget.create_definition({
        {
			pass_type = "texture",
			style_id = "divider",
			value = "content/ui/materials/dividers/horizontal_frame_big_middle",
            style = {
            },
		},
    }, "talent_divider"),
    randomize_weapon_ranged_icon = UIWidget.create_definition({
        {
            value = "content/ui/materials/icons/items/containers/item_container_landscape",
            value_id = "icon",
            style_id = "icon",
            pass_type = "texture",
            style = {
                material_values = {
                    use_placeholder_texture = 1
                },
                horizontal_alignment = "center",
                vertical_alignment = "bottom",
                size = weapon_icon_size,
                color = UIHudSettings.color_tint_main_1,
                offset = {
                    0,
                    -2,
                    5
                },
            },
            change_function = change_function_weapon_icon,
        },
        {
            value = "content/ui/materials/icons/items/containers/item_container_landscape",
            value_id = "icon_frame",
            style_id = "icon_frame",
            pass_type = "texture",
            style = {
                horizontal_alignment = "center",
                vertical_alignment = "center",
                size = { 128 * 3, 48 * 3 },
                color = Color.white(32, true),
                offset = {
                    0,
                    -48 * 1.5,
                    -1
                }
            },
            change_function = function(content, style)
                if not content or not content.item then
                    return
                end

                if content.item.hud_icon ~= content.icon_frame then
                    if content.package_id then
                        content.icon_frame = "content/ui/materials/icons/items/containers/item_container_landscape"
                        Managers.package:release(content.package_id)
                        content.package_id = nil
                    end

                    local hud_icon = content.item.hud_icon

                    local cb = function(package_id)
                        content.icon_frame = hud_icon
                        content.package_id = package_id
                    end

                    Managers.package:load(hud_icon, "loadout_randomizer_ui_test", cb)
                end
            end,
        },
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "",
            style = {
                font_type = "proxima_nova_bold",
                font_size = 24,
                text_vertical_alignment = "top",
                text_horizontal_alignment = "center",
                text_color = Color.terminal_text_header(255, true),
                offset = { 0, 120, 1 }
            },
            change_function = change_function_weapon_text,
        },
    }, "randomize_weapon_ranged_icon"),
    randomize_weapon_melee_icon = UIWidget.create_definition({
        {
            value = "content/ui/materials/icons/items/containers/item_container_landscape",
            value_id = "icon",
            style_id = "icon",
            pass_type = "texture",
            style = {
                material_values = {
                    use_placeholder_texture = 1
                },
                horizontal_alignment = "center",
                vertical_alignment = "bottom",
                size = weapon_icon_size,
                offset = {
                    0,
                    -2,
                    5
                }
            },
            change_function = change_function_weapon_icon,
        },
        {
            value = "content/ui/materials/icons/items/containers/item_container_landscape",
            value_id = "icon_frame",
            style_id = "icon_frame",
            pass_type = "texture",
            style = {
                horizontal_alignment = "center",
                vertical_alignment = "center",
                size = { 128 * 3, 48 * 3 },
                color = Color.white(32, true),
                offset = {
                    0,
                    -48 * 1.5,
                    -1
                }
            },
            change_function = function(content, style)
                if not content or not content.item then
                    return
                end

                if content.item.hud_icon ~= content.icon_frame then
                    if content.package_id then
                        content.icon_frame = "content/ui/materials/icons/items/containers/item_container_landscape"
                        Managers.package:release(content.package_id)
                        content.package_id = nil
                    end

                    local hud_icon = content.item.hud_icon

                    local cb = function(package_id)
                        content.icon_frame = hud_icon
                        content.package_id = package_id
                    end

                    Managers.package:load(hud_icon, "loadout_randomizer_ui_test", cb)
                end
            end,
        },
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "",
            style = {
                font_type = "proxima_nova_bold",
                font_size = 24,
                text_vertical_alignment = "top",
                text_horizontal_alignment = "center",
                text_color = Color.terminal_text_header(255, true),
                offset = { 0, 120, 1 }
            },
            change_function = change_function_weapon_text,
        },
    }, "randomize_weapon_melee_icon"),
    randomize_button = UIWidget.create_definition(ButtonPassTemplates.default_button, "randomize_button", {
        original_text = "RANDOMIZE LOADOUT",
            hotspot = {
            on_pressed_sound = UISoundEvents.default_click
        },
    }, nil, {
        background = {
            default_color = Color.terminal_background(255, true),
            selected_color = Color.terminal_background_selected(255, true)
        },
    }),
    loadout_randomizer_header = UIWidget.create_definition({
        {
            pass_type = "rect",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "center",
                color = Color.terminal_background(255, true),
                offset = { 0, 0, 0 }
            }
        },
        {
            pass_type = "texture",
            value = "content/ui/materials/frames/frame_tile_2px",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "center",
                color = Color.terminal_frame(255, true),
                offset = { 0, 0, 2 }
            }
        },
        {
            pass_type = "text",
            value = "Loadout Randomizer",--Localize("loc_item_information_stats_title_modifiers"),
            style = {
                font_type = "machine_medium",
                font_size = 32,
                text_vertical_alignment = "center",
                text_horizontal_alignment = "center",
                text_color = Color.terminal_text_body(255, true),
                offset = { 0, 0, 1 }
            }
        },
    }, "loadout_randomizer_header"),
    randomize_archetype_text = UIWidget.create_definition({
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "LOADOUT RANDOMIZER",--Localize("loc_item_information_stats_title_modifiers"),
            style = {
                font_type = "machine_medium",
                font_size = 92,
                text_vertical_alignment = "top",
                text_horizontal_alignment = "center",
                material = "content/ui/materials/font_gradients/slug_font_gradient_gold",
                text_color = Color.white(255, true),
                offset = { 0, 50, 1 }
            },
            change_function = function(content, style)
                if not content or not content.archetype then
                    return
                end
                content.text = Localize(content.archetype.archetype_name)
            end,
        },
        {
			pass_type = "texture",
            value = "content/ui/materials/icons/class_badges/container",
			value_id = "icon",
            style_id = "icon",
			style = {
				horizontal_alignment = "center",
				vertical_alignment = "center",
				size = {
                    400 * 1,
                    240 * 1,
                },
				color = {
					255, 255, 255, 255,
				},
				offset = {
					0,
					-50,
					10,
				},
                material_values = {
                    icon = "content/ui/materials/frames/talents/talent_bg_top_gradient_zealot",
                },
			},
            change_function = function(content, style)
                if not content or not content.archetype then
                    return
                end
                --content.icon = archetype_badge_texture_by_name[content.archetype.name]
            end,
		},
    }, "randomize_archetype_text"),
}

local node_widget_definitions = {
    node_default_icon = {
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
            style_id = "icon",
            value_id = "icon",
			style = {
                material_values = {
                    frame = "content/ui/textures/frames/talents/circular_frame",
					icon_mask = "content/ui/textures/frames/talents/circular_frame_mask",
                    icon = "content/ui/textures/icons/talents/zealot/zealot_aura_the_emperor_demand",
                    gradient_map = default_gradient_map,
					intensity = -1,
					saturation = 1,
				},
                size = talent_node_size,
				horizontal_alignment = "center",
				vertical_alignment = "upper",
			},
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end
                style.material_values.icon = content.talent.icon
            end,
		},
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
			style = {
                material_values = {
                    frame = "content/ui/textures/frames/talents/circular_frame",
				},
                size = talent_node_size,
                offset = { 8, 8, -1 },
                color = {64, 0, 0, 0},
				horizontal_alignment = "center",
				vertical_alignment = "upper",
			},
		},
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "Sample",--Localize("loc_item_information_stats_title_modifiers"),
            style = {
                font_type = "proxima_nova_bold",
                font_size = 24,
                text_vertical_alignment = "top",
                text_horizontal_alignment = "center",
                text_color = Color.terminal_text_header(255, true),
                offset = { 0, 150, 1 },
                horizontal_alignment = "center",
                size = {talent_node_size[1], talent_node_size[2]},
            },
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end

                local text = Localize(content.talent.display_name)

                if #content.text > 25 then
                    style.font_size = math.max(14, -1.2 * (#content.text - 25) + 22)
                end
                
                if content.talent.unrolled then
                    content.text = mod:localize("loc_talent_default_unrolled")
                else
                    content.text = text
                end
            end,
        },
    },
    node_ability_icon = {
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
            style_id = "icon",
            value_id = "icon",
			style = {
                material_values = {
                    icon = "content/ui/textures/icons/talents/zealot/zealot_ability_bolstering_prayer",
                    fill_amount = 0.5,
					fill_color = ColorUtilities.format_color_to_material({
						255,
                        64,
                        223,
                        208,
					}),
					intensity = -1,
					saturation = 1,
				},
                offset = {0, -40, 0},
                size = {talent_node_size[1] * 1.25, talent_node_size[2] * 1.25},
				horizontal_alignment = "center",
				vertical_alignment = "upper",
			},
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end
                style.material_values.icon = content.talent.icon
            end,
		},
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
            style_id = "icon_shadow",
            value_id = "icon_shadow",
			style = {
                material_values = {
                    icon = "content/ui/textures/icons/talents/zealot/zealot_ability_bolstering_prayer",
				},
                size = {talent_node_size[1] * 1.25, talent_node_size[2] * 1.25},
                offset = { 8, 8-40, -1 },
                color = {64, 0, 0, 0},
				horizontal_alignment = "center",
				vertical_alignment = "upper",
			},
		},
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "Sample",--Localize("loc_item_information_stats_title_modifiers"),
            style = {
                font_type = "proxima_nova_bold",
                font_size = 24,
                text_vertical_alignment = "top",
                text_horizontal_alignment = "center",
                text_color = Color.terminal_text_header(255, true),
                offset = { 0, 150, 1 },
                horizontal_alignment = "center",
                size = {talent_node_size[1], talent_node_size[2]},
            },
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end

                local text = Localize(content.talent.display_name)

                if #content.text > 25 then
                    style.font_size = math.max(14, -1.2 * (#content.text - 25) + 22)
                end
                
                if content.talent.unrolled then
                    content.text = mod:localize("loc_talent_ability_unrolled")
                else
                    content.text = text
                end
            end,
        },
    },
    node_aura_icon = {
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
            style_id = "icon",
            value_id = "icon",
			style = {
                material_values = {
                    frame = "content/ui/textures/frames/talents/circular_frame",
					icon_mask = "content/ui/textures/frames/talents/circular_frame_mask",
                    icon = "content/ui/textures/icons/talents/zealot/zealot_aura_the_emperor_demand",
                    gradient_map = aura_gradient_map,
					intensity = -1,
					saturation = 1,
				},
                size = talent_node_size,
				horizontal_alignment = "center",
				vertical_alignment = "upper",
			},
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end
                style.material_values.icon = content.talent.icon
            end,
		},
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
			style = {
                material_values = {
                    frame = "content/ui/textures/frames/talents/circular_frame",
				},
                size = talent_node_size,
                offset = { 8, 8, -1 },
                color = {64, 0, 0, 0},
				horizontal_alignment = "center",
				vertical_alignment = "upper",
			},
		},
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "Sample",--Localize("loc_item_information_stats_title_modifiers"),
            style = {
                font_type = "proxima_nova_bold",
                font_size = 24,
                text_vertical_alignment = "top",
                text_horizontal_alignment = "center",
                text_color = Color.terminal_text_header(255, true),
                offset = { 0, 150, 1 },
                horizontal_alignment = "center",
                size = {talent_node_size[1], talent_node_size[2]},
            },
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end

                local text = Localize(content.talent.display_name)

                if #content.text > 25 then
                    style.font_size = math.max(14, -1.2 * (#content.text - 25) + 22)
                end
                
                if content.talent.unrolled then
                    content.text = mod:localize("loc_talent_aura_unrolled")
                else
                    content.text = text
                end
            end,
        },
    },
    node_blitz_icon = {
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
            style_id = "icon",
			style = {
                material_values = {
					frame = "content/ui/textures/frames/talents/square_frame",
					icon_mask = "content/ui/textures/frames/talents/square_frame_mask",
                    icon = "content/ui/textures/icons/talents/zealot/zealot_blitz_fire_grenade",
                    gradient_map = blitz_gradient_map,
					intensity = -1,
					--saturation = 1,
				},
                size = talent_node_size,
				horizontal_alignment = "center",
				vertical_alignment = "upper",
                --color = Color.terminal_grid_background(hide_background and 0 or nil, true),
				color = Color.white(255, true),
			},
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end
                style.material_values.icon = content.talent.icon
            end,
		},
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
			style = {
                material_values = {
                    frame = "content/ui/textures/frames/talents/square_frame",
				},
                size = talent_node_size,
                offset = { 8, 8, -1 },
                color = {64, 0, 0, 0},
				horizontal_alignment = "center",
				vertical_alignment = "upper",
			},
		},
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "Sample",--Localize("loc_item_information_stats_title_modifiers"),
            style = {
                font_type = "proxima_nova_bold",
                font_size = 24,
                text_vertical_alignment = "top",
                text_horizontal_alignment = "center",
                text_color = Color.terminal_text_header(255, true),
                offset = { 0, 150, 1 },
                horizontal_alignment = "center",
                size = {talent_node_size[1], talent_node_size[2]},
            },
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end

                local text = Localize(content.talent.display_name)

                if #content.text > 25 then
                    style.font_size = math.max(14, -1.2 * (#content.text - 25) + 22)
                end
                
                if content.talent.unrolled then
                    content.text = mod:localize("loc_talent_blitz_unrolled")
                else
                    content.text = text
                end
            end,
        },
    },
    node_keystone_icon = {
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
            style_id = "icon",
			style = {
                material_values = {
					frame = "content/ui/textures/frames/talents/circular_frame",
					icon_mask = "content/ui/textures/frames/talents/circular_frame_mask",
                    icon = "content/ui/textures/icons/talents/zealot/zealot_keystone_martyrdom",
                    gradient_map = keystone_gradient_map,
					intensity = -1,
					--saturation = 1,
				},
                size = talent_node_size,
				horizontal_alignment = "center",
				vertical_alignment = "upper",
				--color = Color.white(255, true),
			},
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end
                style.material_values.icon = content.talent.icon
            end,
		},
        {
			pass_type = "texture",
			value = "content/ui/materials/frames/talents/talent_icon_container",
			style = {
                material_values = {
                    frame = "content/ui/textures/frames/talents/circular_frame",
				},
                size = talent_node_size,
                offset = { 8, 8, -1 },
                color = {64, 0, 0, 0},
				horizontal_alignment = "center",
				vertical_alignment = "upper",
			},
		},
        {
            pass_type = "text",
            value_id = "text",
            style_id = "text",
            value = "Sample",--Localize("loc_item_information_stats_title_modifiers"),
            style = {
                font_type = "proxima_nova_bold",
                font_size = 24,
                text_vertical_alignment = "top",
                text_horizontal_alignment = "center",
                text_color = Color.terminal_text_header(255, true),
                offset = { 0, 150, 1 },
                horizontal_alignment = "center",
                size = {talent_node_size[1], talent_node_size[2]},
            },
            change_function = function(content, style)
                if not content or not content.talent then
                    return
                end

                local text = Localize(content.talent.display_name)

                if #content.text > 25 then
                    style.font_size = math.max(14, -1.2 * (#content.text - 25) + 22)
                end
                
                if content.talent.unrolled then
                    content.text = mod:localize("loc_talent_keystone_unrolled")
                else
                    content.text = text
                end
            end,
        },
    },
}

local legend_inputs = {
	{
		input_action = "back",
		on_pressed_callback = "_on_back_pressed",
		display_name = "loc_class_selection_button_back",
		alignment = "left_alignment",
	},
}

local reset_end_time = 0.3

local anim_lerp = function(from, to, t)
    return (1-t) * from + t * to
end

local animations = {
	on_enter = {
		{
			end_time = 0.6,
			name = "move",
			start_time = 0,
			init = function (parent, ui_scenegraph, scenegraph_definition, widgets, params)
				parent._render_settings.alpha_multiplier = 0

                local function contains_initial_widgets(widget)
                    local base_widgets = {
                        "randomize_weapon_ranged_icon",
                        "randomize_weapon_melee_icon",
                        "weapon_divider",
                        "talent_divider",
                    }

                    for _, widget_name in pairs(base_widgets) do
                        if widget_name == widget.name then 
                            return true 
                        end
                    end

                    return false
                end

                for key, widget in pairs(widgets) do
                    if contains_initial_widgets(widget) then
                        widget.alpha_multiplier = 0
                    end
                end

			end,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local anim_progress = math.easeOutCubic(progress)
				parent._render_settings.alpha_multiplier = anim_progress
			end,
		},
	},
    fade_to = {
		{
			end_time = 1,
			name = "move",
			start_time = 0,
			init = function (parent, ui_scenegraph, scenegraph_definition, widgets, params)
                local select_widgets = params.widgets
                params.from = {}

                for widget_id, widget in pairs(select_widgets) do
				    params.from[widget_id] = widget.alpha_multiplier or 1
                end
			end,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
                local select_widgets = params.widgets
				local anim_progress = math.easeOutCubic(progress)

                for widget_id, widget in pairs(select_widgets) do
                    local lerp = anim_lerp(params.from[widget_id], params.fade_to, anim_progress)
                    --mod:echo(lerp)
				    widget.alpha_multiplier = lerp
                end
			end,
		},
	},
    on_start_bg = {
		{
			end_time = 0.6,
			name = "move",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(progress)
                local bg = ui_scenegraph.background
                local text_widget = parent._widgets_by_name.randomize_archetype_text
                params.original_text_size = text_widget.style.text.font_size

                parent:_set_scenegraph_position("background", ease_progress * (0 - 400), ease_progress * -50, nil)
                parent:_set_scenegraph_size("background", nil, 400 + ease_progress * 375)
                parent:_set_scenegraph_position("randomize_button", nil, 75 + ease_progress * 50)
                parent:_set_scenegraph_position("layout_background", nil, -50 - ease_progress * 50)

                --gbl_defs3 = parent._ui_scenegraph

                text_widget.style.text.font_size = params.original_text_size - ease_progress * 1

                local function contains_initial_widgets(widget)
                    local base_widgets = {
                        "background",
                        "randomize_button",
                        "randomize_archetype_text",
                        "layout_background",
                    }

                    for _, widget_name in pairs(base_widgets) do
                        if widget_name == widget.name then 
                            return true 
                        end
                    end

                    return false
                end

                for key, widget in pairs(widgets) do
                    if contains_initial_widgets(widget) then
                        widget.alpha_multiplier = ease_progress
                    end
                end
			end,
		},
	},
    on_item_reset = {
		{
			end_time = reset_end_time,
			name = "init",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(1-progress)

                local widget = params.widget
                local style = widget.style

                local function clamp(value, min_val, max_val)
                    return math.min(math.max(value, min_val), max_val)
                end

                local function normalize(val, min_val, max_val)
                    if max_val == min_val then return 0 end -- Avoid division by zero
                    return (val - min_val) / (max_val - min_val)
                end

                local function range(val, min, max)
                    local normalized = normalize(val, min, max)
                    local clamped = clamp(normalized, 0, 1)
                    return clamped
                end

                local icon_progress = range(ease_progress, 0, 0.5)
                local icon_frame_progress = range(ease_progress, 0.25, 1)

                style.icon.color = {icon_progress * 255, 255, 255, 255}
                style.icon_frame.color = {icon_frame_progress * 32, 255, 255, 255}
                style.text.text_color = Color.terminal_text_header(ease_progress * 255, true)
                widget.alpha_multiplier = ease_progress
			end,
		},
	},
    on_item_roll = {
		{
			end_time = 1,
			name = "move",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(progress)

                local widget = params.widget
                local style = widget.style

                local function clamp(value, min_val, max_val)
                    return math.min(math.max(value, min_val), max_val)
                end

                local function normalize(val, min_val, max_val)
                    if max_val == min_val then return 0 end -- Avoid division by zero
                    return (val - min_val) / (max_val - min_val)
                end

                local function range(val, min, max)
                    local normalized = normalize(val, min, max)
                    local clamped = clamp(normalized, 0, 1)
                    return clamped
                end

                local icon_progress = range(ease_progress, 0, 0.25)
                local icon_frame_progress = range(ease_progress, 0.25, 1)

                --local bg_scenegraph = ui_scenegraph.background
                --bg_scenegraph.size[2] = ease_progress * 500

                style.icon.color = {icon_progress * 255, 255, 255, 255}
                style.icon_frame.color = {icon_frame_progress * 32, 255, 255, 255}
                style.text.text_color = Color.terminal_text_header(ease_progress * 255, true)
                widget.alpha_multiplier = ease_progress

                if (not params.played_sound) and ease_progress >= 0.2 then
                    parent:_play_sound(UISoundEvents.weapons_equip_weapon)
                    params.played_sound = true
                end
			end,
		},
	},
    on_talent_reset = {
		{
			end_time = reset_end_time,
			name = "init",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(1-progress)

                local widget = params.widget
                local style = widget.style

                style.icon.material_values.intensity = ease_progress - 1
                style.text.text_color = Color.terminal_text_header(ease_progress * 255, true)
                widget.alpha_multiplier = math.min(1, ease_progress * 2)
			end,
		},
	},
    on_talent_roll = {
		{
			end_time = 2,
			name = "move",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(progress)

                local widget = params.widget
                local style = widget.style

                local talent = widget.content.talent

                if talent and talent.unrolled then
                    style.icon.material_values.intensity = ((-(ease_progress - 1)) ^ 2) - 1
                    style.text.text_color = Color.terminal_text_header((progress ^ 2) * 255, true)
                    widget.alpha_multiplier = math.max(math.min(1, ease_progress * 2),0)

                    if (not params.played_sound_1) and ease_progress >= 0.2 then
                        parent:_play_sound(UISoundEvents.talent_node_select_stat)
                        params.played_sound_1 = true
                    end

                    if (not params.played_sound_2) and ease_progress >= 0.5 then
                        --parent:_play_sound(UISoundEvents.end_screen_summary_plasteel_zero)
                        --parent:_play_sound(UISoundEvents.end_screen_summary_diamantine_stop)
                        parent:_play_sound(UISoundEvents.end_screen_summary_credits_stop)
                        params.played_sound_2 = true
                    end

                else
                    style.icon.material_values.intensity = ease_progress - 1
                    style.text.text_color = Color.terminal_text_header(ease_progress * 255, true)
                    widget.alpha_multiplier = math.max(math.min(1, ease_progress * 2),0)

                    if (not params.played_sound_1) and ease_progress >= 0.2 then
                        parent:_play_sound(UISoundEvents.talent_node_select_stat)
                        params.played_sound_1 = true
                    end
                    if (not params.played_sound_2) and ease_progress >= 0.7 then
                        parent:_play_sound(UISoundEvents.talent_node_line_connection_stop)
                        params.played_sound_2 = true
                    end
                end
			end,
		},
	},
    on_archetype_reset = {
		{
			end_time = reset_end_time,
			name = "init",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(1-progress)

                local widget = params.widget
                local style = widget.style

                --style.icon.color = {ease_progress * 255, 255, 255}
                style.text.text_color = Color.white(ease_progress * 255, true)
			end,
		},
	},
    on_archetype_roll = {
		{
			end_time = 1,
			name = "move",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(progress)

                local widget = params.widget
                local style = widget.style

                --style.icon.color = {ease_progress * 255, 255, 255}
                style.text.text_color = Color.white(ease_progress * 255, true)
			end,
		},
	},
    on_archetype_bg_reset = {
		{
			end_time = reset_end_time,
			name = "init",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(1-progress)

                local widget = params.widget
                local style = widget.style

                style.image.color = {ease_progress * 64, 255, 255, 255}
			end,
		},
	},
    on_archetype_bg_roll = {
		{
			end_time = 1,
			name = "move",
			start_time = 0,
            init = function (parent, ui_scenegraph, scenegraph_definition, widgets, params)

                local widget = params.widget
                local style = widget.style
                params.color = {}
                params.color[1] = style.image.color[1]
                params.color[2] = style.image.color[2]
                params.color[3] = style.image.color[3]
                params.color[4] = style.image.color[4]
			end,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(progress)

                local widget = params.widget
                local style = widget.style
                local color = params.color

                style.image.color = {ease_progress * 64, 255, 255, 255}
			end,
		},
	},
    on_world_fade_out = {
		{
			end_time = 1,
			name = "move",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(progress)

                local widget = parent._widgets_by_name.screen_blackout
                local style = widget.style

                style.rect.color = {ease_progress * 255, 0, 0, 0}
			end,
		},
	},
    on_world_fade_in = {
		{
			end_time = 1,
			name = "move",
			start_time = 0,
			update = function (parent, ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local ease_progress = math.easeOutCubic(1-progress)

                local widget = parent._widgets_by_name.screen_blackout
                local style = widget.style

                --local bg_scenegraph = ui_scenegraph.background
                --bg_scenegraph.size[2] = ease_progress * 200

                style.rect.color = {ease_progress * 255, 0, 0, 0}
			end,
		},
	},
}

return {
	scenegraph_definition = scenegraph_definition,
	widget_definitions = widget_definitions,
	legend_inputs = legend_inputs,
    animations = animations,
    node_widget_definitions = node_widget_definitions,
}