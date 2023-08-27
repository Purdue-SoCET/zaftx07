const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const riscv = std.Target.riscv;
const Feature = riscv.Feature;
const featureSet = riscv.featureSet;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target: CrossTarget = .{
        .cpu_arch = .riscv32,
        .cpu_features_add = featureSet(&[_]Feature{
            .@"32bit",
            .m,
            .c,
        }),
        .os_tag = .freestanding,
        .os_version_min = .none,
        .os_version_max = .none,
    };

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zaftx07",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.setLinkerScript(.{ .path = "./link.ld" });
    exe.addAssemblyFile(.{ .path = "./AFTx07.S" });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    const bin_path = b.pathJoin(&[_][]const u8{ b.install_prefix, "bin" });
    const bin_file_name = "meminit.bin";
    const bin_file_path = b.pathJoin(&[_][]const u8{ bin_path, bin_file_name });

    const objdump_step = b.addSystemCommand(&[_][]const u8{ "riscv64-unknown-elf-objcopy", "-O", "binary" });
    objdump_step.addArtifactArg(exe);
    objdump_step.addArg(bin_file_path);

    const aft_path = b.env_map.get("AFTX07_ROOT") orelse {
        std.debug.print("Cannot find $AFTX07_ROOT", .{});
        return;
    };
    const vaft_path = b.pathJoin(&[_][]const u8{ aft_path, "aft_out", "sim-verilator", "Vaftx07" });
    const run_cmd = b.addSystemCommand(&[_][]const u8{ vaft_path, bin_file_path });
    run_cmd.cwd = bin_path;

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.step.dependOn(&objdump_step.step);

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
