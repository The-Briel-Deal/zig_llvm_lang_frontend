pub const lexer = @import("lexer.zig");
pub const ast = @import("ast.zig");
pub const parser = @import("parser.zig");

comptime {
    _ = @import("lexer.zig");
    _ = @import("ast.zig");
    _ = @import("parser.zig");
}
