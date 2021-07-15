#module_parameters (
    USE_TEMPORARY_STORAGE := true,          // If no allocator is set with `set_f_allocator`, leaving this enabled
                                            // will mean `f` uses temporary storage.  If disabled then the default allocator
                                            // is used instead.

    BUFFER_CHARACTERS_PER_CALLBACK := 512,  // How many characters per callback in `sprintf`.

    FORCE_ALIGN := false                    // Enabling will pad so that everything in `sprintf` is aligned.
);

#load "c_format.jai";


/**
# Exports:

* `f(format: string, args: .. Any) -> string`
    Equivalent of C sprintf

* `set_f_allocator(allocator: Allocator, allocator_data: *void = null)`
    Sets allocator used for string returned by `f`.  If allocator is `null` then either temp storage (if module parameter is set)
    or default allocator is used instead.

* `echo(args: .. Any, separator := " ", endl := true)`
    Convenience print function that doesn't require a format string.

* `secho(args: .. Any, separator := " ", endl := true, allocator : Allocator = null, allocator_data : *void = null) -> string`
    As `echo` but, returns the string instead of printing it.
*/
