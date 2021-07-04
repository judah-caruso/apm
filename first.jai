#run {
    build_directory := sprint("%/output/", #filepath);
    make_directory_if_it_does_not_exist(build_directory);

    target := get_build_options();
    target.output_type = .NO_OUTPUT;
    set_build_options(target);

    target.output_type = .EXECUTABLE;
    target.output_path = build_directory;
    target.output_executable_name = "apm";

    workspace := compiler_create_workspace();
    set_build_options(target, workspace);

    version := "0.0.5";
    ok, _, output := os_run_command(...[ "git", "rev-parse", "--short", "HEAD" ], capture_and_return_output = true);
    if ok {
        output.count -= 1;
        version = tprint("% (%)", version, output);
    }

    version_string := tprint("VERSION :: \"%\";", version);
    add_build_string(version_string, workspace);

    add_build_file("source/main.jai", workspace);
}

#import "File";
#import "Basic";
#import "String";
#import "Process";
#import "Compiler";
