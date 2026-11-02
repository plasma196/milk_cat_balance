local mod = get_mod("milk_cat_balance")
local mod_api = require("scripts/mods/milk_cat_balance/_api/_mod_api")

--[[
	$BEGIN_TB
		---
		## Necromancer
		### Talents
		**Death Ascendant**
		- Changed buff to ranged weapon damage (from ranged power).

		**Reaping**
		- Removed power bonus (from 25%).

		**Cursed Blood**
		- Reduced explosion damage to 10% (from 25%) of the crit attack triggering the explosion.
		- Added internal cooldown of 0.3s.
		- Removed stagger from the blood explosion (from 0.08) and crit burst from (0.7).

		**Lost Souls**
		- Removed stagger from unleashed souls (from 0.25).
	$END_TB
]]
--[[

	Passives

]]


--[[

	Talents

]]
--[[
	Vanhel's Danse Macabre
]]
local DANSE_MACABRE_BUFF = "sienna_necromancer_2_1_attack_speed"
local DANSE_MACABRE_MAX_STACKS = 3

mod_api.update_talent_buff_template("bright_wizard", DANSE_MACABRE_BUFF, {
	max_stacks = DANSE_MACABRE_MAX_STACKS, -- 1
	multiplier = 0.05, -- 0.12
})
-- A stack for each raised skeleton, on the field or desummoned (both are in the controlled units count). Checked on
-- a timer, since desummoning and resummoning change the count without the controlled unit events the talent used
mod_api.insert_buff_function("tb_danse_macabre_update", function (unit, buff, params)
	local commander_extension = ScriptUnit.has_extension(unit, "ai_commander_system")
	local buff_extension = ScriptUnit.has_extension(unit, "buff_system")

	if not commander_extension or not buff_extension then
		return
	end

	local wanted_stacks = math.min(commander_extension:get_controlled_units_count(), DANSE_MACABRE_MAX_STACKS)
	local stacks = buff_extension:get_stacking_buff(DANSE_MACABRE_BUFF)
	local current_stacks = stacks and #stacks or 0

	for _ = current_stacks + 1, wanted_stacks do
		buff_extension:add_buff(DANSE_MACABRE_BUFF)
	end

	for i = current_stacks, wanted_stacks + 1, -1 do
		buff_extension:remove_buff(stacks[i].id)
	end
end)
mod_api.insert_talent_buff_template("bright_wizard", "sienna_necromancer_2_1", {
	update_frequency = 0.25,
	update_func = "tb_danse_macabre_update",
})
mod_api.update_talent("bw_necromancer", 2, 1, {
	buffs = {
		"sienna_necromancer_2_1",
	},
	description = "sienna_necromancer_2_1_desc",
	description_values = {},
})
mod_api.insert_text("sienna_necromancer_2_1_desc", "For each raised skeleton increases attack speed by 5%. Max 3 stacks.")

--[[
	Death Ascendant
]]
mod_api.update_talent_buff_template("bright_wizard", "sienna_necromancer_2_2_buff", {
    stat_buff = "increased_weapon_damage_ranged" -- "power_level_ranged"
})
mod_api.update_talent_buff_template("bright_wizard", "sienna_necromancer_2_2", {
	event = "on_ranged_hit" -- "on_spell_used"
})
mod_api.update_talent("bw_necromancer", 2, 2, {
    description = "sienna_necromancer_2_2_desc",
    description_values = {},
})
mod_api.insert_text("sienna_necromancer_2_2_desc", "Ranged hits grant 5% ranged damage for 6 seconds. Max stacks 5.")

-- The soulstealer's soul rip (ActionDamageTarget) only runs the ranged hit procs on its final damage step, its other
-- damage ticks never do. So each of those ticks grants a stack here, and the final step if the proc did not
mod:hook(ActionDamageTarget, "_apply_damage_step", function (func, self, hit_unit, power_level, step_data, t)
	local owner_unit = self.owner_unit
	local talent_extension = ScriptUnit.has_extension(owner_unit, "talent_system")

	if not talent_extension or not talent_extension:has_talent("sienna_necromancer_2_2") or not HEALTH_ALIVE[hit_unit] or not Managers.state.side:is_enemy(owner_unit, hit_unit) then
		return func(self, hit_unit, power_level, step_data, t)
	end

	local buff_extension = self.owner_buff_extension
	local stacks_before = buff_extension:num_buff_type("sienna_necromancer_2_2_buff")

	func(self, hit_unit, power_level, step_data, t)

	if not step_data.proc_buffs or buff_extension:num_buff_type("sienna_necromancer_2_2_buff") == stacks_before then
		buff_extension:add_buff("sienna_necromancer_2_2_buff")
	end
end)

--[[
	Reaping
]]
mod_api.update_talent_buff_template("bright_wizard", "sienna_necromancer_2_3", {
	multiplier = 0 -- 0.25
})
mod_api.insert_text("sienna_necromancer_2_3_desc", "Melee critical attacks have unlimited cleave.")

--[[
	Cursed Blood
]]
-- Direct hit stagger
DamageProfileTemplates.sienna_necromancer_blood_explosion.default_target.power_distribution.impact = 0 -- 0.08
-- Crit burst stagger
DamageProfileTemplates.necromancer_crit_burst_stagger.default_target.power_distribution.impact = 0 -- 0.7
-- Prevent chain bursts
mod_api.insert_proc_function("necromancer_crit_burst", function (owner_unit, buff, params, world, param_order)
	local is_crit = params [param_order.is_critical_strike]
	if not is_crit then
		return
	end

	local is_first_hit = params [param_order.first_hit]
	if not is_first_hit then
		return
	end

	-- Check explosion
	local buff_extension = ScriptUnit.extension(owner_unit, "buff_system")
	local exploded_already = false
	if buff_extension then
		exploded_already = buff_extension:has_buff_type("tb_bw_necromancer_cursed_blood_icd")
	end
	if exploded_already then
		return
	end

	local hit_unit = params [param_order.attacked_unit]
	local is_burning, applied_this_frame = Managers.state.status_effect:has_status(hit_unit, StatusEffectNames.burning_balefire)
	if not is_burning or applied_this_frame then
		return
	end

	local damage_dealt = params [param_order.damage_amount]
	if damage_dealt <= 0 then
		return
	end

	local template = buff.template
	local side = Managers.state.side.side_by_unit [owner_unit]
	local hit_pos = POSITION_LOOKUP [hit_unit]
	if not hit_pos then

		return
	end

	local unit_storage = Managers.state.unit_storage
	local hit_go_id = unit_storage:go_id(hit_unit)
	local node_id = 0
	if Unit.has_node(hit_unit, "j_spine") then
		node_id = Unit.node(hit_unit, "j_spine")
	end

	local network_manager = Managers.state.network
	network_manager.network_transmit:send_rpc_server("rpc_play_particle_effect", NetworkLookup.effects ["fx/necromancer_cursed_explosion_blood"], hit_go_id, node_id, Vector3.zero(), Quaternion.identity(), false)
	network_manager.network_transmit:send_rpc_server("rpc_play_particle_effect", NetworkLookup.effects ["fx/necromancer_cursed_explosion_blue"], hit_go_id, node_id, Vector3(0.5, 0, 0), Quaternion.identity(), false)

	local audio_system = Managers.state.entity:system("audio_system")
	audio_system:play_audio_unit_event("Play_career_necro_ability_cursed_blood", hit_unit, "j_spine")

	local broadphase_categories = side.enemy_broadphase_categories
	local nearby_units = FrameTable.alloc_table()
	local num_nearby = AiUtils.broadphase_query(hit_pos, template.radius, nearby_units, broadphase_categories)

	if num_nearby == 0 then
		return
	end

	local t = Managers.time:time("game")
	local propagated_damage = damage_dealt * template.propagation_multiplier
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	local power_level = career_extension:get_career_power_level()
	for i = 1, num_nearby do
		local target_unit = nearby_units [i]
		if target_unit ~= hit_unit then
			local damage_direction = Vector3.normalize(POSITION_LOOKUP [target_unit] - hit_pos)
			DamageUtils.add_damage_network(target_unit, owner_unit, propagated_damage, "torso", "buff", nil, damage_direction, "buff", nil, owner_unit, nil, nil, false, nil, nil, nil, nil, true, i)
			DamageUtils.stagger_ai(t, DamageProfileTemplates.necromancer_crit_burst_stagger, i + 1, power_level, target_unit, owner_unit, "torso", damage_direction, nil, nil, false, "buff", owner_unit)
		end
	end

	local buff_system = Managers.state.entity:system("buff_system")
	local buff_to_add = "tb_bw_necromancer_cursed_blood_icd"
	buff_system:add_buff(owner_unit, buff_to_add, owner_unit, false)
end)
-- Added Internal cooldown to prevent chain procs
mod_api.insert_talent_buff_template("bright_wizard", "tb_bw_necromancer_cursed_blood_icd", {
	duration = 0.3
})
-- Cursed blood explosion damage
mod_api.update_talent_buff_template("bright_wizard", "sienna_necromancer_4_1_cursed_blood", {
	propagation_multiplier = 0.10 -- 0.25 
})
mod_api.insert_text("sienna_necromancer_4_1_desc", "Critical attacks against enemies afflicted by the Malediction of Nagash cause them to burst, damaging nearby enemies for 10% of the attack. Cannot trigger more than once every 0.3 seconds.")

--[[
	Lost Souls
]]
-- Remove lost soul stagger
DamageProfileTemplates.trapped_soul.default_target.power_distribution_near.impact = 0 -- 0.25
DamageProfileTemplates.trapped_soul.default_target.power_distribution_far.impact = 0 -- 0.25


