NAME :: "apm";
#placeholder VERSION;

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
        case "get"   ; runner = get_module;
        case "build" ; runner = build_project;
        case "update"; runner = update_module;

        case "help";
            print_usage();
            return;

        case "version";
            log_print(.None, "% version %\n", NAME, VERSION);
            return;

        case;
            // log_print(.None, "Unknown command '%'\n", command);
            print_usage(command);
            exit(1);
            return;
    }

    ok, err := runner(..arguments);
    if !ok {
        log_print(.Fail, err);
        exit(1);
    }

    if err.count print(err);
}

new_project :: (arguments: ..string) -> bool, string {
    if arguments.count <= 0 return false, "A project name was expected!";

    project_name     := arguments[0];
    project_dir_name := ifx arguments.count <= 1 then project_name else arguments[1];

    log_print(.Info, "Creating project: % (%)\n", project_name, project_dir_name);

    if !make_directory_if_it_does_not_exist(project_dir_name) {
        return false, tprint("Unable to create directory '%'", project_dir_name);
    }

    project_dir     := tprint("%1%2%3%2", root_directory, separator, project_dir_name);
    source_path     := tprint("%1source%2", project_dir, separator);
    first_file_path := tprint("%1first.jai", project_dir);
    main_file_path  := tprint("%1main.jai", source_path);

    if file_exists(first_file_path) {
        return false, tprint("A project already exists within '%'", project_dir);
    }

    if !make_directory_if_it_does_not_exist(source_path) {
        return false, tprint("Unable to create directory '%'", source_path);
    }

    write_entire_file(first_file_path, tprint(TEMPLATE_BUILD, project_name));
    write_entire_file(main_file_path, tprint(TEMPLATE_MAIN, project_name));

    return true, "";
}

get_module :: (arguments: ..string) -> bool, string {
    if !valid_project_directory(root_directory) return false, "Not in a valid project directory!";
    if arguments.count <= 0 return false, "Expected module URL!";

    module_uri      := arguments[0];
    module_dir_name := ifx arguments.count <= 1 then "" else arguments[1];
    module_dir      := tprint("%1%2vendor", root_directory, separator);

    if !make_directory_if_it_does_not_exist(module_dir) {
        return false, "Unable to make vendor directory!";
    }

    log_print(.Info, "Fetching module: % %\n", module_uri, ifx module_dir_name.count then tprint("(%)", module_dir_name) else "");

    command: [4]string = ---;
    command[0] = "git";
    command[1] = "clone";
    command[2] = module_uri;
    command[3] = module_dir_name;

    ok, code, stdout, stderr := os_run_command(..command, working_directory = module_dir, capture_and_return_output = true);
    if !ok || code != 0 {
        // module_directory := module_dir_name;
        // if !module_directory.count {
        //     parts := split(module_uri, "/");
        //     module_directory = parts[parts.count - 1];
        // }

        // created_directory := tprint("%1%2%3", module_dir, separator, module_directory);

        // log_print(.Warn, "Deleting excess directory: %\n", created_directory);

        // delete_directory(created_directory);

        return false, tprint("Operation failed with code %!\n%", code, format_output(stderr));
    }

    if stdout.count {
        print(format_output(stdout));
    }

    log_print(.Info, "Fetch successful!\n");

    return true, "";
}

update_module :: (arguments: ..string) -> bool, string {
    if !valid_project_directory(root_directory) return false, "Not in a valid project directory!";
    if arguments.count <= 0 return false, "Expected module name!";

    module: string = ---;
    force := false;

    arg := arguments[0];
    if arg[0] == #char "-" {
        if arg == "-f" {
            force = true;
        }
        else {
            return false, tprint("Unknown option '%'", arg);
        }

        if arguments.count < 2 {
            return false, "Expected module name!";
        }

        module = arguments[1];
    }
    else {
        module = arg;
    }

    module_dir := tprint("vendor/%", module); // @Todo(Judah): Should eventually take a 'module directory name' argument so we don't hardcode 'vendor'
    if !directory_exists(module_dir) {
        return false, tprint("Module directory for '%' doesn't exist!", module);
    }

    full_path := tprint("%/%", get_working_directory(), module_dir);
    if !set_working_directory(full_path) {
        return false, tprint("Unable to move to directory: %", full_path);
    }

    log_print(.Info, "Updating module: % %\n", module, ifx force "(forced)" else "");

    ok     : bool   = ---;
    code   : int    = ---;
    stdout : string = ---;
    stderr : string = ---;

    command: [4]string;
    if force {
        command[0] = "git";
        command[1] = "reset";
        command[2] = "--hard";
        command[3] = "HEAD";

        ok, code, stdout, stderr = os_run_command(..command, working_directory = full_path, capture_and_return_output = true);
        if !ok || code != 0 {
            return false, tprint("Operation failed with code %!\n%", code, format_output(stderr));
        }

        command[3] = "";
    }

    // @Note(Judah): This might not be the best command to do a "safe update." 
    command[0] = "git";
    command[1] = "pull";
    command[2] = "-ff";

    ok, code, stdout, stderr = os_run_command(..command, working_directory = full_path, capture_and_return_output = true);
    if !ok || code != 0 {
        return false, tprint("Operation failed with code %!\n%", code, format_output(stderr));
    }

    if stdout.count print(format_output(stdout));
    return true, "";
}

valid_project_directory :: (directory: string) -> bool {
    return file_exists(tprint("%/first.jai", directory)) ||
           file_exists(tprint("%/module.jai", directory));
}

build_project :: (arguments: ..string) -> bool, string {
    if !valid_project_directory(root_directory) return false, "not in a valid project directory!";

    clean_args := arguments;
    if clean_args.count && clean_args[0] == "--" {
        if clean_args.count == 1 {
            clean_args.count = 0;
        }
        else {
            clean_args.count -= 1;
            clean_args.data  += 1;
        }
    }

    arg_info_string: string;
    if clean_args.count {
        arg_info_string = tprint("with arguments: %", clean_args);
    }

    log_print(.Info, "Building project %\n", arg_info_string);

    args: [..]string;
    array_add(*args, "jai", "first.jai", "--");
    array_add(*args, ..clean_args);

    ok, code, stdout, stderr := os_run_command(..args, working_directory = root_directory, capture_and_return_output = true);
    if !ok || code != 0 {
        error_string := tprint("Build failed with code %!", code);

        if stdout.count error_string = tprint("%\n%", error_string, format_output(stdout));
        if stderr.count error_string = tprint("%\n%", error_string, format_output(stderr));

        return false, error_string;
    }

    return true, format_output(stdout);
}

Log_Level :: enum {
    None;
    Info;
    Warn;
    Fail;
};

log_print :: (level: Log_Level, format: string, args: ..Any) {
    output_string := tprint("[%:", NAME);

    if level == {
        case .Info;
            output_string = join(output_string, "info] ");
        case .Warn;
            output_string = join(output_string, "warning] ");
        case .Fail;
            output_string = join(output_string, "error] ");
        case .None;
            output_string = tprint("[%] ", NAME);
    }

    user_string := tprint(format, ..args);
    print("%+%", output_string, user_string);
}

format_output :: (output: string) -> string {
    #if OS == .WINDOWS {
        no_returns := replace(output, "\r", "");
    }
    else {
        no_returns := output;
    }
    
    parts      := split(no_returns, "\n");
    formatted  := join(..parts, "\n    ", before_first = true);
    return formatted;
}


#if OS == .WINDOWS {
    directory_exists :: (directory: string, allocator := context.allocator) -> bool {
        wide_dir := utf8_to_wide(directory, allocator);
        attributes := GetFileAttributesW(xx wide_dir);
        free(wide_dir, allocator);
        return (attributes != INVALID_FILE_ATTRIBUTES &&
                attributes & FILE_ATTRIBUTE_DIRECTORY);
    }
}
else #if OS == .LINUX {
    directory_exists :: (directory: string, allocator := context.allocator) -> bool {
        dir_name_c := temp_c_string(directory); // @Note(Judah): Should actually be 'to_c_string' but it doesn't take an allocator yet.
        // defer free(dir_name_c, allocator);
        stats: stat_t;
        return stat(dir_name_c, *stats) == 0 && S_ISDIR(stats.st_mode);
    }
}

print_usage :: (invalid_command := "") {
    command_string: string;
    if invalid_command.count {
        command_string = tprint("\nCommand '%' is invalid or unknown!\n", invalid_command);
    }

    print(#string END
%1 version %2
%3
Usage:
    %1 new [name] <directory>      creates a new project
    %1 get [url] <import name>     fetches an external module (via git)
    %1 update [-f] <module name>   updates a module, -f will forcibly apply the update
    %1 build <compiler arguments>  builds the project, passing any arguments given 

    END, NAME, VERSION, command_string);
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
            case "!dev"; DEVELOPER = it[0] != #char "!";

            case "test"; #through;
            case "!test"; RUN_TESTS = it[0] != #char "!";

            case "profile"; #through;
            case "!profile"; RUN_PROFILER = it[0] != #char "!";

            case "fast"; #through;
            case "!fast"; FAST = it[0] != #char "!";
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

    // Platform category defines
    add_build_string(tprint("PLATFORM_MOBILE  :: %%;", OS == .IOS || OS == .ANDROID), workspace);
    add_build_string(tprint("PLATFORM_CONSOLE :: %%;", OS == .PS4 || OS == .PS5 || OS == .XBOX || OS == .NN_SWITCH), workspace);
    add_build_string(tprint("PLATFORM_DESKTOP :: %%;", OS == .WINDOWS || OS == .MACOS || OS == .LINUX), workspace);

    // Configurable flags
    add_build_string(tprint("FAST         :: %%;", FAST), workspace);
    add_build_string(tprint("DEVELOPER    :: %%;", DEVELOPER), workspace);
    add_build_string(tprint("RUN_TESTS    :: %%;", RUN_TESTS), workspace);
    add_build_string(tprint("RUN_PROFILER :: %%;", RUN_PROFILER), workspace);

    add_build_file("source/main.jai", workspace);
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

#if OS == .WINDOWS {
    #import "Windows";
    #import "Windows_Utf8";
}
else #if OS == .LINUX {
    #import "POSIX";
}
