// @Note Tests from `https://raw.githubusercontent.com/nothings/stb/master/tests/test_sprintf.c`

// @Note current failures:
// * Tests 44 & 45 fail; `0.0 / 0.0` returns `-NaN` in Jai, but `NaN` is expected.
// * Tests 60 & 61 fail; these are non-standard metric things using `$`
//                       Would be much better served rewriting `$` to be the Posix
//                       standard arg-specifier than fix this behaviour...


basic :: #import "Basic";
math :: #import "Math";
#import "Native_STB_Sprintf"(DEBUG = false);

buffer : [512] u8 = ---;


sprint :: (format: string, args: .. Any) -> string {
	builder : basic.String_Builder;

	callback :: (buf: *u8, user: *void, len: int) -> *u8 {
		s : string = ---;
		s.data = buf;
		s.count = len;
		if s.count && <<(buf + s.count - 1) == 0
			s.count -= 1;
		basic.append(cast(*basic.String_Builder) user, s);
		return buf;
	}

	cb := callback;
	sprintfcb(*cb, *builder, *buffer[0], format.data, .. args);

	return basic.builder_to_string(*builder);
}


test_count := 0;
fails := 0;


check :: (reference: string, format: string, args: .. Any, location := #caller_location) {
	result := sprint(format, .. args);

	test_count += 1;

	if result != reference {
		basic.log("\nTest %: FAIL", test_count);
		basic.log("    Expected: [%]", reference);
		basic.log("    Got:      [%]", result);
		basic.log("Line %\n", location.line_number);
		fails += 1;
	}
}


zero := 0.0;
intmax_t :: u64;
ssize_t :: s64;
ptrdiff_t :: u64;


exp :: (n: float64, e: float64) -> float64 {
    return n * math.pow(10, e);
}


main :: () {
	buf : [1024] u8;
	n := 0;
	pow_2_75 : float64 : 37778931862957161709568.0;
	pow_2_85 : float64 : 38685626227668133590597632.0;

	// integers
	check("a b     1",              "%c %s     %d", #char "a", "b", 1);
	check("abc     ",               "%-8.3s", "abcdefgh");
	check("+5",                     "%+2d", 5);
	check("  6",                    "% 3i", 6);
	check("-7  ",                   "%-4d", -7);
	check("+0",                     "%+d", 0);
	check("     00003:     00004",  "%10.5d:%10.5d", 3, 4);
	check("-100006789",             "%d", -100006789);
	check("20 0020",                "%u %04u", cast(u32)20, cast(u32)20);
	check("12 1e 3C",               "%o %x %X", cast(u32)10, cast(u32)30, cast(u32)60);
	check(" 12 1e 3C ",             "%3o %2x %-3X", cast(u32)10, cast(u32)30, cast(u32)60);
	check("012 0x1e 0X3C",          "%#o %#x %#X", cast(u32)10, cast(u32)30, cast(u32)60);
	check("",                       "%.0x", 0);
	check("0",                      "%.0d", 0);  // stb_sprintf gives "0"
	check("33 555",                 "%hi %ld", cast(s16)33, cast(s32)555);
	check("9888777666",             "%llu", cast(u64)9888777666);
	check("-1 2 -3",                "%ji %zi %ti", cast(intmax_t)-1, cast(ssize_t)2, cast(ptrdiff_t)-3);

	// floating-point numbers
	check("-3.000000",                    "%f", -3.0);
	check("-8.8888888800",                "%.10f", -8.88888888);
	check("880.0888888800",               "%.10f", 880.08888888);
	check("4.1",                          "%.1f", 4.1);
	check(" 0",                           "% .0f", 0.1);
	check("0.00",                         "%.2f", 0.0001);
	check("-5.20",                        "%+4.2f", -5.2);
	check("0.0       ",                   "%-10.1f", 0.);
	check("-0.000000",                    "%f", -0.);
	check("0.000001",                     "%f", 0.000000909834);
	check("38685626227668133600000000.0", "%.1f", pow_2_85);
	check("0.000000499999999999999978",   "%.24f", #run exp(5, -7));
	check("0.000000000000000020000000",   "%.24f", #run exp(2, -17));
	check("0.0000000100 100000000",       "%.10f %.0f", #run exp(1, -8), #run exp(1, +8));
	check("100056789.0",                  "%.1f", 100056789.0);
	check(" 1.23 %",                      "%*.*f %%", 5, 2, 1.23);
	check("-3.000000e+00",                "%e", -3.0);
	check("4.1E+00",                      "%.1E", 4.1);
	check("-5.20e+00",                    "%+4.2e", -5.2);
	check("+0.3 -3",                      "%+g %+g", 0.3, -3.0);
	check("4",                            "%.1G", 4.1);
	check("-5.2",                         "%+4.2g", -5.2);
	check("3e-300",                       "%g", #run exp(3, -300));
	check("1",                            "%.0g", 1.2);
	check(" 3.7 3.71",                    "% .3g %.3g", 3.704, 3.706);
	check("2e-315:1e+308",                "%g:%g", #run exp(2, -315), #run exp(1, +308));

	check("Inf Inf NaN",                  "%g %G %f", 1.0 / zero, 1.0 / zero, 0.0 / zero);
	check("N",                            "%.1g", 0.0 / zero);

	// %n
	check("aaa ", "%.3s %n", "aaaaaaaaaaaaa", *n);
	if n != 4 {
		fails += 1;
		basic.log("\nTest %:FAIL\n    N should be 4!\nLine %\n", test_count, #location().line_number);
	}

	// hex floats // @Note jai does hex floats a different away
	/*
	check("0x1.fedcbap+98", "%a", 0x1.fedcbap+98);
	check("0x1.999999999999a0p-4", "%.14a", 0.1);
	check("0x1.0p-1022", "%.1a", 0x1.ffp-1023);
	check("0x1.009117p-1022", "%a", 2.23e-308);
	check("-0x1.AB0P-5", "%.3A", -0x1.abp-5);
	*/

	// %p
	check("0000000000000000", "%p", null);

	// snprintf // @TODO maybe do this, but we don't really care about snprintf
	/*
	assert(SNPRINTF(buf, 100, " %s     %d",  "b", 123) == 10);
	assert(strcmp(buf, " b     123") == 0);
	assert(SNPRINTF(buf, 100, "%f", pow_2_75) == 30);
	assert(strncmp(buf, "37778931862957161709568.000000", 17) == 0);
	n = SNPRINTF(buf, 10, "number %f", 123.456789);
	assert(strcmp(buf, "number 12") == 0);
	assert(n == 17);  // written vs would-be written bytes
	n = SNPRINTF(buf, 0, "7 chars");
	assert(n == 7);
	// stb_sprintf uses internal buffer of 512 chars - test longer string
	assert(SPRINTF(buf, "%d  %600s", 3, "abc") == 603);
	assert(strlen(buf) == 603);
	SNPRINTF(buf, 550, "%d  %600s", 3, "abc");
	assert(strlen(buf) == 549);
	assert(SNPRINTF(buf, 600, "%510s     %c", "a", 'b') == 516);

	// length check
	assert(SNPRINTF(NULL, 0, " %s     %d",  "b", 123) == 10);
	*/

	check("1,200,000",           "%'d", 1200000);
	check("-100,006,789",        "%'d", -100006789);
	check("9,888,777,666",       "%'lld", 9888777666);
	check("200,000,000.000000",  "%'18f", #run exp(2, 8));
	check("100,056,789",         "%'.0f", 100056789.0);
	check("100,056,789.0",       "%'.1f", 100056789.0);
	check("000,001,200,000",     "%'015d", 1200000);

	// things not supported by glibc
	check("null",           "%s", null);
	check("123,4abc:",      "%'x:", 0x1234ABC);
	check("100000000",      "%b", 256);
	check("0b10 0B11",      "%#b %#B", 2, 3);
	check("2 3 4",          "%I64d %I32d %Id", cast(s64)2, 3, cast(s64)4);
	check("1k 2.54 M",      "%$_d %$.2d", 1000, 2536000);
	check("2.42 Mi 2.4 M",  "%$$.2d %$$$d", 2536000, 2536000);

	// different separators
	set_separators(#char " ", #char ",");
	check("12 345,678900", "%'f", 12345.6789);

	if fails {
		basic.log("\nFailed: %", fails);
	}
	else {
		basic.log("All tests passed!");
	}
}
