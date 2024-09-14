const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;
const Config = @import("config.zig");
const ArrayList = std.ArrayList;

pub fn onGetBag(session: *Session, _: *const Packet, allocator: Allocator) !void {
    const config = try Config.configLoader(allocator, "config.json");
    var generator = UidGenerator().init();

    // fake item inventory
    // TODO: make real one
    var rsp = protocol.GetBagScRsp.init(allocator);
    rsp.equipment_list = ArrayList(protocol.Equipment).init(allocator);
    rsp.relic_list = ArrayList(protocol.Relic).init(allocator);

    for (config.avatar_config.items) |avatarConf| {
        // lc
        const lc = protocol.Equipment{
            .unique_id = generator.nextId(),
            .tid = avatarConf.lightcone.id, // id
            .is_protected = true, // lock
            .level = avatarConf.lightcone.level,
            .rank = avatarConf.lightcone.rank,
            .promotion = avatarConf.lightcone.promotion,
            .equip_avatar_id = avatarConf.id, // base avatar id
        };
        try rsp.equipment_list.append(lc);

        // relics
        for (avatarConf.relics.items) |input| {
            var r = protocol.Relic{
                .tid = input.id, // id
                .main_affix_id = input.main_affix_id,
                .unique_id = generator.nextId(),
                .exp = 0,
                .equip_avatar_id = avatarConf.id, // base avatar id
                .is_protected = true, // lock
                .level = input.level,
                .sub_affix_list = ArrayList(protocol.RelicAffix).init(allocator),
            };
            try r.sub_affix_list.append(protocol.RelicAffix{ .affix_id = input.stat1, .cnt = input.cnt1, .step = 3 });
            try r.sub_affix_list.append(protocol.RelicAffix{ .affix_id = input.stat2, .cnt = input.cnt2, .step = 3 });
            try r.sub_affix_list.append(protocol.RelicAffix{ .affix_id = input.stat3, .cnt = input.cnt3, .step = 3 });
            try r.sub_affix_list.append(protocol.RelicAffix{ .affix_id = input.stat4, .cnt = input.cnt4, .step = 3 });

            std.debug.print("adding {}:{}:{}\n", .{ avatarConf.id, input.id, r.unique_id });
            try rsp.relic_list.append(r);
        }
    }

    try session.send(CmdID.CmdGetBagScRsp, rsp);
}

pub fn UidGenerator() type {
    return struct {
        current_id: u32,

        const Self = @This();

        pub fn init() Self {
            return Self{ .current_id = 0 };
        }

        pub fn nextId(self: *Self) u32 {
            self.current_id +%= 1; // Using wrapping addition
            return self.current_id;
        }
    };
}
