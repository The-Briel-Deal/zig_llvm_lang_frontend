const TokenTag = enum(i8) {
    eof = -1,

    def = -2,
    @"extern" = -3,

    identifier = -4,
    number = -5,
};

pub const Token = union(TokenTag) {
    eof: void,

    def: void,
    @"extern": void,

    identifier: []const u8,
    number: f64,
};
