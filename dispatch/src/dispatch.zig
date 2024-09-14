const std = @import("std");
const httpz = @import("httpz");
const protocol = @import("protocol");
const Base64Encoder = @import("std").base64.standard.Encoder;

pub fn onQueryDispatch(_: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("onQueryDispatch", .{});

    var proto = protocol.DispatchRegionData.init(res.arena);

    proto.retcode = 0;
    try proto.region_list.append(.{
        .name = .{ .Const = "YunliSR" },
        .display_name = .{ .Const = "YunliSR" },
        .env_type = .{ .Const = "2" },
        .title = .{ .Const = "YunliSR" },
        .dispatch_url = .{ .Const = "http://127.0.0.1:21000/query_gateway" },
    });

    const data = try proto.encode(res.arena);
    const size = Base64Encoder.calcSize(data.len);
    const output = try res.arena.alloc(u8, size);
    _ = Base64Encoder.encode(output, data);

    res.body = output;
}

pub fn onQueryGateway(_: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("onQueryGateway", .{});

    var proto = protocol.Gateserver.init(res.arena);

    proto.retcode = 0;
    proto.port = 23301;
    proto.ip = .{ .Const = "127.0.0.1" };
    proto.AIPNJNLHFBP = .{ .Const = "0" }; // ifix_version
    proto.LLFDDPLHGBM = .{ .Const = "7980531" }; // lua_version
    proto.lua_url = .{ .Const = "https://autopatchcn.bhsr.com/lua/BetaLive/output_8023974_8a20ac590d04" };
    proto.asset_bundle_url = .{ .Const = "https://autopatchcn.bhsr.com/asb/BetaLive/output_8023914_1c5d3bc509a7" };
    proto.ex_resource_url = .{ .Const = "https://autopatchcn.bhsr.com/design_data/BetaLive/output_8023914_b27d1db5c7a4" };
    
    proto.IALOEKGOJOC = true;
    proto.CCHNJJFKGPM = true;
    proto.DNNFDDBEFOI = true;
    proto.HBCEBKFAGIA = true;
    proto.BOKGICKLEGO = true;
    proto.FIOHEKDJNCG = true;
    proto.MCEIPIBAMDB = true;
    proto.CNAKLGMDLPE = true;
    //proto.Unknown = true;
    //proto.Unknown = true;
    proto.NNGLEBKCMLA = true;
    proto.APJECJMGAKC = true;
    proto.NPHDIMJOKNI = true;
    proto.JGCIILJEHHE = true;
    proto.LAABLMNKLLD = true;
    proto.OFJAKNEDMDM = true;
    proto.EBKBNEKCOHI = true;


    const data = try proto.encode(res.arena);
    const size = Base64Encoder.calcSize(data.len);
    const output = try res.arena.alloc(u8, size);
    _ = Base64Encoder.encode(output, data);

    res.body = output;
}
