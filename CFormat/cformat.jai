#import "Basic";
#import "String";


DEBUG :: false;  // @TODO remove
STRICT :: false;

f :: inline ($format: string, args: .. Any) -> string {
/**
```
    return sprint(jai_format_string, formatInt(args[0]), formatFloat(args[1]));

```
*/
    #insert #run format_string(format);
}


format_string :: (format: string) -> string #expand {
    #if DEBUG {
        debug_builder : String_Builder;
        defer free_buffers(*debug_builder);
    }

    bounds_check :: () #expand {
        #if DEBUG
            assert(`c < `format.count, "Invalid string format: expecting more info but end of format string reached");
    }

    main_builder : String_Builder;
    args_builder : String_Builder;
    defer free_buffers(*main_builder);
    defer free_buffers(*args_builder);

    append(*main_builder, "return sprint(\"");

    c := 0;
    arg_index := 0;
    while c < format.count {
        defer c += 1;

        if format[c] == #char "%" {
            c += 1;
            bounds_check();

            // escaped %
            if format[c] == #char "%" {
                append(*main_builder, "%%");
                continue;
            }

            // parameter
            number, is_number, c := read_int(format, c);
            bounds_check();

            if is_number && format[c] == #char "$" {
                arg_index = number;
                c += 1;
                bounds_check();
                number, is_number, c = read_int(format, c);
                bounds_check();
            }

            // flags
            zero := false;
            if is_number && number == 0 {
                is_number = false;
                zero = true;
            }

            minus := false;
            plus := false;
            space := false;
            apostrophe := false;
            hash := false;

            while true {
                if format[c] == {
                    case #char "-";
                    minus = true;

                    case #char "+";
                    plus = true;

                    case #char " ";
                    space = true;

                    case #char "0";
                    zero = true;

                    case #char "'";
                    apostrophe = true;

                    case #char "#";
                    hash = true;

                    case;
                    break;
                }

                c += 1;
                bounds_check();
            }

            // width
            get_from_arg :: -1;
            width : int = ---;
            if is_number {
                width = number;
            }
            else if format[c] == #char "*" {
                width = get_from_arg;
                c += 1;
                bounds_check();
            }
            else {
                width = 0;
            }

            // precision
            trailing_width : int = ---;
            if format[c] == #char "." {
                number, is_number, c = read_int(format, c + 1);
                bounds_check();
                if is_number
                    trailing_width = number;
                else if format[c] == #char "*"
                    trailing_width = get_from_arg;
                else
                    trailing_width = 0;
            }
            else
                trailing_width = 0;


            // length
            size := -1;
            if format[c] == {
                case #char "h";
                c += 1;
                bounds_check();
                if format[c] == #char "h"  c += 1;
                size = 4;

                case #char "l";
                c += 1;
                bounds_check();
                if format[c] == #char "l"  c += 1;
                size = 8;

                case #char "L"; #through;
                case #char "z";
                case #char "j";
                case #char "t"; // Is this 4?
                c += 1;
                bounds_check();
                size = 8;
            }

            // type
            type : *Type_Info = ---;
            if format[c] == {
                case #char "d"; #through;
                case #char "i";
                type = type_info(int);
                if size == -1  size = 8;
                #if DEBUG && STRICT {
                    print_to_builder(*debug_builder, "assert(cast(*Type_Info_Integer)(args[%].type).signed);\n", arg_index);
                }
                print_to_builder(*args_builder, ", formatInt(args[%]", arg_index);

                if !zero  append(*args_builder, ", pad_char=#char \" \"");
                if minus append()
            plus := false;
            space := false;
            apostrophe := false;
            hash := false;

                case #char "u";
                type = type_info(int);
                if size == -1  size = 8;
                #if DEBUG && STRICT {
                    print_to_builder(*debug_builder, "assert(!cast(*Type_Info_Integer)(args[%].type).signed);\n", arg_index);
                }

                case #char "f";
                type = type_info(float);

                case #char "s";

                case;
                assert(false, "Illegal format string: expected type at character %", c);
            }

            append(*main_builder, "%");
            #if DEBUG {
                print_to_builder(*debug_builder, "assert(args[%].type.type == .%);\n", arg_index, type.type);
                #if STRICT {
                    print_to_builder(*debug_builder, "assert(args[%].type.runtime_size >= .%);\n", arg_index, type.type);
                }
            }

            arg_index += 1;
        }
        else {
            append(*main_builder, format[c]);
        }
    }

    append(*main_builder, "\"");
    append(*main_builder, builder_to_string(*args_builder));
    append(*main_builder, ");");

    #if DEBUG {
        append(*debug_builder, builder_to_string(*main_builder));
        return builder_to_string(*debug_builder);
    }
    else
        return builder_to_string(*main_builder);
}


echo :: (args: .. Any, separator := " ", endl := true) {
    if args.count > 0       print("%",  args[0]);
    for i: 1..args.count-1  print("%1%2", separator, args[i]);
    if endl  print("\n");
}


secho :: (args: .. Any, separator := " ", endl := true) -> string {
    builder: String_Builder;
    init_string_builder(*builder);
    defer reset(*builder);

    if args.count > 0       print_to_builder(*builder, "%",  args[0]);
    for i: 1..args.count-1  print_to_builder(*builder, "%1%2", separator, args[i]);
    if endl  print_to_builder(*builder, "\n");

    return builder_to_string(*builder);
}


main :: () {
    echo(f("%d %f", 1, 4.0));

    print("% %", 1, 4.0);
    print("% %", 1, formatFloat(4.0, width=2, trailing_width=4));

    print(f("%d %02.4f", 1, 4.0));

    log("\n%\n", formatInt(4, minimum_digits=4));
}



#scope_file



formatInt :: (value : Any, base := 10, minimum_digits := -1, left_align := false, pad_char := #char "0", prepend_space := false, thousand_grouping := false, alternate_form := false) -> FormatInt {
    result : FormatInt;

    result.value = value;
    result.base = base;
    result.minimum_digits = minimum_digits;

    result.left_align = left_align;
    result.pad_char = pad_char;
    result.prepend_space = prepend_space;
    result.thousand_grouping = thousand_grouping;
    result.alternate_form = alternate_form;

    return result;
}


formatFloat :: (value : Any, width := -1, trailing_width := -1, mode := FormatFloat.Mode.DECIMAL, zero_removal := FormatFloat.Zero_Removal.YES, left_align := false, pad_char := #char "0", prepend_space := false, thousand_grouping := false, alternate_form := false) -> FormatFloat {
    result : FormatFloat;

    result.value = value;
    result.width = width;
    result.trailing_width = trailing_width;
    result.mode = mode;
    result.zero_removal = zero_removal;

    result.left_align = left_align;
    result.pad_char = pad_char;
    result.prepend_space = prepend_space;
    result.thousand_grouping = thousand_grouping;
    result.alternate_form = alternate_form;

    return result;
}


FormatNumber :: struct {
    using formatter : Formatter;

    left_align := false;
    pad_char := #char "0";
    prepend_space := false;
    thousand_grouping := false;
    alternate_form := false;
}


FormatInt :: struct {
    using formatter : FormatNumber;

    base := 10;
    minimum_digits := -1;
}


FormatFloat :: struct {
    using formatter : FormatNumber;

    width := -1;
    trailing_width := -1;

    Zero_Removal :: enum { YES; NO; ONE_ZERO_AFTER_DECIMAL; };

    zero_removal := Zero_Removal.YES;  // This will also remove the decimal if it's the last character.

    Mode :: enum { DECIMAL; SCIENTIFIC; SHORTEST; };
    mode := Mode.DECIMAL;
}


read_int :: inline (str: string, index: int) -> value: int, is_number: bool, cursor: int {
    if !is_numeral(str[index])
        return 0, false, index;

    end := index + 1;
    while end < str.count && is_numeral(str[end])
        end += 1;
    s : string = ---;
    s.data = str.data + index;
    s.count = end - index;
    value, success := parse_int(*s);

    return value, success, end;
}


is_numeral :: inline (c: u8) -> bool {
    return c >= #char "0" && c <= #char "9";
}
