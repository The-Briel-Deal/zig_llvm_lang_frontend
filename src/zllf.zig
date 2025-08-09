pub const lexer = @import("lexer.zig");
pub const ast = @import("ast.zig");

comptime {
    _ = @import("lexer.zig");
    _ = @import("ast.zig");
}
