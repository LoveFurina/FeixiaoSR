const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;

const log = std.log.scoped(.scene_service);

pub fn onGetCurSceneInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var scene_info = protocol.SceneInfo.init(allocator);
    //scene_info.JDEFJHMIGII = 1;
    //scene_info.leader_entity_id = 1;
    scene_info.game_mode_type = 2;
    scene_info.plane_id = 20231;
    scene_info.floor_id = 20231001;
    scene_info.entry_id = 2023101;

        { // Character
        var scene_group = protocol.SceneEntityGroupInfo.init(allocator);
        scene_group.state = 1;

        try scene_group.entity_list.append(.{
            //.EntityId = 0,
            //.GroupId = 0,
            //.InstId = 0,
            .Actor = .{
                .base_avatar_id = 1314,
                .avatar_type = .AVATAR_FORMAL_TYPE,
                .uid = 666,
                .map_layer = 2,
            },
            .Motion = .{ .pos = .{ .x = 68806, .y = 69528, .z = -225384 }, .rot = .{} },
        });

        try scene_info.entity_group_list.append(scene_group);
    }

    { // Calyx prop
        var scene_group = protocol.SceneEntityGroupInfo.init(allocator);
        scene_group.state = 1;
        scene_group.group_id = 55;

        var prop = protocol.ScenePropInfo.init(allocator);
		//calyx prop 808 = yellow 801 = red 113 = boss 702 = stagnant shadow
        prop.quest_prop_id = 801;
        prop.prop_state = 1;

        try scene_group.entity_list.append(.{
            .GroupId = 55,
            .InstId = 300001,
            .EntityId = 1337,
            .Prop = prop,
            .Motion = .{ .pos = .{ .x = 68806, .y = 68528, .z = -225384 }, .rot = .{ .x = 0, .y = 133224, .z = 0 } },
        });

        try scene_info.entity_group_list.append(scene_group);
}

    { // NPC
        var scene_group = protocol.SceneEntityGroupInfo.init(allocator);
        scene_group.state = 1;

        var npc = protocol.SceneNpcInfo.init(allocator);
        npc.npc_id = 0;

        try scene_group.entity_list.append(.{
            .Npc = npc,
        });

        try scene_info.entity_group_list.append(scene_group);
    }

    try session.send(CmdID.CmdGetCurSceneInfoScRsp, protocol.GetCurSceneInfoScRsp{
        .scene = scene_info,
        .retcode = 0,
    });
}

pub fn onSceneEntityMove(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.SceneEntityMoveCsReq, allocator);

    for (req.entity_motion_list.items) |entity_motion| {
        if (entity_motion.motion) |motion| {
            log.debug("[POSITION] entity_id: {}, motion: {}", .{ entity_motion.entity_id, motion });
        }
    }

    try session.send(CmdID.CmdSceneEntityMoveScRsp, protocol.SceneEntityMoveScRsp{
        .retcode = 0,
        .entity_motion_list = req.entity_motion_list,
        .download_data = null,
    });
}
