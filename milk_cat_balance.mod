return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`milk_cat_balance` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("milk_cat_balance", {
			mod_script       = "scripts/mods/milk_cat_balance/milk_cat_balance",
			mod_data         = "scripts/mods/milk_cat_balance/milk_cat_balance_data",
			mod_localization = "scripts/mods/milk_cat_balance/milk_cat_balance_localization",
		})
	end,
	packages = {
		"resource_packages/milk_cat_balance/milk_cat_balance",
	},
}
