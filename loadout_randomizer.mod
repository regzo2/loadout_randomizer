return {
	run = function()
		fassert(rawget(_G, "loadout_randomizer"), "`loadout_randomizer` encountered an error loading the Darktide Mod Framework.")

		new_mod("loadout_randomizer", {
			mod_script       = "loadout_randomizer/scripts/loadout_randomizer_main",
			mod_data         = "loadout_randomizer/scripts/loadout_randomizer_data",
			mod_localization = "loadout_randomizer/scripts/loadout_randomizer_localization",
		})
	end,
	packages = {},
}
