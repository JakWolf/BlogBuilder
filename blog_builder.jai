main :: () {
    template_file_not_found_error := "Could not find %1 file in template directory. Did you delete it?";

    // HTML vars defined in vars.txt.
    html_vars: , ok: = read_entire_file("in/vars.txt");
    assert(ok, tprint("Could not find %1 file in 'in' directory.", "var.txt"));
    
    html_var_lines := split(html_vars, "\n");
    
    for html_var_lines {
        ok, var, value := split_from_left(it, "=");
        array_add(*html_var_list, .{var, value});
    }
        
    // Template parsing.
    blog_wrapper_start, ok = read_entire_file("in/templates/blog_start.html");
    assert(ok, template_file_not_found_error, "blog_start.html");
    
    blog_wrapper_end: , ok = read_entire_file("in/templates/blog_end.html");
    assert(ok, template_file_not_found_error, "blog_end.html");
    
    header, ok = read_entire_file("in/templates/header.html");
    assert(ok, template_file_not_found_error, "header.html");
        
    head, ok = read_entire_file("in/templates/head.html");
    assert(ok, template_file_not_found_error, "head.html");
    
    footer, ok = read_entire_file("in/templates/footer.html");
    assert(ok, template_file_not_found_error, "footer.html");

    if file_exists("out") then delete_directory("out");
    make_directory_if_it_does_not_exist("out");
    make_directory_if_it_does_not_exist("out/blogs");    

    
    //
    // Blog posts     
    //

    // Read all files in blog posts folder.    
    file_names : [..] string;
    visitor :: (info: *File_Visit_Info, user_data: *[..] string) {
        array_add(user_data, copy_string(info.full_name));
        array_add(user_data, copy_string(info.short_name));
    }
    
    visit_files("in/blog_posts", false, *file_names , visitor, follow_symlinks=false);
    
    blog_post_file_content: [..] string;
    blog_post_file_name:    [..] string;
    
    i := 0;
    while true {
        if file_names.count <= 0 break;
        s, ok := read_entire_file(file_names[i]);
        assert(ok);
        array_add(*blog_post_file_content, s);
        array_add(*blog_post_file_name, file_names[i+1]);
        i += 2;
        if i > file_names.count-1 break;
    }

    // Parse content and variables.    
    for blog_post_file_content {
        begins_with_comment := begins_with(it, "<!--");
        assert(begins_with_comment, tprint("\nThe blog post %1 has to start with a comment so the variables can be parsed.", blog_post_file_name[it_index]));
        
        ok, vars, content := split_from_left(it, "-->");
        vars_lines := split(it, "\n");
        
        blog_post: BlogPost;
        blog_post.file_name = blog_post_file_name[it_index];
        
        found_name: bool;
        found_date: bool;
        for vars_lines {
            if it_index == 0 continue;
            ok, var, value := split_from_left(it, "=");
            
            if var == "%%BLOG_POST_NAME" { blog_post.name = value; found_name = true; }
            if var == "%%BLOG_POST_DATE" { blog_post.date = value; found_date = true; }
        }
        
        assert(found_name, tprint("\nDidn't find the name variable in %1.\nYou have to define it in the first comment of a blog post with \%\%BLOG_POST_NAME=.", blog_post.file_name));
        assert(found_date, tprint("\nDidn't find the date variable in %1.\nYou have to define it in the first comment of a blog post with \%\%BLOG_POST_DATE=.", blog_post.file_name));
        
        array_add(*blog_posts, blog_post);
    }

    // Order blog post from date.    
    blog_posts_ordered: [..] BlogPost;
    for 0..blog_posts.count-1 {
        newest_blog_post_index: s64;
        highest_date_value: s64;
        
        for * blog_posts {
            date_int := split(it.date, "/");
            assert(date_int.count == 3, "\nDate in blog %1 has the wrong format. Please use DD/MM/YYYY.", it.file_name);
            
            date_val := string_to_int(date_int[2]) + string_to_int(date_int[1]) + string_to_int(date_int[0]);
            
            if !it.ordered && date_val >= highest_date_value {
                newest_blog_post_index = it_index;
                highest_date_value = date_val;
            }
            
        }

        newest_blog_post := *blog_posts[newest_blog_post_index];
        newest_blog_post.ordered = true;
        array_add(*blog_posts_ordered, newest_blog_post);
    }
    
    // Generating html sites for blog posts.
    all_blogs_builder: String_Builder;
    init_string_builder(*all_blogs_builder);    
    for blog_posts_ordered {
        file_name_in := tprint("in/blog_posts/%1", it.file_name);
        
        content, _ := read_entire_file(file_name_in);
        
        content = tprint("%1\n%2", blog_wrapper_start, content);
        
        _, file_name_no_ext, _ := split_from_right(it.file_name, ".");
        file_name_out := tprint("out/blogs/%1%2", file_name_no_ext, ".html");
        
        content = replace(content, "%%TITLE", it.name);
        content = replace(content, "%%DATE", it.date);
        
        content = tprint("%1\n%2", content, blog_wrapper_end);
        
        append(*all_blogs_builder, content);
        generate_html(content, file_name_out);
    }
    
    array_add(*html_var_list, .{"%%BLOG_POST_ALL", builder_to_string(*all_blogs_builder)});
    
    // Generate blog list.
    blog_list: String_Builder;
    init_string_builder(*blog_list);
    
    for blog_posts_ordered {
        _, file_name_out, _ := split_from_right(it.file_name, ".");
        file_name_out = tprint("%1%2", file_name_out, ".html");
        
        link := tprint("<p><a href=/blogs/%1>%2</a> <em>%3</em></p>\n", file_name_out, it.name, it.date);
        append(*blog_list, link);
    }
    
    array_add(*html_var_list, .{"%%BLOG_POST_LIST",  builder_to_string(*blog_list)});



    // Copy and generate files in root.    
    array_reset(*file_names);
    visit_files("in/root", false, *file_names , visitor, follow_symlinks=false);
    
    root_file_content: [..] string;
    root_file_name:    [..] string;
    
    i = 0;
    while true {
        s, ok :=  read_entire_file(file_names[i]);
        assert(ok);
        array_add(*root_file_content, s);
        array_add(*root_file_name, file_names[i+1]);
        i += 2;
        if i > file_names.count-1 break;
    }
    
    for root_file_name {
        generate_html(root_file_content[it_index], tprint("out/%1", it));
    }
        
    // Copying other files to out.    
    copy_file("in/style.css", "out/style.css");
    copy_directory("in/resources", "out/resources");
}

replace_vars :: (s: string) -> string {
    mod_s := copy_string(s);
    for html_var_list {
        mod_s = replace(mod_s, it.key, it.value);
    }
    return mod_s;
}

generate_html :: (content: string, file_name: string) {
    if !html_builder.initialized init_string_builder(*html_builder);
    
    append(*html_builder, "<!DOCTYPE html>\n<html>\n\n");
    append(*html_builder, head);
    
    append(*html_builder, "\n\n<body>\n");
    
    header = replace_vars(header);
    append(*html_builder, header);
    
    append(*html_builder, "\n<main>\n");
    
    mod_content := replace_vars(content);
    append(*html_builder, mod_content);
    append(*html_builder, "\n</main>\n\n");
    
    
    footer = replace_vars(footer);
    append(*html_builder, footer);
    append(*html_builder, "\n\n</body>\n</htlml>");
    
    write_entire_file(file_name, builder_to_string(*html_builder));
    reset(*html_builder);
}

html_builder: String_Builder;
head: string;
header: string;
footer: string;
blog_wrapper_start: string;
blog_wrapper_end: string;

blog_posts : [..] BlogPost;
BlogPost :: struct {
    file_name: string;
    name: string;
    date: string;
    ordered: bool;
}

html_var_list: [..] HTMLVar;
HTMLVar :: struct {
    key: string;
    value: string;
}

#import "File_Utilities";
#import "Text_File_Handler";
#import "Basic";
#import "File";
#import "String";