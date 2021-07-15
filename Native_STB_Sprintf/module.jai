// stb_sprintf rewritten in Jai
// See `tests.jai` for inconsistencies with C version (they're present but very minor)

#module_parameters (
    BUFFER_CHARACTERS_PER_CALLBACK := 512,  // How many characters per callback
    FORCE_ALIGN := false                    // Enabling will pad so that everything is aligned
);


#load "sprintf.jai";
