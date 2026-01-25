local mod = get_mod("loadout_randomizer")

local ViewElementProfilePresetsSettings = require("scripts/ui/view_elements/view_element_profile_presets/view_element_profile_presets_settings")
local ProfileUtils = require("scripts/utilities/profile_utils")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")

local LoadoutRandomizerProfileUtils = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_utils")
local Definitions = mod:io_dofile("loadout_randomizer/scripts/view_elements/view_element_profile_presets/view_element_profile_presets_override_defs")

local randomizer_profile_widget

local on_randomize_profile_preset_pressed = function (self, is_active)
    local widget = randomizer_profile_widget
    local content = widget.content
    local hotspot = content.hotspot

    hotspot.is_selected = is_active

    if is_active and content.profile_preset_id ~= self._active_profile_preset_id then
        local profile_preset = LoadoutRandomizerProfileUtils.get_randomizer_profile()

		if not profile_preset then return end

		self._active_profile_preset_id = profile_preset_id

		ProfileUtils.save_active_profile_preset_id(profile_preset.id)
        
        LoadoutRandomizerProfileUtils.save_randomizer_profile(profile_preset)
        Managers.event:trigger("event_on_profile_preset_changed", profile_preset)
    end
end

mod:hook_safe(CLASS.ViewElementProfilePresets, "init", function(self, ...)
    self._rando_missing_content = false
	self._rando_modified_content = false
end)

mod:hook_safe(CLASS.ViewElementProfilePresets, "on_profile_preset_index_change", function(self, index, ignore_activation, on_preset_deleted, ignore_sound)
    if randomizer_profile_widget == nil then return end

	local is_randomizer_profile = index == 256
	on_randomize_profile_preset_pressed(self, is_randomizer_profile)
end)

local create_randomizer_widget = function(self, profile_preset)
    local button_width = 44
	local button_spacing = 6
	local total_width = 0
    local randomizer_definitions = Definitions
    local profile_preset_button = randomizer_definitions.profile_preset_button
    local widget_name = "profile_button_randomized"

    local widget = self:_create_widget(widget_name, profile_preset_button)

	local BetterLoadoutsMod = get_mod("BetterLoadouts")

    local offset = widget.offset

	if BetterLoadoutsMod then
		offset[1] = 0
		offset[2] = 815
	else
    	offset[1] = -(#self._profile_buttons_widgets * button_width + (#self._profile_buttons_widgets - 1) * button_spacing) - 50
	end

    local is_selected = profile_preset.id == ProfileUtils.get_active_profile_preset_id()
    local content = widget.content
    local hotspot = content.hotspot

    if is_selected then
        self._active_profile_preset_id = profile_preset.id
        hotspot.is_selected = is_selected

	    for _, p_widget in pairs(self._profile_buttons_widgets) do
            p_widget.content.hotspot.is_selected = false
        end
    end

    self.on_randomize_profile_preset_pressed = on_randomize_profile_preset_pressed
    hotspot.pressed_callback = callback(self, "on_profile_preset_index_change", 256)

    content.profile_preset_id = profile_preset.id

    table.insert(self._profile_buttons_widgets, widget)

    randomizer_profile_widget = widget
end

mod:hook_safe(CLASS.ViewElementProfilePresets, "_setup_preset_buttons", function(self)
	local randomizer_profile = LoadoutRandomizerProfileUtils.get_randomizer_profile()

	if randomizer_profile then
		create_randomizer_widget(self, randomizer_profile)
		self:_sync_profile_buttons_items_status()
	end
end)

mod:hook_safe(CLASS.ViewElementProfilePresets, "show_profile_preset_missing_items_warning", function(self, is_missing_content, is_modified_content, optional_preset_id)

	local active_profile_preset_id = optional_preset_id or self._active_profile_preset_id

	local randomizer_profile = LoadoutRandomizerProfileUtils.get_randomizer_profile()
	if randomizer_profile and randomizer_profile.is_active then
		local profile_buttons_widgets = self._profile_buttons_widgets

		local widget = randomizer_profile_widget
		local content = widget.content
		local profile_preset_id = content.profile_preset_id

		if profile_preset_id == active_profile_preset_id then
			content.missing_content = is_missing_content
			content.modified_content = is_modified_content
			self._rando_missing_content = is_missing_content
			self._rando_modified_content = is_modified_content
		end
	end
end)

mod:hook_safe(CLASS.ViewElementProfilePresets, "_sync_profile_buttons_items_status", function(self)

	local widget = randomizer_profile_widget

	if widget then
		local content = widget.content
		local profile_preset_id = content.profile_preset_id

		content.missing_content = self._rando_missing_content
		content.modified_content = self._rando_modified_content
	end
end)