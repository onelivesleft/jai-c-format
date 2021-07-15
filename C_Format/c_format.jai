#import "Basic";
#import "Native_STB_Sprintf"(FORCE_ALIGN = FORCE_ALIGN, BUFFER_CHARACTERS_PER_CALLBACK=BUFFER_CHARACTERS_PER_CALLBACK);


f :: (format: string, args: .. Any) -> string #must {
	builder : String_Builder;
    defer reset(*builder);

	callback :: (buf: *u8, user: *void, len: int) -> *u8 {
		s : string = ---;
		s.data = buf;
		s.count = len;
		if s.count && <<(buf + s.count - 1) == 0
			s.count -= 1;
		append(cast(*String_Builder) user, s);
		return buf;
	}

	cb := callback;
	sprintfcb(*cb, *builder, *buffer[0], format.data, .. args);

    if allocator
        return builder_to_string(*builder, allocator = allocator, allocator_data = allocator_data);
    else if USE_TEMPORARY_STORAGE
	    return builder_to_string(*builder, allocator = __temporary_allocator);
    else
        return builder_to_string(*builder);
}


set_f_allocator :: (new_allocator: Allocator, new_allocator_data: *void = null) {
    allocator = new_allocator;
    allocator_data = new_allocator_data;
}


echo :: (args: .. Any, separator := " ", endl := true) {
    if args.count > 0       print("%",  args[0]);
    for i: 1..args.count-1  print("%1%2", separator, args[i]);
    if endl  print("\n");
}


secho :: (args: .. Any, separator := " ", endl := true, allocator : Allocator = null, allocator_data : *void = null) -> string #must {
    builder : String_Builder;
    defer reset(*builder);

    if args.count > 0       print_to_builder(*builder, "%",  args[0]);
    for i: 1..args.count-1  print_to_builder(*builder, "%1%2", separator, args[i]);
    if endl  print_to_builder(*builder, "\n");

    if allocator
        return builder_to_string(*builder, allocator = allocator, allocator_data = allocator_data);
    else
        return builder_to_string(*builder);
}



#scope_file



allocator : Allocator = null;
allocator_data : *void = null;

buffer : [BUFFER_CHARACTERS_PER_CALLBACK] u8 = ---;
