local mod = get_mod("milk_cat_balance")
local mod_api = require("scripts/mods/milk_cat_balance/_api/_mod_api")
local buff_perks = require("scripts/unit_extensions/default_player_unit/buffs/settings/buff_perk_names")

--[[
	Coruscation
]]
Weapons.bw_deus_01_template_1.actions.action_one.default.allowed_chain_actions[1].start_time = 0.5
Weapons.bw_deus_01_template_1.actions.action_one.default.total_time = 0.65
Weapons.bw_deus_01_template_1.actions.action_one.default.shot_count = 15

-- Weapon editor export (TourneyBalance)

-- burning_dot
DamageProfileTemplates.burning_dot.default_target.armor_modifier.attack[1] = 0.6 -- official: 1
DamageProfileTemplates.burning_dot.default_target.armor_modifier.attack[2] = 0.25 -- official: 0.75
DamageProfileTemplates.burning_dot.default_target.armor_modifier.attack[3] = 3.5 -- official: 3
DamageProfileTemplates.burning_dot.default_target.armor_modifier.attack[6] = 0.25 -- official: 0.5
