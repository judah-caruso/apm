#run {
    build_directory := sprint("%/output/", #filepath);
    make_directory_if_it_does_not_exist(build_directory);

    target := get_build_options();
    target.output_type = .NO_OUTPUT;
    set_build_options(target);

    target.output_type = .EXECUTABLE;
    target.output_path = build_directory;
    target.output_executable_name = "pm";

    workspace := compiler_create_workspace();
    set_build_options(target, workspace);

    add_build_file("source/main.jai", workspace);
    add_build_string("DATE :: \"today\";", workspace);
}

#import "File";
#import "Basic";
#import "String";
#import "Compiler";
