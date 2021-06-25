NAME    :: "pm";
VERSION :: "0.0.1b";
#placeholder DATE;

root_directory: string = ---;
separator: string = ---;

main :: () {
    raw_args := get_command_line_arguments();
    defer array_free(raw_args);

    args := raw_args;
    args.count -= 1;
    args.data  += 1;

    if args.count <= 0 {
        print_usage();
        return;
    }

    command := args[0];
    arguments := args;
    arguments.count -= 1;
    arguments.data  += 1;

    sep := PATH_SEPARATOR;
    separator.data  = cast(*u8)*sep;
    separator.count = 1;

    root_directory = get_working_directory();

    runner: (args: ..string) -> bool, string;
    if command == {
        case "new"   ; runner = new_project;
        case "get"   ; runner = get_library;
        case "run"   ; runner = run_project;
        case "build" ; runner = build_project;

        case "help";
            print_usage();
            return;

        case;
            print("Unknown command '%'\n", command);
            print_usage();
            exit(1);
            return;
    }

    ok, err := runner(..arguments);
    if !ok {
        print("Error: %\n", err);
        exit(1);
    }

    if err.count print(err);
}

new_project :: (arguments: ..string) -> bool, string {
    if arguments.count <= 0 return false, "a project name was expected!";

    project_name     := arguments[0];
    project_dir_name := ifx arguments.count <= 1 then project_name else arguments[1];

    print("Creating project: % (%)\n", project_name, project_dir_name);
    if !make_directory_if_it_does_not_exist(project_dir_name) {
        return false, tprint("unable to create directory '%'", project_dir_name);
    }

    project_dir     := tprint("%1%2%3%2", root_directory, separator, project_dir_name);
    source_path     := tprint("%1source%2", project_dir, separator);
    first_file_path := tprint("%1first.jai", project_dir);
    main_file_path  := tprint("%1main.jai", source_path);

    if file_exists(first_file_path) {
        return false, tprint("a project already exists within '%'", project_dir);
    }

    if !make_directory_if_it_does_not_exist(source_path) {
        return false, tprint("unable to create directory '%'", source_path);
    }

    write_entire_file(first_file_path, tprint(TEMPLATE_BUILD, project_name));
    write_entire_file(main_file_path, tprint(TEMPLATE_MAIN, project_name));

    return true, "";
}

get_library :: (arguments: ..string) -> bool, string {
    if arguments.count <= 0 return false, "expected library URL!";

    if !file_exists(tprint("%1%2first.jai", root_directory, separator)) {
        return false, tprint("% is not a valid project directory!", root_directory);
    }

    library_uri      := arguments[0];
    library_dir_name := ifx arguments.count <= 1 then "" else arguments[1];
    library_dir      := tprint("%1%2vendor", root_directory, separator);

    if !make_directory_if_it_does_not_exist(library_dir) {
        return false, "unable to make vendor directory!";
    }

    print("Fetching library: % %\n", library_uri, ifx library_dir_name.count then tprint("(%)", library_dir_name) else "");

    command: [4]string = ---;
    command[0] = "git";
    command[1] = "clone";
    command[2] = library_uri;
    command[3] = library_dir_name;

    ok, code, stdout, stderr := os_run_command(..command, working_directory = library_dir, capture_and_return_output = true);
    if !ok || code != 0 {
        return false, tprint("operation failed with code %! Output:\n%", code, stderr);
    }

    if stdout.count print(stdout);
    print("Fetch successful!\n");
    return true, "";
}

valid_project_directory :: (directory: string) -> bool {
    return file_exists(tprint("%/first.jai", directory));
}

build_project :: (arguments: ..string) -> bool, string {
    if !valid_project_directory(root_directory) return false, "not in a valid project directory!";
    print("Building project...\n");

    args: [..]string;
    array_add(*args, "jai", "first.jai", "--");
    array_add(*args, ..arguments);

    ok, code, stdout, stderr := os_run_command(..args, working_directory = root_directory, capture_and_return_output = true);
    if !ok || code != 0 {
        return false, tprint("build failed with code %! Output:\n%", code, stderr);
    }

    return true, stdout;
}

run_project :: (arguments: ..string) -> bool, string {
    if !valid_project_directory(root_directory) return false, "not in a valid project directory!";

    // ok, code, stdout, stderr := os_run_command(..["jai", "first.jai"], working_directory = root_directory, capture_and_return_output = true);
    // if !ok || code != 0 {
    //     return false, tprint("build failed with code %! Output:\n%", code, stderr);
    // }

    // if stdout.count print(stdout);

    // ok, code, stdout, stderr = os_run_command()

    return false, "unable to run project (not implemented)";
}

print_usage :: () {
    print(#string END
%1 version %2 (%3)

Usage:
    %1 new [name] <directory>                   creates a new project
    %1 get [url] <import name>                  fetches an external (git) library
    %1 run <compiler args> -- <program args>    runs the project (builds if necessary)
    %1 build <compiler args>                    builds the project

    END, NAME, VERSION, DATE);
}

TEMPLATE_MAIN :: #string END
main :: () {
    write_string("Hello from %1!\n");
}
END;

TEMPLATE_BUILD :: #string _END
PROJECT_NAME  :: "%1";

FAST         := false;
DEVELOPER    := true;
RUN_TESTS    := false;
RUN_PROFILER := false;

#run {
    args := compiler_get_command_line_arguments();

    for args {
        if it == {
            case "dev"; #through;
            case "!dev";
                DEVELOPER = it[0] != #char "!";

            case "test"; #through;
            case "!test";
                RUN_TESTS = it[0] != #char "!";

            case "profile"; #through;
            case "!profile";
                RUN_PROFILER = it[0] != #char "!";

            case "fast"; #through;
            case "!fast";
                FAST = it[0] != #char "!";
        }
    }

    print(#string END
Flags:
    DEVELOPER    :: %%
    FAST         :: %%
    RUN_TESTS    :: %%
    RUN_PROFILER :: %%

END, DEVELOPER, FAST, RUN_TESTS, RUN_PROFILER);

    build_directory :: "output/";
    make_directory_if_it_does_not_exist(build_directory);

    target := get_build_options();

    import_path: [..]string;
    array_add(*import_path, ..target.import_path);
    array_add(*import_path, tprint("%%1/vendor/", #filepath));

    target.import_path = import_path;
    target.output_type = .NO_OUTPUT;
    set_build_options(target);

    target.output_type = .EXECUTABLE;
    target.output_path = build_directory;
    target.output_executable_name = PROJECT_NAME;

    workspace := compiler_create_workspace();
    set_build_options(target, workspace);

    add_build_file("source/main.jai", workspace);

    // Platform category defines
    add_build_string(tprint("PLATFORM_MOBILE  :: %%;", OS == .IOS || OS == .ANDROID), workspace);
    add_build_string(tprint("PLATFORM_CONSOLE :: %%;", OS == .PS4 || OS == .PS5 || OS == .XBOX || OS == .NN_SWITCH), workspace);
    add_build_string(tprint("PLATFORM_DESKTOP :: %%;", OS == .WINDOWS || OS == .MACOS || OS == .LINUX), workspace);

    // Configurable flags
    add_build_string(tprint("FAST         :: %%;", FAST), workspace);
    add_build_string(tprint("DEVELOPER    :: %%;", DEVELOPER), workspace);
    add_build_string(tprint("RUN_TESTS    :: %%;", RUN_TESTS), workspace);
    add_build_string(tprint("RUN_PROFILER :: %%;", RUN_PROFILER), workspace);
}

#import "File";
#import "Basic";
#import "String";
#import "Compiler";
_END;

#import "File";
#import "Basic";
#import "System";
#import "String";
#import "Process";
#import "File_Utilities";
