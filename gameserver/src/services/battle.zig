const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Config = @import("config.zig");

pub fn onStartCocoonStage(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.StartCocoonStageCsReq, allocator);

    const config = try Config.configLoader(allocator, "config.json");
    
    const BattleBuff = protocol.BattleBuff;

    var battle = protocol.SceneBattleInfo.init(allocator);

    // avatar handler
    for (config.avatar_config.items, 0..) |avatarConf, idx| {
        var avatar = protocol.BattleAvatar.init(allocator);
        avatar.id = avatarConf.id;
        avatar.hp = avatarConf.hp * 100;
        avatar.sp_bar = .{ .cur_sp = avatarConf.sp * 100, .max_sp = 10000 };
        avatar.level = avatarConf.level;
        avatar.rank = avatarConf.rank;
        avatar.promotion = avatarConf.promotion;
        avatar.avatar_type = .AVATAR_FORMAL_TYPE;
        // relics
        for (avatarConf.relics.items) |relic| {
            const r = try relicCoder(allocator, relic.id, relic.level, relic.main_affix_id, relic.stat1, relic.cnt1, relic.stat2, relic.cnt2, relic.stat3, relic.cnt3, relic.stat4, relic.cnt4);
            try avatar.relic_list.append(r);
        }
        // lc
        const lc = protocol.BattleEquipment{
            .id = avatarConf.lightcone.id,
            .rank = avatarConf.lightcone.rank,
            .level = avatarConf.lightcone.level,
            .promotion = avatarConf.lightcone.promotion,
        };
        try avatar.equipment_list.append(lc);
        // max trace
        const skills = [_]u32{ 1, 2, 3, 4, 7, 101, 102, 103, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210 };
        var talentLevel: u32 = 0;
        for (skills) |elem| {
            if (elem == 1) {
                talentLevel = 6;
            } else if (elem <= 4) {
                talentLevel = 10;
            } else {
                talentLevel = 1;
            }
            const talent = protocol.AvatarSkillTree{ .point_id = avatar.id * 1000 + elem, .level = talentLevel };
            try avatar.skilltree_list.append(talent);
        }
        
		// enable technique
		if (avatarConf.use_technique) {
			std.debug.print("{} is using tech\n", .{avatar.id});
			var targetIndexList = ArrayList(u32).init(allocator);
			try targetIndexList.append(0);
			
			const buffs_unlocked = &[_]u32{100101, 100201, 100301, 100401, 100501, 100601, 100801, 100901, 101301, 110101, 110201, 110202, 110203, 110301, 110401, 110501, 110601, 110701, 110801, 110901, 111001, 111101, 111201, 120101, 120301, 120401, 120501, 120601, 120701, 120702, 120801, 120802, 120901, 121001, 121101, 121201, 121202, 121203, 121301, 121302, 121303, 121401, 121501, 121701, 121801, 122001, 122002, 122003, 122004, 122101, 122201, 122301, 122302, 122303, 122304, 122401, 122402, 122403, 130101, 130201, 130301, 130302, 130303, 130401, 130402, 130403, 130404, 130405, 130406, 130501, 130601, 130602, 130701, 130801, 130802, 130803, 130901, 130902, 130903, 131001, 131002, 131201, 131401, 131501, 131502, 131503, 131701, 131702, 800301, 800501};
			
			var buffedAvatarId = avatar.id;
			if (avatar.id == 8004) {
				buffedAvatarId = 8003;
			} else if (avatar.id == 8006) {
				buffedAvatarId = 8005;
			}
			
			for (buffs_unlocked) |buffId| {
            const idPrefix = buffId / 100;
				if (idPrefix == buffedAvatarId) {
					std.debug.print("loading buffID {} for {}\n", .{buffId, buffedAvatarId});
					var buff = BattleBuff{
						.id = buffId,
						.level = 1,
						.owner_id = @intCast(idx),
						.wave_flag = 1,
						.target_index_list = targetIndexList,
						.dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
					};

					try buff.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
					try battle.buff_list.append(buff);
				}
			}

			if (buffedAvatarId == 1006 or buffedAvatarId == 1308 or buffedAvatarId == 1317) {
				var buff_tough = BattleBuff{
					.id = 1000119, //for is_ignore toughness
					.level = 1,
					.owner_id = @intCast(idx),
					.wave_flag = 1,
					.target_index_list = targetIndexList,
					.dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
				};
				try buff_tough.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
				try battle.buff_list.append(buff_tough);
			}
			
			if (buffedAvatarId == 1310) {
				var buff_firefly = BattleBuff{
					.id = 1000112, //for firefly tech
					.level = 1,
					.owner_id = @intCast(idx),
					.wave_flag = 1,
					.target_index_list = targetIndexList,
					.dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
				};
				try buff_firefly.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
				try battle.buff_list.append(buff_firefly);
			}
		}
        try battle.pve_avatar_list.append(avatar);
    }

    // basic info
    battle.battle_id = config.battle_config.battle_id;
    battle.stage_id = config.battle_config.stage_id;
    battle.logic_random_seed = @intCast(@mod(std.time.timestamp(), 0xFFFFFFFF));
    battle.rounds_limit = config.battle_config.cycle_count; // cycle
    battle.AFHKNCHFNLE = @intCast(config.battle_config.monster_wave.items.len); // monster_wave_length

    // monster handler
    for (config.battle_config.monster_wave.items) |wave| {
        var monster_wave = protocol.SceneMonsterWave.init(allocator);
        monster_wave.wave_param = protocol.SceneMonsterWaveParam{ .level = config.battle_config.monster_level };
        for (wave.items) |mob_id| {
            try monster_wave.monster_list.append(.{ .monster_id = mob_id });
        }
        try battle.monster_wave_list.append(monster_wave);
    }

    // stage blessings
    for (config.battle_config.blessings.items) |blessing| {
        var targetIndexList = ArrayList(u32).init(allocator);
        try targetIndexList.append(0);
        var buff = protocol.BattleBuff{
            .id = blessing,
            .level = 1,
            .owner_id = 0xffffffff,
            .wave_flag = 0xffffffff,
            .target_index_list = targetIndexList,
            .dynamic_values = ArrayList(protocol.BattleBuff.DynamicValuesEntry).init(allocator),
        };
        try buff.dynamic_values.append(.{ .key = .{ .Const = "SkillIndex" }, .value = 0 });
        try battle.buff_list.append(buff);
    }

    // PF/AS scoring
    const BattleTargetInfoEntry = protocol.SceneBattleInfo.BattleTargetInfoEntry;
    battle.battle_target_info = ArrayList(BattleTargetInfoEntry).init(allocator);

    // target hardcode
    var pfTargetHead = protocol.BattleTargetList{ .battle_target_list = ArrayList(protocol.BattleTarget).init(allocator) };
    try pfTargetHead.battle_target_list.append(.{ .id = 10002, .progress = 0, .total_progress = 0 });
    var pfTargetTail = protocol.BattleTargetList{ .battle_target_list = ArrayList(protocol.BattleTarget).init(allocator) };
    try pfTargetTail.battle_target_list.append(.{ .id = 2001, .progress = 0, .total_progress = 0 });
    try pfTargetTail.battle_target_list.append(.{ .id = 2002, .progress = 0, .total_progress = 0 });
    var asTargetHead = protocol.BattleTargetList{ .battle_target_list = ArrayList(protocol.BattleTarget).init(allocator) };
    try asTargetHead.battle_target_list.append(.{ .id = 90005, .progress = 0, .total_progress = 0 });

    switch (battle.stage_id) {
        // PF
        30019000...30019100, 30021000...30021100, 30301000...30309000 => {
            try battle.battle_target_info.append(.{ .key = 1, .value = pfTargetHead });
            // fill blank target
            for (2..5) |i| {
                try battle.battle_target_info.append(.{ .key = @intCast(i) });
            }
            try battle.battle_target_info.append(.{ .key = 5, .value = pfTargetTail });
        },
        // AS
        420100...420200 => {
            try battle.battle_target_info.append(.{ .key = 1, .value = asTargetHead });
        },
        else => {},
    }

    try session.send(CmdID.CmdStartCocoonStageScRsp, protocol.StartCocoonStageScRsp{
        .Retcode = 0,
        .CocoonId = req.cocoon_id,
        .PropEntityId = req.prop_entity_id,
        .Wave = req.wave,
        .BattleInfo = battle,
    });
}

pub fn onPVEBattleResult(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.PVEBattleResultCsReq, allocator);

    var rsp = protocol.PVEBattleResultScRsp.init(allocator);
    rsp.battle_id = req.battle_id;
    rsp.end_status = req.end_status;

    try session.send(CmdID.CmdPVEBattleResultScRsp, rsp);
}

fn relicCoder(allocator: Allocator, id: u32, level: u32, main_affix_id: u32, stat1: u32, cnt1: u32, stat2: u32, cnt2: u32, stat3: u32, cnt3: u32, stat4: u32, cnt4: u32) !protocol.BattleRelic {
    var relic = protocol.BattleRelic{
        .id = id,
        .main_affix_id = main_affix_id,
        .level = level,
        .sub_affix_list = ArrayList(protocol.RelicAffix).init(allocator),
    };
    try relic.sub_affix_list.append(protocol.RelicAffix{ .affix_id = stat1, .cnt = cnt1, .step = 3 });
    try relic.sub_affix_list.append(protocol.RelicAffix{ .affix_id = stat2, .cnt = cnt2, .step = 3 });
    try relic.sub_affix_list.append(protocol.RelicAffix{ .affix_id = stat3, .cnt = cnt3, .step = 3 });
    try relic.sub_affix_list.append(protocol.RelicAffix{ .affix_id = stat4, .cnt = cnt4, .step = 3 });

    return relic;
}
