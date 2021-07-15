#import "Basic";
math :: #import "Math";

// @Note Output of this file did not produce exact matching results when tested using `test.jai`,
//       so is not currenty used.  Instead, hex values generated from C code are used in `sprintf.jai`,
//       as they do produce the extpected test results.  These are:
/*
stbsp__bot       :: float64.[0h3ff0000000000000, 0h4024000000000000, 0h4059000000000000, 0h408f400000000000, 0h40c3880000000000, 0h40f86a0000000000, 0h412e848000000000, 0h416312d000000000, 0h4197d78400000000, 0h41cdcd6500000000, 0h4202a05f20000000, 0h42374876e8000000, 0h426d1a94a2000000, 0h42a2309ce5400000, 0h42d6bcc41e900000, 0h430c6bf526340000, 0h4341c37937e08000, 0h4376345785d8a000, 0h43abc16d674ec800, 0h43e158e460913d00, 0h4415af1d78b58c40, 0h444b1ae4d6e2ef50, 0h4480f0cf064dd592];
stbsp__negbot    :: float64.[0h3fb999999999999a, 0h3f847ae147ae147b, 0h3f50624dd2f1a9fc, 0h3f1a36e2eb1c432d, 0h3ee4f8b588e368f1, 0h3eb0c6f7a0b5ed8d, 0h3e7ad7f29abcaf48, 0h3e45798ee2308c3a, 0h3e112e0be826d695, 0h3ddb7cdfd9d7bdbb, 0h3da5fd7fe1796495, 0h3d719799812dea11, 0h3d3c25c268497682, 0h3d06849b86a12b9b, 0h3cd203af9ee75616, 0h3c9cd2b297d889bc, 0h3c670ef54646d497, 0h3c32725dd1d243ac, 0h3bfd83c94fb6d2ac, 0h3bc79ca10c924223, 0h3b92e3b40a0e9b4f, 0h3b5e392010175ee6];
stbsp__negboterr :: float64.[0hbc5999999999999a, 0hbc0eb851eb851eb8, 0hbbd89374bc6a7efa, 0hbbb6a161e4f765fe, 0hbb8ee78183f91e64, 0h3b4b5a63f9a49c2c, 0h3b15e1e99483b023, 0hbad03023df2d4c94, 0hbab34674bfabb83b, 0hba720a5465df8d2c, 0h3a47f7bc7b4d28aa, 0h39f97f27f0f6e886, 0hb9cecd79a5a0df95, 0h394ea70909833de7, 0hb97937831647f5a0, 0h3925b4c2ebe68799, 0hb90db7b2080a3029, 0hb8d7c628066e8cee, 0h388a52b31e9e3d07, 0h38675447a5d8e536, 0h383f769fb7e0b75e, 0hb7fa7566d9cba769];
stbsp__top       :: float64.[0h44b52d02c7e14af6, 0h497c06a5ec5433c6, 0h4e428bc8abe49f64, 0h53088ba3bf284e24, 0h57d03e29f5c2b18c, 0h5c957f48bb41db7c, 0h615c73892ecbfbf4, 0h6622d3d6f88f0b3d, 0h6ae8eb0138858d0a, 0h6fb07d457124123d, 0h7475d2ce55747a18, 0h793ce2137f743382, 0h7e031cfd3999f7b0];
stbsp__negtop    :: float64.[0h3b282db34012b251, 0h366244ce242c5561, 0h319b9b6364f30304, 0h2cd4dbf7b3f71cb7, 0h280f8587e7083e30, 0h2347d12a4670c123, 0h1e81fee341fc585d, 0h19bb31bb5dc320d2, 0h14f48c22ca71a1bd, 0h102f0ce4839198db, 0h0b677603725064a8, 0h06a1ba03f5b21000, 0h01dac9a7b3b7302f];
stbsp__toperr    :: float64.[0h4160000000000000, 0h45ebb542c80deb40, 0hcae83b80b9aab60a, 0hcfa32e22d17a166c, 0hd4523606902e180e, 0hd9296fb782462e87, 0hddf358952c0bd011, 0he2a78c1376a34b6c, 0he7817569fc243adf, 0hec5d9365a897aaa6, 0h7119050c256123a0, 0hf5db1799d76cc7a6, 0hfaa213fe39571a38];
stbsp__negtoperr :: float64.[0h37c13badb829e079, 0hb2ee46a98d3d9f64, 0h2e3227c7218a2b65, 0h2951d96999aa01e9, 0ha4acc2229efc3962, 0h9fecd04a2263407a, 0h9b123b80f187a157, 0h965c4e22914ed912, 0h119bc296cdf42f82, 0h8cc9f9e7f4e16fe1, 0h880aeb0a72a8902a, 0h834e228e12c13408, 0h0000000000fa1259];
*/


/* Desired equivalent output:

stbsp__bot       :: float64.[1e+000,1e+001,1e+002,1e+003,1e+004,1e+005,1e+006,1e+007,1e+008,1e+009,1e+010,1e+011,1e+012,1e+013,1e+014,1e+015,1e+016,1e+017,1e+018,1e+019,1e+020,1e+021,1e+022];
stbsp__negbot    :: float64.[1e-001,1e-002,1e-003,1e-004,1e-005,1e-006,1e-007,1e-008,1e-009,1e-010,1e-011,1e-012,1e-013,1e-014,1e-015,1e-016,1e-017,1e-018,1e-019,1e-020,1e-021,1e-022];
stbsp__negboterr :: float64.[-5.551115123125783e-018,-2.0816681711721684e-019,-2.0816681711721686e-020,-4.7921736023859299e-021,-8.1803053914031305e-022,4.5251888174113741e-023,4.5251888174113739e-024,-2.0922560830128471e-025,-6.2281591457779853e-026,-3.6432197315497743e-027,6.0503030718060191e-028,2.0113352370744385e-029,-3.0373745563400371e-030,1.1806906454401013e-032,-7.7705399876661076e-032,2.0902213275965398e-033,-7.1542424054621921e-034,-7.1542424054621926e-035,2.4754073164739869e-036,5.4846728545790429e-037,9.2462547772103625e-038,-4.8596774326570872e-039];
stbsp__top       :: float64.[1e+023,1e+046,1e+069,1e+092,1e+115,1e+138,1e+161,1e+184,1e+207,1e+230,1e+253,1e+276,1e+299];
stbsp__negtop    :: float64.[1e-023,1e-046,1e-069,1e-092,1e-115,1e-138,1e-161,1e-184,1e-207,1e-230,1e-253,1e-276,1e-299];
stbsp__toperr    :: float64.[8388608,6.8601809640529717e+028,-7.253143638152921e+052,-4.3377296974619174e+075,-1.5559416129466825e+098,-3.2841562489204913e+121,-3.7745893248228135e+144,-1.7356668416969134e+167,-3.8893577551088374e+190,-9.9566444326005119e+213,6.3641293062232429e+236,-5.2069140800249813e+259,-5.2504760255204387e+282];
stbsp__negtoperr :: float64.[3.9565301985100693e-040,-2.299904345391321e-063,3.6506201437945798e-086,1.1875228833981544e-109,-5.0644902316928607e-132,-6.7156837247865426e-155,-2.812077463003139e-178,-5.7778912386589953e-201,7.4997100559334532e-224,-4.6439668915134491e-247,-6.3691100762962136e-270,-9.436808465446358e-293,8.0970921678014997e-317];

*/

stbsp__bot       :: float64.[#run exp(1, +000),#run exp(1, +001),#run exp(1, +002),#run exp(1, +003),#run exp(1, +004),#run exp(1, +005),#run exp(1, +006),#run exp(1, +007),#run exp(1, +008),#run exp(1, +009),#run exp(1, +010),#run exp(1, +011),#run exp(1, +012),#run exp(1, +013),#run exp(1, +014),#run exp(1, +015),#run exp(1, +016),#run exp(1, +017),#run exp(1, +018),#run exp(1, +019),#run exp(1, +020),#run exp(1, +021),#run exp(1, +022)];
stbsp__negbot    :: float64.[#run exp(1, -001),#run exp(1, -002),#run exp(1, -003),#run exp(1, -004),#run exp(1, -005),#run exp(1, -006),#run exp(1, -007),#run exp(1, -008),#run exp(1, -009),#run exp(1, -010),#run exp(1, -011),#run exp(1, -012),#run exp(1, -013),#run exp(1, -014),#run exp(1, -015),#run exp(1, -016),#run exp(1, -017),#run exp(1, -018),#run exp(1, -019),#run exp(1, -020),#run exp(1, -021),#run exp(1, -022)];
stbsp__negboterr :: float64.[#run exp(-5.551115123125783, -018),#run exp(-2.0816681711721684, -019),#run exp(-2.0816681711721686, -020),#run exp(-4.7921736023859299, -021),#run exp(-8.1803053914031305, -022),#run exp(4.5251888174113741, -023),#run exp(4.5251888174113739, -024),#run exp(-2.0922560830128471, -025),#run exp(-6.2281591457779853, -026),#run exp(-3.6432197315497743, -027),#run exp(6.0503030718060191, -028),#run exp(2.0113352370744385, -029),#run exp(-3.0373745563400371, -030),#run exp(1.1806906454401013, -032),#run exp(-7.7705399876661076, -032),#run exp(2.0902213275965398, -033),#run exp(-7.1542424054621921, -034),#run exp(-7.1542424054621926, -035),#run exp(2.4754073164739869, -036),#run exp(5.4846728545790429, -037),#run exp(9.2462547772103625, -038),#run exp(-4.8596774326570872, -039)];
stbsp__top       :: float64.[#run exp(1, +023),#run exp(1, +046),#run exp(1, +069),#run exp(1, +092),#run exp(1, +115),#run exp(1, +138),#run exp(1, +161),#run exp(1, +184),#run exp(1, +207),#run exp(1, +230),#run exp(1, +253),#run exp(1, +276),#run exp(1, +299)];
stbsp__negtop    :: float64.[#run exp(1, -023),#run exp(1, -046),#run exp(1, -069),#run exp(1, -092),#run exp(1, -115),#run exp(1, -138),#run exp(1, -161),#run exp(1, -184),#run exp(1, -207),#run exp(1, -230),#run exp(1, -253),#run exp(1, -276),#run exp(1, -299)];
stbsp__toperr    :: float64.[8388608,#run exp(6.8601809640529717, +028),#run exp(-7.253143638152921, +052),#run exp(-4.3377296974619174, +075),#run exp(-1.5559416129466825, +098),#run exp(-3.2841562489204913, +121),#run exp(-3.7745893248228135, +144),#run exp(-1.7356668416969134, +167),#run exp(-3.8893577551088374, +190),#run exp(-9.9566444326005119, +213),#run exp(6.3641293062232429, +236),#run exp(-5.2069140800249813, +259),#run exp(-5.2504760255204387, +282)];
stbsp__negtoperr :: float64.[#run exp(3.9565301985100693, -040),#run exp(-2.299904345391321, -063),#run exp(3.6506201437945798, -086),#run exp(1.1875228833981544, -109),#run exp(-5.0644902316928607, -132),#run exp(-6.7156837247865426, -155),#run exp(-2.812077463003139, -178),#run exp(-5.7778912386589953, -201),#run exp(7.4997100559334532, -224),#run exp(-4.6439668915134491, -247),#run exp(-6.3691100762962136, -270),#run exp(-9.436808465446358, -293),#run exp(8.0970921678014997, -317)];


exp :: (n: float64, e: float64) -> float64 {
    return n * math.pow(10, e);
}


main :: () {
    builder: String_Builder;

    output(*builder, stbsp__bot,       "stbsp__bot      ");
    output(*builder, stbsp__negbot,    "stbsp__negbot   ");
    output(*builder, stbsp__negboterr, "stbsp__negboterr");
    output(*builder, stbsp__top,       "stbsp__top      ");
    output(*builder, stbsp__negtop,    "stbsp__negtop   ");
    output(*builder, stbsp__toperr,    "stbsp__toperr   ");
    output(*builder, stbsp__negtoperr, "stbsp__negtoperr");

    print(builder_to_string(*builder));
}


output :: (builder: *String_Builder, values: [] float64, label: string) {
    append(builder, label);
    append(builder, " :: float64.[");
    for values {
        if it_index  append(builder, ", ");
        i : u64 = <<cast,no_check(*u64)*it;
        append(builder, "0h");
        print_to_builder(builder, "%", formatInt(i, minimum_digits=16, base=16));
    }
    append(builder, "];\n");
}
