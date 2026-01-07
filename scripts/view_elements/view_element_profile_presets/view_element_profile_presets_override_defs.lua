local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local ColorUtilities = require("scripts/utilities/ui/colors")
local ItemUtils = require("scripts/utilities/items")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIFonts = require("scripts/managers/ui/ui_fonts")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local ViewElementTabMenuSettings = require("scripts/ui/view_elements/view_element_tab_menu/view_element_tab_menu_settings")

local profile_preset_button = UIWidget.create_definition({
	{
		pass_type = "rotated_texture",
		value = "content/ui/materials/icons/system/page_arrow",
		value_id = "arrow",
		style = {
			horizontal_alignment = "center",
			vertical_alignment = "center",
			angle = -math.pi / 2,
			offset = {
				0,
				39,
				7,
			},
			color = Color.terminal_corner(nil, true),
			size = {
				24,
				46,
			},
		},
		visibility_function = function (content, style)
			local hotspot = content.hotspot

			return hotspot.is_focused
		end,
	},
	{
		pass_type = "texture",
		style_id = "exclamation_mark",
		value = "content/ui/materials/icons/generic/exclamation_mark",
		value_id = "exclamation_mark",
		style = {
			horizontal_alignment = "center",
			vertical_alignment = "center",
			offset = {
				10,
				10,
				7,
			},
			color = {
				255,
				246,
				69,
				69,
			},
			size = {
				16,
				28,
			},
		},
		visibility_function = function (content, style)
			return content.missing_content
		end,
	},
	{
		pass_type = "texture",
		style_id = "modified_exclamation_mark",
		value = "content/ui/materials/icons/generic/exclamation_mark",
		value_id = "modified_exclamation_mark",
		style = {
			horizontal_alignment = "center",
			vertical_alignment = "center",
			offset = {
				10,
				10,
				7,
			},
			color = {
				255,
				246,
				202,
				69,
			},
			size = {
				16,
				28,
			},
		},
		visibility_function = function (content, style)
			return content.modified_content
		end,
		change_function = function (content, style)
			if content.missing_content then
				style.offset[1] = 0
			else
				style.offset[1] = 10
			end
		end,
	},
	{
		content_id = "hotspot",
		pass_type = "hotspot",
		content = {
			on_hover_sound = UISoundEvents.default_mouse_hover,
		},
	},
	{
		pass_type = "text",
		value_id = "text",
		style_id = "text",
		value = "?",--Localize("loc_item_information_stats_title_modifiers"),
		style = {
			font_type = "machine_medium",
			font_size = 32,
			text_vertical_alignment = "center",
			text_horizontal_alignment = "center",
			material = "content/ui/materials/font_gradients/slug_font_gradient_gold",
			text_color = Color.white(255, true),
			offset = { 0, 5/2, 11 }
		},
	},	
	{
		pass_type = "texture",
		value = "content/ui/materials/frames/presets/idle",
		value_id = "background_idle",
		style = {
			offset = {
				0,
				0,
				0,
			},
		},
		visibility_function = function (content, style)
			local hotspot = content.hotspot

			return not hotspot.is_selected
		end,
	},
	{
		pass_type = "texture",
		value = "content/ui/materials/frames/presets/active",
		value_id = "background_active",
		style = {
			offset = {
				0,
				0,
				1,
			},
		},
		visibility_function = function (content, style)
			local hotspot = content.hotspot

			return hotspot.is_selected
		end,
	},
	{
		pass_type = "texture",
		value = "content/ui/materials/frames/presets/highlight",
		value_id = "highlight",
		style = {
			offset = {
				0,
				0,
				2,
			},
			default_color = Color.terminal_corner(255, true),
			hover_color = Color.terminal_corner_hover(255, true),
		},
		change_function = function (content, style)
			local color = style.color
			local hotspot = content.hotspot
			local is_selected = hotspot.is_selected
			local default_color = style.default_color
			local hover_color = style.hover_color
			local hover_progress = hotspot.anim_hover_progress
			local input_progress = hotspot.anim_input_progress
			local focus_progress = hotspot.anim_focus_progress
			local select_progress = hotspot.anim_select_progress

			color[1] = 255 * math.max(hover_progress, focus_progress)

			local ignore_alpha = true

			ColorUtilities.color_lerp(default_color, hover_color, math.max(focus_progress, select_progress), color, ignore_alpha)
		end,
	},
}, "profile_preset_button_pivot")

return {
	profile_preset_button = profile_preset_button,
}