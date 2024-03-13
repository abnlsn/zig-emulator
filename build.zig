const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const cpu = b.createModule(.{
        .root_source_file = .{ .path = "src/cpu/cpu.zig" },
        .target = target,
        .optimize = optimize,
    });

    // const assembler = b.createModule(.{
    //     .root_source_file = .{ .path = "src/assembler/assembler.zig" },
    //     .target = b.host,
    // });

    const assembler = b.addExecutable(.{
        .name = "assembler",
        .root_source_file = .{ .path = "src/assembler/assembler.zig" },
        .target = target,
        .optimize = optimize,
    });

    assembler.root_module.addImport("cpu", cpu);

    const exe = b.addExecutable(.{
        .name = "zig-emulator",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("cpu", cpu);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);
    b.installArtifact(assembler);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);
    const assemble_command = b.addRunArtifact(assembler);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());
    assemble_command.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
        assemble_command.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const assemble_step = b.step("assemble", "Run the assembler");
    assemble_step.dependOn(&assemble_command.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.root_module.addImport("cpu", cpu);

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const assembler_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/assembler/assembler.zig" },
        .target = target,
        .optimize = optimize,
    });

    assembler_tests.root_module.addImport("cpu", cpu);

    const run_assembler_tests = b.addRunArtifact(assembler_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
    test_step.dependOn(&run_assembler_tests.step);

    buildWeb(b, cpu, b.createModule(.{
        .root_source_file = .{.path = "src/assembler/assembler.zig"},
        .target = target,
        .optimize = optimize
    }));
}

fn buildWeb(b: *std.Build, cpu: *std.Build.Module, assembler: *std.Build.Module) void {
    assembler.addImport("cpu", cpu);
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const exe = b.addExecutable(.{
        .name = "emulator",
        .root_source_file = .{ .path = "src/web/zigdom.zig" },
        .target = target,
        // .optimize = .ReleaseSmall
    });

    exe.entry = .disabled;
    exe.rdynamic = true;
    // exe.import_memory = true;

    exe.root_module.addImport("cpu", cpu);
    exe.root_module.addImport("assembler", assembler);

    b.installArtifact(exe);


}