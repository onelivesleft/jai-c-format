#import "Basic";

// Translated from Jeff Roberts' stb_sprintf.cpp, original header
// reads:


// stb_sprintf - v1.01 - public domain snprintf() implementation
// originally by Jeff Roberts / RAD Game Tools, 2015/10/20
// http://github.com/nothings/stb
//

/*
Single file sprintf replacement.

Originally written by Jeff Roberts at RAD Game Tools - 2015/10/20.
Hereby placed in public domain.

This is a full sprintf replacement that supports everything that
the C runtime sprintfs support, including float/double, 64-bit integers,
hex floats, field parameters (%*.*d stuff), length reads backs, etc.

Why would you need this if sprintf already exists?  Well, first off,
it's *much* faster (see below). It's also much smaller than the CRT
versions code-space-wise. We've also added some simple improvements
that are super handy (commas in thousands, callbacks at buffer full,
for example). Finally, the format strings for MSVC and GCC differ
for 64-bit integers (among other small things), so this lets you use
the same format strings in cross platform code.

It uses the standard single file trick of being both the header file
and the source itself. If you just include it normally, you just get
the header file function definitions. To get the code, you include
it from a C or C++ file and define STB_SPRINTF_IMPLEMENTATION first.

It only uses va_args macros from the C runtime to do it's work. It
does cast doubles to S64s and shifts and divides U64s, which does
drag in CRT code on most platforms.

It compiles to roughly 8K with float support, and 4K without.
As a comparison, when using MSVC static libs, calling sprintf drags
in 16K.

API:
====
int stbsp_sprintf( char * buf, char const * fmt, ... )
int stbsp_snprintf( char * buf, int count, char const * fmt, ... )
  Convert an arg list into a buffer.  stbsp_snprintf always returns
  a zero-terminated string (unlike regular snprintf).

int stbsp_vsprintf( char * buf, char const * fmt, va_list va )
int stbsp_vsnprintf( char * buf, int count, char const * fmt, va_list va )
  Convert a va_list arg list into a buffer.  stbsp_vsnprintf always returns
  a zero-terminated string (unlike regular snprintf).

int stbsp_vsprintfcb( Sprintf_Callback * callback, void * user, char * buf, char const * fmt, va_list va )
    typedef char * Sprintf_Callback( char const * buf, void * user, int len );
  Convert into a buffer, calling back every BUFFER_CHARACTERS_PER_CALLBACK chars.
  Your callback can then copy the chars out, print them or whatever.
  This function is actually the workhorse for everything else.
  The buffer you pass in must hold at least BUFFER_CHARACTERS_PER_CALLBACK characters.
    // you return the next buffer to use or 0 to stop converting

void stbsp_set_separators( char comma, char period )
  Set the comma and period characters to use.

FLOATS/DOUBLES:
===============
This code uses a internal float->ascii conversion method that uses
doubles with error correction (double-doubles, for ~105 bits of
precision).  This conversion is round-trip perfect - that is, an atof
of the values output here will give you the bit-exact double back.

One difference is that our insignificant digits will be different than
with MSVC or GCC (but they don't match each other either).  We also
don't attempt to find the minimum length matching float (pre-MSVC15
doesn't either).

If you don't need float or doubles at all, define STB_SPRINTF_NOFLOAT
and you'll save 4K of code space.

64-BIT INTS:
============
This library also supports 64-bit integers and you can use MSVC style or
GCC style indicators (%I64d or %lld).  It supports the C99 specifiers
for size_t and ptr_diff_t (%jd %zd) as well.

EXTRAS:
=======
Like some GCCs, for integers and floats, you can use a ' (single quote)
specifier and commas will be inserted on the thousands: "%'d" on 12345
would print 12,345.

For integers and floats, you can use a "$" specifier and the number
will be converted to float and then divided to get kilo, mega, giga or
tera and then printed, so "%$d" 1024 is "1.0 k", "%$.2d" 2536000 is
"2.42 m", etc.

In addition to octal and hexadecimal conversions, you can print
integers in binary: "%b" for 256 would print 100.

PERFORMANCE vs MSVC 2008 32-/64-bit (GCC is even slower than MSVC):
===================================================================
"%d" across all 32-bit ints (4.8x/4.0x faster than 32-/64-bit MSVC)
"%24d" across all 32-bit ints (4.5x/4.2x faster)
"%x" across all 32-bit ints (4.5x/3.8x faster)
"%08x" across all 32-bit ints (4.3x/3.8x faster)
"%f" across e-10 to e+10 floats (7.3x/6.0x faster)
"%e" across e-10 to e+10 floats (8.1x/6.0x faster)
"%g" across e-10 to e+10 floats (10.0x/7.1x faster)
"%f" for values near e-300 (7.9x/6.5x faster)
"%f" for values near e+300 (10.0x/9.1x faster)
"%e" for values near e-300 (10.1x/7.0x faster)
"%e" for values near e+300 (9.2x/6.0x faster)
"%.320f" for values near e-300 (12.6x/11.2x faster)
"%a" for random values (8.6x/4.3x faster)
"%I64d" for 64-bits with 32-bit values (4.8x/3.4x faster)
"%I64d" for 64-bits > 32-bit values (4.9x/5.5x faster)
"%s%s%s" for 64 char strings (7.1x/7.3x faster)
"...512 char string..." ( 35.0x/32.5x faster!)
*/



/* @Note Jai-land:
We don't need the duality of handling va_list; we're just gonna use `.. Any`
So, we ditch `vsprintf`, `vsnprintf`, and rename `vsprintfcb` to `sprintfcb`
*/


Sprintf_Callback :: #type(buf: *u8, user: *void, len: int) -> *u8;


set_separators :: (pcomma: u8, pperiod: u8) {
  stbsp__period = pperiod;
  stbsp__comma = pcomma;
}


sprintf :: (buf : *u8, fmt: *u8, va: .. Any) -> int {
    return sprintfcb(null, null, buf, fmt, .. va);
}


snprintf :: (buf: *u8, count: int, fmt: *u8, va: .. Any) -> int {
    c : stbsp__context = ---;
    l : int;

    if count == 0  return 0;

    c.buf = buf;
    c.count = count;

    callback := stbsp__clamp_callback;
    sprintfcb(*callback, *c, callback(null, *c, 0), fmt, va);

    // zero-terminate
    l = cast,no_check(int)(c.buf - buf);
    if l >= count // should never be greater, only equal (or less) than count
        l = count - 1;
    <<(buf + l) = 0;

    return l;
}


sprintfcb :: (callback: *Sprintf_Callback, user: *void, buf: *u8, fmt: *u8, va: .. Any) -> int {
    hex :: "0123456789abcdefxp";
    hexu :: "0123456789ABCDEFXP";
    tlen := 0;
    done := false;

    bf := buf; f := fmt;


    // @TODO should we do type-checking here, perhaps controlled by a module parameter?
    va_index := -1;
    va_arg :: ($type: Type) -> value: type, count: s64, any: Any #expand {
        `va_index += 1;
        if `va_index >= `va.count || `va[`va_index].value_pointer == null {
            value : type;
            any : Any;
            return value, -1, any;
        }

        any := `va[`va_index];

        #if type == float64 {
            if any.type.type == .FLOAT {
                if any.type.runtime_size == 4 {
                    value := << cast(*float32) any.value_pointer;
                    return cast(float64) value, -1, any;
                }
                else {
                    return << cast(*float64) any.value_pointer, -1, any;
                }
            }
        }

        #if type == *u8 {
            if any.type.type == .STRING {
                value := << cast(*string) any.value_pointer;
                return value.data, value.count, any;
            }
        }

        return << cast,no_check(*type) any.value_pointer, -1, any;
    }


    stbsp__flush_cb :: () #expand { //flush if there is even one byte in the buffer
        len := `bf - `buf;
        if len > 0 {
            `tlen += len;
            `bf = (<<callback)(`buf, `user, len);
            `buf = `bf;
        }
    }

    while fmt := true {
        fw,pr,tz : s32;
        fl: u32;

        STBSP__LEFTJUST      ::   1;
        STBSP__LEADINGPLUS   ::   2;
        STBSP__LEADINGSPACE  ::   4;
        STBSP__LEADING_0X    ::   8;
        STBSP__LEADINGZERO   ::  16;
        STBSP__INTMAX        ::  32;
        STBSP__TRIPLET_COMMA ::  64;
        STBSP__NEGATIVE      :: 128;
        STBSP__METRIC_SUFFIX :: 256;
        STBSP__HALFWIDTH     :: 512;

        // macros for the callback buffer stuff
        stbsp__chk_cb_bufL :: (bytes: int) #expand {
            len := `bf - `buf;
            if len + bytes >= BUFFER_CHARACTERS_PER_CALLBACK {
                `tlen += len;
                `bf = (<<callback)(`buf, `user, len);
                `buf = `bf;
                if `bf == null {
                    `done = true;
                    break `fmt;
                }
            }
        }

        stbsp__chk_cb_buf :: (bytes: int) #expand {
            if `callback  stbsp__chk_cb_bufL(bytes);
        }

        stbsp__cb_buf_clamp :: (cl: Code, v: Code) #expand {
            (#insert cl) = (#insert v);
            if `callback {
                lg := BUFFER_CHARACTERS_PER_CALLBACK - cast,no_check(int)(`bf - `buf);
                if (#insert cl) > lg {
                    (#insert cl) = cast,no_check(type_of(#insert cl))lg;
                }
            }
        }

        // fast copy everything up to the next % (or end of string)
        // @Note code duplicated to replace `goto` optimizations.  Could be deduplicated with a macro or w/e.
        while scandd := true {
            while (cast,no_check(u64)f) & 3 {
                if <<f == #char "%"   break scandd;
                if <<f == #char "\0"  break fmt;
                stbsp__chk_cb_buf(1);
                <<bf = <<f;
                bf += 1;
                f += 1;
            }

            while true {
                v := << cast,no_check(*u32) f;
                c := (~v) & 0x80808080;
                if (v - 0x26262626) & c {
                    if <<f == #char "%"   break scandd;
                    if <<f == #char "\0"  break fmt;
                    stbsp__chk_cb_buf(1);
                    <<bf = <<f;
                    bf += 1;
                    f += 1;
                    continue scandd;
                }
                if (v - 0x01010101) & c {
                    if <<f == #char "\0"  break fmt;
                    stbsp__chk_cb_buf(1);
                    <<bf = <<f;
                    bf += 1;
                    f += 1;
                    continue scandd;
                }
                if callback && (BUFFER_CHARACTERS_PER_CALLBACK - cast,no_check(int)(bf-buf)) < 4 {
                    if <<f == #char "%"   break scandd;
                    if <<f == #char "\0"  break fmt;
                    stbsp__chk_cb_buf(1);
                    <<bf = <<f;
                    bf += 1;
                    f += 1;
                    continue scandd;
                }

                <<cast(*u32)bf = v;
                bf += 4;
                f += 4;
            }
        }

        f += 1;

        // ok, we have a percent, read the modifiers first
        fw = 0; pr = -1; fl = 0; tz = 0;

        // flags
        while flags := true {
            if <<f == {
                // if we have left justify
                case #char "-"; fl |= STBSP__LEFTJUST; f += 1;

                // if we have leading plus
                case #char "+"; fl |= STBSP__LEADINGPLUS; f += 1;

                // if we have leading space
                case #char " "; fl |= STBSP__LEADINGSPACE; f += 1;

                // if we have leading 0x
                case #char "#"; fl |= STBSP__LEADING_0X; f += 1;

                // if we have thousand commas
                case #char "'"; fl |= STBSP__TRIPLET_COMMA; f += 1;

                // if we have kilo marker
                case #char "$"; fl |= STBSP__METRIC_SUFFIX; f += 1;

                // if we have leading zero
                case #char "0"; fl |= STBSP__LEADINGZERO; f += 1; break flags;

                case;  break flags;
            }
        }

        // get the field width
        if <<f == #char "*" {
            fw = cast,no_check(s32) va_arg(u32);
            f += 1;
        }
        else {
            while (<<f >= #char "0") && (<<f <= #char "9") {
                fw = fw * 10 + <<f - #char "0";
                f += 1;
            }
        }

        // get the precision
        if <<f == #char "." {
            f += 1;
            if <<f == #char "*" {
                pr = cast,no_check(s32) va_arg(u32);
                f += 1;
            }
            else {
                pr = 0;
                while (<<f >= #char "0") && (<<f <= #char "9") {
                    pr = pr * 10 + <<f - #char "0";
                    f += 1;
                }
            }
        }

        // handle integer size overrides
        if <<f == {
            // are we halfwidth?
            case #char "h";
            fl |= STBSP__HALFWIDTH; f += 1;

            // are we 64-bit (unix style)
            case #char "l";
            f += 1;
            if <<f == #char "l" {
                fl |= STBSP__INTMAX;
                f += 1;
            }

            // are we 64-bit on intmax? (c99)
            case #char "j";
            fl |= STBSP__INTMAX; f += 1;

            // are we 64-bit on size_t or ptrdiff_t? (c99)
            case #char "z"; #through;
            case #char "t";
            // @Note :JAIIS64BIT Jai is always 64-bit, so hardcode this?
            //                   Maybe look at this again later for things like relative pointers.
            //fl |= ifx ((sizeof(*u8)==8) then STBSP__INTMAX else 0;
            fl |= STBSP__INTMAX;
            f += 1;

            // are we 64-bit (msft style)
            case #char "I";
            if (<<(f+1) == #char "6") && (<<(f+2) == #char "4") {
                fl |= STBSP__INTMAX;
                f += 3;
            }
            else if (<<(f + 1) == #char "3") && (<<(f+2) == #char "2") {
                f += 3;
            }
            else {
                // @Note :JAIIS64BIT
                //fl |= ((sizeof(void*)==8)?STBSP__INTMAX:0); ++f; }
                fl |= STBSP__INTMAX;
                f += 1;
            }
        }

        // handle each replacement
        STBSP__NUMSZ :: 512; // big enough for e308 (with commas) or e-307
        num : [STBSP__NUMSZ] u8;
        lead : [8] u8;
        tail : [8] u8;
        s, h : *u8;
        l, n, cs : u32;
        n64 : u64;
        fv : float64;
        dp : s32;
        sn : *u8;

        // @Note each of these `#code` blocks come from labelled sections with
        //       multiple entry points (i.e. `goto`s)  The original C is performant
        //       spaghetti.

        scopy :: #code {
            // get fw=leading/trailing space, pr=leading zeros
            if pr < cast,no_check(s32)l  pr = cast,no_check(s32)l;
            n = cast,no_check(u32)(pr + lead[0] + tail[0] + tz);
            if fw < cast,no_check(s32)n  fw = cast,no_check(s32)n;
            fw -= cast,no_check(s32)n;
            pr -= cast,no_check(s32)l;

            // handle right justify and leading zeros
            if (fl & STBSP__LEFTJUST) == 0 {
                if fl & STBSP__LEADINGZERO { // if leading zeros, everything is in pr
                    pr = ifx fw > pr then fw else pr;
                    fw = 0;
                }
                else {
                    fl &= cast,no_check(u32)(~STBSP__TRIPLET_COMMA); // if no leading zeros, then no commas
                }
            }

            // copy the spaces and/or zeros
            if fw + pr {
                i : s32;
                c : u32;

                // copy leading spaces (or when doing %8.4d stuff)
                if (fl & STBSP__LEFTJUST) == 0 {
                    while fw > 0 {
                        stbsp__cb_buf_clamp(i,fw);
                        fw -= i;
                        while i {
                            if ((cast,no_check(u64)bf) & 3) == 0  break;
                            <<bf = #char " ";
                            bf += 1;
                            i -= 1;
                        }
                        while i >= 4 {
                            <<cast,no_check(*u32)bf = 0x20202020;
                            bf += 4;
                            i -= 4;
                        }
                        while i {
                            <<bf = #char " ";
                            bf += 1;
                            i -= 1;
                        }
                        stbsp__chk_cb_buf(1);
                    }
                }

                // copy leader
                sn = *lead[1];
                while lead[0] {
                    stbsp__cb_buf_clamp(i, lead[0]);
                    lead[0] -= cast,no_check(u8)i;
                    while i {
                        <<bf = <<sn;
                        bf += 1;
                        sn += 1;
                        i -= 1;
                    }
                    stbsp__chk_cb_buf(1);
                }

                // copy leading zeros
                c = cs >> 24;
                cs &= 0xffffff;
                cs = ifx fl & STBSP__TRIPLET_COMMA then cast,no_check(u32)(c - ((cast,no_check(u32)pr + cs) % (c + 1))) else 0;
                while pr > 0 {
                    stbsp__cb_buf_clamp(i, pr);
                    pr -= i;
                    if (fl & STBSP__TRIPLET_COMMA) == 0 {
                        while i {
                            if ((cast,no_check(u64)bf) & 3) == 0  break;
                            <<bf = #char "0";
                            bf += 1;
                            i -= 1;
                        }
                        while i >= 4 {
                            <<cast,no_check(*u32)bf = 0x30303030;
                            bf += 4;
                            i -= 4;
                        }
                    }

                    while i {
                        if (fl & STBSP__TRIPLET_COMMA) && (cs == c) {
                            cs = 0;
                            <<bf = stbsp__comma;
                            bf += 1;
                        }
                        else {
                            cs += 1;
                            <<bf = #char "0";
                            bf += 1;
                        }
                        i -= 1;
                    }
                    stbsp__chk_cb_buf(1);
                }
            }

            // copy leader if there is still one
            sn = *lead[1];
            while lead[0] {
                i : s32;
                stbsp__cb_buf_clamp(i, lead[0]);
                lead[0] -= cast,no_check(u8) i;
                while i {
                    <<bf = <<sn;
                    bf += 1;
                    sn += 1;
                    i -= 1;
                }
                stbsp__chk_cb_buf(1);
            }

            // copy the string
            n = l;
            while n {
                i : s32;
                stbsp__cb_buf_clamp(i, cast,no_check(s32)n);
                n -= cast,no_check(u32)i;
                #if FORCE_ALIGN {
                    while i >= 4 {
                        <<cast,no_check(*u32)bf = <<cast,no_check(*u32)s;
                        bf += 4;
                        s += 4;
                        i -= 4;
                    }
                }

                while i {
                    <<bf = <<s;
                    bf += 1;
                    s += 1;
                    i -= 1;
                }

                stbsp__chk_cb_buf(1);
            }

            // copy trailing zeros
            while tz {
                i : s32;
                stbsp__cb_buf_clamp(i, tz);
                tz -= i;

                while i {
                    if ((cast,no_check(u64)bf) & 3) == 0  break;
                    <<bf = #char "0";
                    bf += 1;
                    i -= 1;
                }

                while i >= 4 {
                    <<cast,no_check(*u32)bf = 0x30303030;
                    bf += 4;
                    i -= 4;
                }

                while i {
                    <<bf = #char "0";
                    bf += 1;
                    i -= 1;
                }

                stbsp__chk_cb_buf(1);
            }

            // copy tail if there is one
            sn = *tail[1];
            while tail[0] {
                i : s32;
                stbsp__cb_buf_clamp(i, tail[0]);
                tail[0] -= cast,no_check(u8) i;
                while i {
                    <<bf = <<sn;
                    bf += 1;
                    sn += 1;
                    i -= 1;
                }
                stbsp__chk_cb_buf(1);
            }

            // handle the left justify
            if fl & STBSP__LEFTJUST && fw > 0 {
                while fw {
                    i : s32;
                    stbsp__cb_buf_clamp(i, fw);
                    fw -= i;
                    while i {
                        if ((cast,no_check(u64)bf) & 3) == 0  break;
                        <<bf = #char " ";
                        bf += 1;
                        i -= 1;
                    }

                    while i >= 4 {
                        <<cast,no_check(*u32)bf = 0x20202020;
                        bf += 4;
                        i -= 4;
                    }

                    while i {
                        <<bf = #char " ";
                        bf += 1;
                        i -= 1;
                    }

                    stbsp__chk_cb_buf(1);
                }
            }
        };

        hexfloat :: #code {
            fv = va_arg(float64);
            if pr == -1  pr = 6; // default is 6
            // read the double into a string
            if stbsp__real_to_parts(cast,no_check(*s64)*n64, *dp, fv)
                fl |= STBSP__NEGATIVE;

            s = cast,no_check(*u8)(*num[0] + 64);

            // sign
            lead[0] = 0;
            if fl & STBSP__NEGATIVE {
                lead[0] = 1;
                lead[1] = #char "-";
            }
            else if fl & STBSP__LEADINGSPACE {
                lead[0] = 1;
                lead[1] = #char " ";
            }
            else if fl & STBSP__LEADINGPLUS {
                lead[0] = 1;
                lead[1] = #char "+";
            };

            if dp == -1023 {
                dp = ifx n64 then cast,no_check(s32)(-1022) else 0;
            }
            else {
                n64 |= ((cast,no_check(u64)1) << 52);
            }

            n64 <<= (64-56);
            if pr < 15
                    n64 += (((cast,no_check(u64)8) << 56) >> (pr * 4));

            // add leading chars
            lead[1 + lead[0]] = #char "0";
            lead[2 + lead[0]] = #char "x";
            lead[0] += 2;
            <<s = <<(h + (n64 >> 60) & 15);
            s += 1;
            n64 <<= 4;
            if pr {
                <<s = stbsp__period;
                s += 1;
            }
            sn = s;

            // print the bits
            n = cast,no_check(u32)pr;
            if n > 13  n = 13;
            if pr > cast,no_check(s32)n  tz = pr - cast,no_check(s32)n;
            pr = 0;
            while n {
                n -= 1;
                <<s = <<(h + (n64 >> 60) & 15);
                s += 1;
                n64 <<= 4;
            }

            // print the expo
            tail[1] = <<(h + 17);
            if dp < 0 {
                tail[2] = #char "-";
                dp =- dp;
            }
            else {
                tail[2] = #char "+";
            }

            n = cast,no_check(u32) ifx dp >= 1000 then 6 else (ifx dp >= 100 then 5 else (ifx dp >= 10 then 4 else 3));
            tail[0] = cast,no_check(u8)n;
            while true {
                tail[n] = cast,no_check(u8)(#char "0" + (dp % 10));
                if n <= 3  break;
                n -= 1;
                dp /= 10;
            }

            dp = cast,no_check(s32)(s - sn);
            l = cast,no_check(u32)(s - (*num[0] + 64));
            s = *num[0] + 64;
            cs = 1 + (3 << 24);
            #insert_internal scopy;
        };

        dosmallfloat :: #code {
            fv = va_arg(float64);
            if pr == -1 // default is 6
                pr=6;
            else if pr == 0
                pr = 1;

            // read the double into a string
            if stbsp__real_to_str(*sn, *l, *num[0], *dp, fv, cast,no_check(u32)(pr - 1) | 0x80000000)
                fl |= STBSP__NEGATIVE;

            // clamp the precision and delete extra zeros after clamp
            n = cast,no_check(u32)pr;
            if l > cast,no_check(u32)pr
                l = cast,no_check(u32)pr;
            while (l > 1) && pr && (<<(sn + l - 1) == #char "0") {
                pr -= 1;
                l -= 1;
            }

            // should we use %e
            if dp <= -4 || dp > cast,no_check(s32)n {
                if pr > cast,no_check(s32)l
                    pr = cast,no_check(s32)(l - 1);
                else if pr
                    pr -= 1; // when using %e, there is one digit before the decimal
                #insert_internal doexpfromg;
            }
            else {
                // this is the insane action to get the pr to match %g sematics for %f
                if dp > 0 {
                    pr = ifx dp < cast,no_check(s32)l then cast,no_check(s32)l - dp else 0;
                }
                else {
                    pr = -dp + ifx pr > cast,no_check(s32)l then cast,no_check(s32)l else pr;
                }
                #insert_internal dofloatfromg;
            }
        };


        doexp :: #code {
            fv = va_arg(float64);
            if pr == -1  pr = 6; // default is 6
            // read the double into a string
            if stbsp__real_to_str(*sn, *l, *num[0], *dp, fv, cast,no_check(u32)pr | 0x80000000 )
                fl |= STBSP__NEGATIVE;
            #insert_internal doexpfromg;
        };


        doexpfromg :: #code {
            tail[0] = 0;
            lead[0] = 0;
            if fl & STBSP__NEGATIVE {
                lead[0] = 1;
                lead[1] = #char "-";
            }
            else if fl & STBSP__LEADINGSPACE {
                lead[0] = 1;
                lead[1] = #char " ";
            }
            else if fl & STBSP__LEADINGPLUS {
                lead[0] = 1;
                lead[1] = #char "+";
            }

            if dp == STBSP__SPECIAL {
                s = cast,no_check(*u8)sn; cs = 0; pr = 0;
                #insert_internal scopy;
            }
            else {
                s = *num[0] + 64;
                // handle leading chars
                <<s = <<sn;
                s += 1;

                if pr {
                    <<s = stbsp__period;
                    s += 1;
                }

                // handle after decimal
                if (l - 1) > cast,no_check(u32)pr
                    l = cast,no_check(u32)pr + 1;
                n = 1;
                while n < l {
                    <<s = <<(sn + n);
                    s += 1;
                    n += 1;
                }

                // trailing zeros
                tz = pr - cast,no_check(s32)(l - 1);
                pr=0;

                // dump expo
                tail[1] = <<(h + 0xe);
                dp -= 1;
                if dp < 0 {
                    tail[2] = #char "-";
                    dp = -dp;
                }
                else {
                    tail[2] = #char "+";
                }
                n = cast,no_check(u32) ifx dp >= 100 then 5 else 4;
                tail[0] = cast,no_check(u8)n;
                while true {
                    tail[n] = cast,no_check(u8)(#char "0" + (dp % 10));
                    if n <= 3  break;
                    n -= 1;
                    dp /= 10;
                }
                cs = 1 + (3 << 24); // how many tens
                #insert_internal flt_lead;
            }
        };


        flt_lead :: #code {
            // get the length that we copied
            l = cast,no_check(u32)(s - (*num[0] + 64));
            s = *num[0] + 64;
            #insert_internal scopy;
        };


        doafloat :: #code {
            // do kilos
            if fl & STBSP__METRIC_SUFFIX {
                while fl < 0x4000000 {
                    if (fv < 1024.0) && (fv > -1024.0) break;
                    fv /= 1024.0;
                    fl += 0x1000000;
                }
            }
            if pr == -1  pr=6; // default is 6

            // read the double into a string
            if stbsp__real_to_str(*sn, *l, *num[0], *dp, fv, cast,no_check(u32)pr)
                fl |= STBSP__NEGATIVE;
            #insert_internal dofloatfromg;
        };


        dofloatfromg :: #code {
            tail[0] = 0;
            // sign
            lead[0] = 0;
            if fl & STBSP__NEGATIVE {
                lead[0] = 1;
                lead[1] = #char "-";
            }
            else if fl & STBSP__LEADINGSPACE {
                lead[0] = 1;
                lead[1] = #char " ";
            }
            else if fl & STBSP__LEADINGPLUS {
                lead[0] = 1;
                lead[1] = #char "+";
            }

            if dp == STBSP__SPECIAL {
                s = cast,no_check(*u8)sn; cs = 0; pr = 0;
                #insert_internal scopy;
            }
            else {
                s = *num[0] + 64;

                // handle the three decimal varieties
                if dp <= 0 {
                    i : s32;
                    // handle 0.000*000xxxx
                    <<s = #char "0";
                    s += 1;
                    if pr {
                        <<s = stbsp__period;
                        s += 1;
                    }
                    n = cast,no_check(u32)(-dp);
                    if cast,no_check(s32)n > pr  n = cast,no_check(u32)pr;
                    i = cast,no_check(s32)n;
                    while i {
                        if ((cast,no_check(u64)s) & 3) == 0  break;
                        <<s = #char "0";
                        s += 1;
                        i -= 1;
                    }

                    while i >= 4 {
                        <<cast,no_check(*u32)s = 0x30303030;
                        s += 4;
                        i -= 4;
                    }

                    while i {
                        <<s = #char "0";
                        s += 1;
                        i -= 1;
                    }

                    if cast,no_check(s32)(l + n) > pr
                        l = cast,no_check(u32)pr - n;

                    i = cast,no_check(s32)l;
                    while i {
                        <<s = <<sn;
                        s += 1;
                        sn += 1;
                        i -= 1;
                    }

                    tz = pr - cast,no_check(s32)(n + l);
                    cs = 1 + (3 << 24); // how many tens did we write (for commas below)
                }
                else {
                    cs = ifx fl & STBSP__TRIPLET_COMMA then (600 - cast,no_check(u32)dp) % 3 else 0;
                    if cast,no_check(u32)dp >= l {
                        // handle xxxx000*000.0
                        n = 0;
                        while true {
                            if fl & STBSP__TRIPLET_COMMA {
                                cs += 1;
                                if cs == 4 {
                                    cs = 0;
                                    <<s = stbsp__comma;
                                    s += 1;
                                }
                                else {
                                    <<s = <<(sn + n);
                                    s += 1;
                                    n += 1;
                                    if n >= l break;
                                }
                            }
                            else {
                                <<s = <<(sn + n);
                                s += 1;
                                n += 1;
                                if n >= l break;
                            }
                        }

                        if n < cast,no_check(u32)dp {
                            n = cast,no_check(u32)dp - n;
                            if (fl & STBSP__TRIPLET_COMMA) == 0 {
                                while n {
                                    if ((cast,no_check(u64)s) & 3) == 0 break;
                                    <<s = #char "0";
                                    s += 1;
                                    n -= 1;
                                }
                                while n >= 4 {
                                    <<cast,no_check(*u32)s = 0x30303030;
                                    s += 4;
                                    n -= 4;
                                }
                            }

                            while n {
                                if fl & STBSP__TRIPLET_COMMA {
                                    cs += 1;
                                    if cs == 4 {
                                        cs = 0;
                                        <<s = stbsp__comma;
                                        s += 1;
                                    }
                                    else {
                                    <<s = #char "0";
                                    s += 1;
                                    n -= 1;
                                    }
                                }
                                else {
                                    <<s = #char "0";
                                    s += 1;
                                    n -= 1;
                                }
                            }
                        }

                        cs = cast,no_check(u32)(s - (*num[0] + 64)) + (3 << 24); // cs is how many tens
                        if pr {
                            <<s = stbsp__period;
                            s += 1;
                            tz = pr;
                        }
                    }
                    else
                    {
                        // handle xxxxx.xxxx000*000
                        n = 0;
                        while true {
                            if (fl & STBSP__TRIPLET_COMMA) {
                                cs += 1;
                                if cs == 4 {
                                    cs = 0;
                                    <<s = stbsp__comma;
                                    s += 1;
                                }
                                else {
                                    <<s = <<(sn + n);
                                    s += 1;
                                    n += 1;
                                    if n >= cast,no_check(u32)dp  break;
                                }
                            }
                            else {
                                <<s = <<(sn + n);
                                s += 1;
                                n += 1;
                                if n >= cast,no_check(u32)dp  break;
                            }
                        }

                        cs = cast,no_check(u32)(s - (*num[0] + 64)) + (3 << 24); // cs is how many tens
                        if pr {
                            <<s = stbsp__period;
                            s += 1;
                        }

                        if (l - cast,no_check(u32)dp) > cast,no_check(u32)pr
                            l = cast,no_check(u32)(pr + dp);

                        while n < l {
                            <<s = <<(sn + n);
                            s += 1;
                            n += 1;
                        }

                        tz = pr - (cast,no_check(s32)l - dp);
                    }
                }

                pr = 0;

                // handle k,m,g,t
                if fl & STBSP__METRIC_SUFFIX {
                    tail[0] = 1;
                    tail[1] = #char " ";
                    {
                        if fl >> 24 {
                            tail[2] = kmgt[fl >> 24];
                            tail[0] = 2;
                        }
                    }
                }

                #insert_internal flt_lead;
            }
        };


        binary :: #code {
            lead[0] = 0;
            if fl & STBSP__LEADING_0X {
                lead[0] = 2;
                lead[1] = #char "0";
                lead[2] = <<(h + 0xb);
            }
            l = (8 << 4) | (1 << 8);
            #insert_internal radixnum;
        };


        radixnum :: #code {
            // get the number
            if fl & STBSP__INTMAX
                n64 = va_arg(u64);
            else
                n64 = va_arg(u32);

            s = *num[0] + STBSP__NUMSZ;
            dp = 0;

            // clear tail, and clear leading if value is zero
            tail[0] = 0;
            if n64 == 0 {
                lead[0] = 0;
                if pr == 0 {
                    l = 0;
                    cs = ((l >> 4) & 15) << 24;
                    #insert_internal scopy;
                    break;
                }
            }

            // convert to string
            while true {
                s -= 1;
                <<s = <<(h + n64 & cast,no_check(u64)((1 << (l >> 8)) - 1));
                n64 >>= l >> 8;

                if !(n64 || (cast,no_check(s32)((*num[0] + STBSP__NUMSZ) - s) < pr))
                    break;

                if fl & STBSP__TRIPLET_COMMA {
                    l += 1;
                    if (l & 15) == ((l >> 4) & 15) {
                        l &= cast,no_check(u32)(~15);
                        s -= 1;
                        <<s = stbsp__comma;
                    }
                }
            }

            // get the tens and the comma pos
            cs = cast,no_check(u32)((*num[0] + STBSP__NUMSZ) - s) + (((l >> 4) & 15) << 24);

            // get the length that we copied
            l = cast,no_check(u32)((*num[0] + STBSP__NUMSZ) - s);

            // copy it
            #insert_internal scopy;
        };


        dohexb :: #code {
            l = (4 << 4) | (4 << 8);
            lead[0] = 0;
            if fl & STBSP__LEADING_0X {
                lead[0] = 2;
                lead[1] = #char "0";
                lead[2] = <<(h + 16);
            }
            #insert_internal radixnum;
        };


        if <<f == {
            case #char "s";
                // get the string
                count : s64;
                s, count = va_arg(*u8);
                if s == null {
                    s = null_label.data;
                    l = null_label.count;
                }
                else {
                    // get the length
                    if count < 0 {
                        sn = s;

                        while true {
                            if ((cast,no_check(u64)sn) & 3) == 0 {
                                n = 0xffffffff;
                                if pr >= 0 {
                                    n = cast,no_check(u32)(sn - s);
                                    if n >= cast,no_check(u32)pr  break;
                                    n = (cast,no_check(u32)pr - n) >> 2;
                                }

                                while n {
                                    v := << cast,no_check(*u32) sn;
                                    if (v - 0x01010101) & (~v) & 0x80808080  break;
                                    sn += 4;
                                    n -= 1;
                                }
                            }
                            if <<sn == 0  break;
                            sn += 1;
                        }

                        l = cast,no_check(u32)(sn - s);
                    }
                    else
                        l = cast,trunc(u32) count;
                }

                // clamp to precision
                if l > cast,no_check(u32)pr
                    l = cast,no_check(u32)pr;
                lead[0] = 0; tail[0] = 0; pr = 0; dp = 0; cs = 0;
                // copy the string in
                #insert_internal scopy;

            case #char "c"; // char
                // get the character
                s = cast,no_check(*u8)(*num[0] + STBSP__NUMSZ - 1);
                <<s = cast,no_check(u8) va_arg(int);
                l = 1;
                lead[0] = 0; tail[0] = 0; pr = 0; dp = 0; cs = 0;
                #insert_internal scopy;

            case #char "n"; // weird write-bytes specifier
            {
                _, __, any := va_arg(u64);
                if any.value_pointer && any.type.type == .POINTER {
                    pointer_info := cast(*Type_Info_Pointer) any.type;

                    if any.value_pointer && pointer_info.pointer_to.type == .INTEGER {
                        tag := << cast(*Type_Info_Integer) pointer_info.pointer_to;
                        ptr := << cast(*u64) any.value_pointer;
                        if tag.signed {
                            if tag.runtime_size == 1 {
                                <<cast(*s8)ptr = cast(s8)(tlen + bf - buf);
                            }
                            else if tag.runtime_size == 2 {
                                <<cast(*s16)ptr = cast(s16)(tlen + bf - buf);
                            }
                            else if tag.runtime_size == 4 {
                                <<cast(*s32)ptr = cast(s32)(tlen + bf - buf);
                            }
                            else if tag.runtime_size == 8 {
                                <<cast(*s64)ptr = cast(s64)(tlen + bf - buf);
                            }
                        }
                        else {
                            if tag.runtime_size == 1 {
                                <<cast(*u8)ptr = cast(u8)(tlen + bf - buf);
                            }
                            else if tag.runtime_size == 2 {
                                <<cast(*u16)ptr = cast(u16)(tlen + bf - buf);
                            }
                            else if tag.runtime_size == 4 {
                                <<cast(*u32)ptr = cast(u32)(tlen + bf - buf);
                            }
                            else if tag.runtime_size == 8 {
                                <<cast(*u64)ptr = cast(u64)(tlen + bf - buf);
                            }
                        }
                    }
                }
            }

            case #char "A"; // float
                h=hexu;
                #insert_internal hexfloat;

            case #char "a"; // hex float
                h=hex;
                #insert_internal hexfloat;

            case #char "G"; // float
                h=hexu;
                #insert_internal dosmallfloat;

            case #char "g"; // float
                h=hex;
                #insert_internal dosmallfloat;

            case #char "E"; // float
                h=hexu;
                #insert_internal doexp;

            case #char "e"; // float
                h=hex;
                #insert_internal doexp;

            case #char "f"; // float
                fv = va_arg(float64);
                #insert_internal doafloat;

            case #char "B"; // upper binary
                h = hexu;
                #insert_internal binary;

            case #char "b"; // lower binary
                h = hex;
                #insert_internal binary;

            case #char "o"; // octal
                h = hexu;
                lead[0] = 0;
                if fl & STBSP__LEADING_0X {
                    lead[0] = 1;
                    lead[1] = #char "0";
                }
                l = (3 << 4) | (3 << 8);
                #insert_internal radixnum;

            case #char "p"; // pointer
                // @Note :JAIIS64BIT
                //fl |= (sizeof(void*)==8)?STBSP__INTMAX:0;
                fl |= STBSP__INTMAX;
                pr = size_of(*void) * 2;
                fl &= cast,no_check(u32)(~STBSP__LEADINGZERO); // 'p' only prints the pointer with zeros
                // drop through to X
                #through;

            case #char "X"; // upper binary
                h = hexu;
                #insert_internal dohexb;

            case #char "x"; // lower binary
                h = hex;
                #insert_internal dohexb;

            case #char "u"; #through; // unsigned
            case #char "i"; #through;
            case #char "d"; // integer
                // get the integer and abs it
                if fl & STBSP__INTMAX {
                    i64 : s64;
                    i64 = va_arg(s64);
                    n64 = cast,no_check(u64) i64;
                    if (<<f != #char "u") && (i64 < 0) {
                        n64 = cast,no_check(u64)(-i64);
                        fl |= STBSP__NEGATIVE;
                    }
                }
                else {
                    i : s32;
                    i = va_arg(s32);
                    n64 = cast,no_check(u32) i;
                    if (<<f != #char "u") && (i < 0) {
                        n64 = cast,no_check(u32)(-i);
                        fl |= STBSP__NEGATIVE;
                    }
                }

                if fl & STBSP__METRIC_SUFFIX {
                    if n64 < 1024
                        pr = 0;
                    else if pr == -1
                        pr=1;
                    fv = cast(float64)(cast(s64)n64);
                    #insert_internal doafloat;
                    break;
                }

                // convert to string
                s = *num[0] + STBSP__NUMSZ;
                l=0;

                while true {
                    // do in 32-bit chunks (avoid lots of 64-bit divides even with constant denominators)
                    o : *u8 = s - 8;
                    if n64 >= 100000000 {
                        n = cast,no_check(u32)(n64 % 100000000);
                        n64 /= 100000000;
                    }
                    else {
                        n = cast,no_check(u32) n64;
                        n64 = 0;
                    }

                    if (fl & STBSP__TRIPLET_COMMA) == 0 {
                        while n {
                            s -= 2;
                            <<cast,no_check(*u16)s = <<cast,no_check(*u16) *stbsp__digitpair[(n % 100) * 2];
                            n /= 100;
                        }
                    }

                    while n {
                        if (fl & STBSP__TRIPLET_COMMA) && (l == 3) {
                            l = 0;
                            s -= 1;
                            <<s = stbsp__comma;
                            o -= 1;
                        }
                        else {
                            l += 1;
                            s -= 1;
                            <<s = cast,no_check(u8)(#char "0" + (n % 10));
                            n /= 10;
                        }
                    }

                    if n64 == 0 {
                        if (<<s == #char "0") && (s != (*num[0] + STBSP__NUMSZ))
                            s += 1;
                        break;
                    }

                    while s != o {
                        if (fl & STBSP__TRIPLET_COMMA) && (l == 3) {
                            l = 0;
                            s -= 1;
                            <<s = stbsp__comma;
                            o -= 1;
                        }
                        else {
                            l += 1;
                            s -= 1;
                            <<s = #char "0";
                        }
                    }
                }

                tail[0] = 0;

                // sign
                lead[0] = 0;
                if fl & STBSP__NEGATIVE {
                    lead[0] = 1;
                    lead[1] = #char "-";
                }
                else if fl & STBSP__LEADINGSPACE {
                    lead[0] = 1;
                    lead[1] = #char " ";
                }
                else if fl & STBSP__LEADINGPLUS {
                    lead[0] = 1;
                    lead[1] = #char "+";
                }

                // get the length that we copied
                l = cast,no_check(u32)((*num[0] + STBSP__NUMSZ) - s);
                if l == 0 {
                    s -= 1;
                    <<s = #char "0";
                    l = 1;
                }

                cs = l + (3 << 24);
                if pr < 0  pr = 0;
                #insert_internal scopy;

            case; // unknown, just copy code
                s = *num[0] + STBSP__NUMSZ - 1;
                <<s = <<f;
                l = 1;
                fw, pr, fl = 0;
                lead[0] = 0; tail[0] = 0; pr = 0; dp = 0; cs = 0;
                #insert_internal scopy;
        }

        f += 1;
    }

    if !done {
        if !callback {
            <<bf = 0;
        }
        else {
            stbsp__flush_cb();
        }
    }

    return tlen + cast,no_check(int)(bf - buf);
}



#scope_file



STBSP__SPECIAL :: 0x7000;

nan_label :: "NaN";
inf_label :: "Inf";
null_label :: "null";
kmgt :: "_kmgt";


stbsp__period : u8 = #char ".";
stbsp__comma  : u8 = #char ",";
stbsp__digitpair :: "00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899";


stbsp__context :: struct {
    buf : *u8;
    count : int;
    tmp : [BUFFER_CHARACTERS_PER_CALLBACK] u8;
}


stbsp__clamp_callback :: (buf: *u8, user: *void, len: int) -> *u8 {
    c := cast,no_check(*stbsp__context) user;

    if len > c.count  len = c.count;

    if len {
        if buf != c.buf {
            d := c.buf;
            s := buf;
            se := buf + len;
            <<d += 1;
            <<s += 1;
            while s < se {
                <<d += 1;
                <<s += 1;
            }
        }
        c.buf += len;
        c.count -= len;
    }

    if c.count <= 0  return xx 0;
    return ifx c.count >= BUFFER_CHARACTERS_PER_CALLBACK then c.buf else *c.tmp[0]; // go direct into buffer if you can
}


// =======================================================================
//   low level float utility functions


// copies d to bits w/ strict aliasing (this compiles to nothing on /Ox)
//STBSP__COPYFP :: (dest: Code, src: Code) #expand {
//    for cn: 0 .. 7 {
//        <<(cast(*u8)*(#insert dest) + cn) = <<(cast(*u8)*(#insert src) + cn);
//    }
//}

STBSP__COPYFP :: (dest: Code, src: Code) #expand {
    << cast(*u64)*(#insert dest) = << cast(*u64)*(#insert src);
}

// get float info
stbsp__real_to_parts :: inline (bits: *s64, expo: *s32, value: float64) -> s32 {
    // load value and round at the frac_digits
    d := value;
    b : s64;

    STBSP__COPYFP(b, d);

    <<bits = b & cast,no_check(s64)(((cast,no_check(u64) 1) << 52) - 1);
    <<expo = cast,no_check(s32)(((b >> 52) & 2047) - 1023);

    return cast,no_check(s32)(b >> 63);
}


/*
stbsp__bot       :: float64.[1e+000,1e+001,1e+002,1e+003,1e+004,1e+005,1e+006,1e+007,1e+008,1e+009,1e+010,1e+011,1e+012,1e+013,1e+014,1e+015,1e+016,1e+017,1e+018,1e+019,1e+020,1e+021,1e+022];
stbsp__negbot    :: float64.[1e-001,1e-002,1e-003,1e-004,1e-005,1e-006,1e-007,1e-008,1e-009,1e-010,1e-011,1e-012,1e-013,1e-014,1e-015,1e-016,1e-017,1e-018,1e-019,1e-020,1e-021,1e-022];
stbsp__negboterr :: float64.[-5.551115123125783e-018,-2.0816681711721684e-019,-2.0816681711721686e-020,-4.7921736023859299e-021,-8.1803053914031305e-022,4.5251888174113741e-023,4.5251888174113739e-024,-2.0922560830128471e-025,-6.2281591457779853e-026,-3.6432197315497743e-027,6.0503030718060191e-028,2.0113352370744385e-029,-3.0373745563400371e-030,1.1806906454401013e-032,-7.7705399876661076e-032,2.0902213275965398e-033,-7.1542424054621921e-034,-7.1542424054621926e-035,2.4754073164739869e-036,5.4846728545790429e-037,9.2462547772103625e-038,-4.8596774326570872e-039];
stbsp__top       :: float64.[1e+023,1e+046,1e+069,1e+092,1e+115,1e+138,1e+161,1e+184,1e+207,1e+230,1e+253,1e+276,1e+299];
stbsp__negtop    :: float64.[1e-023,1e-046,1e-069,1e-092,1e-115,1e-138,1e-161,1e-184,1e-207,1e-230,1e-253,1e-276,1e-299];
stbsp__toperr    :: float64.[8388608,6.8601809640529717e+028,-7.253143638152921e+052,-4.3377296974619174e+075,-1.5559416129466825e+098,-3.2841562489204913e+121,-3.7745893248228135e+144,-1.7356668416969134e+167,-3.8893577551088374e+190,-9.9566444326005119e+213,6.3641293062232429e+236,-5.2069140800249813e+259,-5.2504760255204387e+282];
stbsp__negtoperr :: float64.[3.9565301985100693e-040,-2.299904345391321e-063,3.6506201437945798e-086,1.1875228833981544e-109,-5.0644902316928607e-132,-6.7156837247865426e-155,-2.812077463003139e-178,-5.7778912386589953e-201,7.4997100559334532e-224,-4.6439668915134491e-247,-6.3691100762962136e-270,-9.436808465446358e-293,8.0970921678014997e-317];
*/

// @Note Following hex values generated on godbolt from above constants, using
/**
```c++
#include <iomanip>
#include <iostream>
using namespace std;

void out(double d) {
    cout<<hex<<*reinterpret_cast<uint64_t*>(&d)<<endl;
}

int main() {
    out(1e+001);
    // ...
}
```
*/

stbsp__bot       :: float64.[0h3ff0000000000000, 0h4024000000000000, 0h4059000000000000, 0h408f400000000000, 0h40c3880000000000, 0h40f86a0000000000, 0h412e848000000000, 0h416312d000000000, 0h4197d78400000000, 0h41cdcd6500000000, 0h4202a05f20000000, 0h42374876e8000000, 0h426d1a94a2000000, 0h42a2309ce5400000, 0h42d6bcc41e900000, 0h430c6bf526340000, 0h4341c37937e08000, 0h4376345785d8a000, 0h43abc16d674ec800, 0h43e158e460913d00, 0h4415af1d78b58c40, 0h444b1ae4d6e2ef50, 0h4480f0cf064dd592];
stbsp__negbot    :: float64.[0h3fb999999999999a, 0h3f847ae147ae147b, 0h3f50624dd2f1a9fc, 0h3f1a36e2eb1c432d, 0h3ee4f8b588e368f1, 0h3eb0c6f7a0b5ed8d, 0h3e7ad7f29abcaf48, 0h3e45798ee2308c3a, 0h3e112e0be826d695, 0h3ddb7cdfd9d7bdbb, 0h3da5fd7fe1796495, 0h3d719799812dea11, 0h3d3c25c268497682, 0h3d06849b86a12b9b, 0h3cd203af9ee75616, 0h3c9cd2b297d889bc, 0h3c670ef54646d497, 0h3c32725dd1d243ac, 0h3bfd83c94fb6d2ac, 0h3bc79ca10c924223, 0h3b92e3b40a0e9b4f, 0h3b5e392010175ee6];
stbsp__negboterr :: float64.[0hbc5999999999999a, 0hbc0eb851eb851eb8, 0hbbd89374bc6a7efa, 0hbbb6a161e4f765fe, 0hbb8ee78183f91e64, 0h3b4b5a63f9a49c2c, 0h3b15e1e99483b023, 0hbad03023df2d4c94, 0hbab34674bfabb83b, 0hba720a5465df8d2c, 0h3a47f7bc7b4d28aa, 0h39f97f27f0f6e886, 0hb9cecd79a5a0df95, 0h394ea70909833de7, 0hb97937831647f5a0, 0h3925b4c2ebe68799, 0hb90db7b2080a3029, 0hb8d7c628066e8cee, 0h388a52b31e9e3d07, 0h38675447a5d8e536, 0h383f769fb7e0b75e, 0hb7fa7566d9cba769];
stbsp__top       :: float64.[0h44b52d02c7e14af6, 0h497c06a5ec5433c6, 0h4e428bc8abe49f64, 0h53088ba3bf284e24, 0h57d03e29f5c2b18c, 0h5c957f48bb41db7c, 0h615c73892ecbfbf4, 0h6622d3d6f88f0b3d, 0h6ae8eb0138858d0a, 0h6fb07d457124123d, 0h7475d2ce55747a18, 0h793ce2137f743382, 0h7e031cfd3999f7b0];
stbsp__negtop    :: float64.[0h3b282db34012b251, 0h366244ce242c5561, 0h319b9b6364f30304, 0h2cd4dbf7b3f71cb7, 0h280f8587e7083e30, 0h2347d12a4670c123, 0h1e81fee341fc585d, 0h19bb31bb5dc320d2, 0h14f48c22ca71a1bd, 0h102f0ce4839198db, 0h0b677603725064a8, 0h06a1ba03f5b21000, 0h01dac9a7b3b7302f];
stbsp__toperr    :: float64.[0h4160000000000000, 0h45ebb542c80deb40, 0hcae83b80b9aab60a, 0hcfa32e22d17a166c, 0hd4523606902e180e, 0hd9296fb782462e87, 0hddf358952c0bd011, 0he2a78c1376a34b6c, 0he7817569fc243adf, 0hec5d9365a897aaa6, 0h7119050c256123a0, 0hf5db1799d76cc7a6, 0hfaa213fe39571a38];
stbsp__negtoperr :: float64.[0h37c13badb829e079, 0hb2ee46a98d3d9f64, 0h2e3227c7218a2b65, 0h2951d96999aa01e9, 0ha4acc2229efc3962, 0h9fecd04a2263407a, 0h9b123b80f187a157, 0h965c4e22914ed912, 0h119bc296cdf42f82, 0h8cc9f9e7f4e16fe1, 0h880aeb0a72a8902a, 0h834e228e12c13408, 0h0000000000fa1259];

stbsp__powten :: u64.[1,10,100,1000, 10000,100000,1000000,10000000, 100000000,1000000000,10000000000,100000000000,1000000000000,10000000000000,100000000000000,1000000000000000,10000000000000000,100000000000000000,1000000000000000000,10000000000000000000];
stbsp__tento19th : u64 : 1000000000000000000;


stbsp__ddmulthi :: (oh: Code, ol: Code, xh: Code, yh: Code) #expand {
    ahi : float64 = 0;
    alo : float64 = ---;
    bhi : float64 = 0;
    blo : float64 = ---;
    bt : s64 = ---;
    (#insert oh) = (#insert xh) * (#insert yh);
    STBSP__COPYFP(bt, (#insert xh)); bt &= cast,no_check(s64)((~cast,no_check(u64)0) << 27); STBSP__COPYFP(ahi, bt); alo = (#insert xh) - ahi;
    STBSP__COPYFP(bt, (#insert yh)); bt &= cast,no_check(s64)((~cast,no_check(u64)0) << 27); STBSP__COPYFP(bhi, bt); blo = (#insert yh) - bhi;
    (#insert ol) = ((ahi * bhi - (#insert oh)) + ahi * blo + alo * bhi) + alo * blo;
}


stbsp__ddtoS64 :: (ob: Code, xh: Code, xl: Code) #expand {
    ahi : float64 = 0;
    alo : float64 = ---;
    vh : float64 = ---;
    t : float64 = ---;
    (#insert ob) = cast,no_check(s64) `ph;
    vh = cast,no_check(float64) (#insert ob);
    ahi = (#insert xh) - vh;
    t = ahi - (#insert xh);
    alo = ((#insert xh) - (ahi - t)) - (vh + t);
    (#insert ob) += cast,no_check(s64)(ahi + alo + (#insert xl));
}


stbsp__ddrenorm :: (oh: Code, ol: Code) #expand {
    s : float64 = ---;
    s = cast,no_check(float64)((#insert oh) + (#insert ol));
    (#insert ol) = (#insert ol) - (s - (#insert oh));
    (#insert oh) = s;
}


stbsp__ddmultlo :: (oh: Code, ol: Code, xh: Code, xl: Code, yh: Code, yl: Code) #expand {
    (#insert ol) = (#insert ol) + ((#insert xh)*(#insert yl) + (#insert xl)*(#insert yh));
}


stbsp__ddmultlos :: (oh: Code, ol: Code, xh: Code, yl: Code) #expand {
    (#insert ol) = (#insert ol) + ((#insert xh)*(#insert yl));
}


stbsp__raise_to_power10 :: (ohi: *float64, olo: *float64, d: float64, power: s32)  // power can be -323 to +350
{
    ph, pl: float64;
    if (power >= 0) && (power <= 22) {
        stbsp__ddmulthi(ph, pl, d, stbsp__bot[power]);
    }
    else
    {
        e, et, eb: s32;
        p2h, p2l: float64;

        e = power;
        if power < 0  e = -e;
        et = (e * 0x2c9) >> 14;/* %23 */
        if et > 13  et = 13;
        eb = e - (et * 23);

        ph = d; pl = 0;
        if power < 0 {
            if eb {
                eb -= 1;
                stbsp__ddmulthi(ph, pl, d, stbsp__negbot[eb]);
                stbsp__ddmultlos(ph, pl, d, stbsp__negboterr[eb]);
            }

            if et {
                stbsp__ddrenorm(ph, pl);
                et -= 1;
                stbsp__ddmulthi(p2h, p2l, ph, stbsp__negtop[et]);
                stbsp__ddmultlo(p2h, p2l, ph, pl, stbsp__negtop[et], stbsp__negtoperr[et]);
                ph = p2h;
                pl = p2l;
            }
        }
        else {
            if eb {
                e = eb;
                if eb > 22  eb = 22;
                e -= eb;
                stbsp__ddmulthi(ph, pl, d, stbsp__bot[eb]);
                if e {
                    stbsp__ddrenorm(ph, pl);
                    stbsp__ddmulthi(p2h, p2l, ph, stbsp__bot[e]);
                    stbsp__ddmultlos(p2h, p2l, stbsp__bot[e], pl);
                    ph = p2h;
                    pl = p2l;
                }
            }
            if et {
                stbsp__ddrenorm(ph, pl);
                et -= 1;
                stbsp__ddmulthi(p2h, p2l, ph, stbsp__top[et]);
                stbsp__ddmultlo(p2h, p2l, ph, pl, stbsp__top[et], stbsp__toperr[et]);
                ph = p2h;
                pl = p2l;
            }
        }
    }
    stbsp__ddrenorm(ph, pl);
    <<ohi = ph;
    <<olo = pl;
}


// given a float value, returns the significant bits in bits, and the position of the
//   decimal point in decimal_pos.  +/-INF and NAN are specified by special values
//   returned in the decimal_pos parameter.
// frac_digits is absolute normally, but if you want from first significant digits (got %g and %e), or in 0x80000000

stbsp__real_to_str :: (start: **u8, len: *u32, out: *u8, decimal_pos: *s32, value: float64, frac_digits: u32) -> s32 {
    bits : s64;
    expo, e, ng, tens : s32;

    d := value;

    STBSP__COPYFP(bits, d);
    expo = cast,no_check(s32)((bits >> 52) & 2047);
    ng = cast,no_check(s32)(bits >> 63);
    if ng  d = -d;

    if expo == 2047 { // is nan or inf?
        <<start = ifx (bits & cast,no_check(s64)(((cast,no_check(u64)1) << 52) - 1)) then nan_label.data else inf_label.data;
        <<decimal_pos = STBSP__SPECIAL;
        <<len = 3;
        return ng;
    }

    if expo == 0 { // is zero or denormal
        if (bits << 1) == 0 { // do zero
            <<decimal_pos = 1;
            <<start = out;
            <<out = #char "0";
            <<len = 1;
            return ng;
        }
        // find the right expo for denormals
        {
            one : u64 : 1;
            v : s64 = cast,no_check(s64)(one << 51);
            while (bits & v) == 0 {
                expo -= 1;
                v >>= 1;
            }
        }
    }

    // find the decimal exponent as well as the decimal bits of the value
    {
        ph, pl: float64;

        // log10 estimate - very specifically tweaked to hit or undershoot by no more than 1 of log10 of all expos 1..2046
        tens = expo - 1023;
        tens = ifx tens < 0 then (tens * 617) / 2048 else ((tens * 1233) / 4096) + 1;

        // move the significant bits into position and stick them into an int
        stbsp__raise_to_power10(*ph, *pl, d, 18 - tens);

        // get full as much precision from double-double as possible
        stbsp__ddtoS64(bits, ph, pl);

        // check if we undershot
        if cast(u64)bits >= stbsp__tento19th
            tens += 1;
    }

    // now do the rounding in integer land
    frac_digits = ifx frac_digits & 0x80000000 then (frac_digits & 0x7ffffff) + 1 else cast,no_check(u32)tens + frac_digits;
    if frac_digits < 24 {
        dg : u32 = 1;
        if cast,no_check(u64)bits >= stbsp__powten[9]
            dg=10;

        done_fracing := false;
        while cast,no_check(u64)bits >= stbsp__powten[dg] {
            dg += 1;
            if dg == 20 {
                done_fracing = true;
                break;
            }
        }

        if !done_fracing && frac_digits < dg {
            // add 0.5 at the right position and round
            e = cast,no_check(s32)dg - cast,no_check(s32)frac_digits;
            if cast,no_check(u32)e < 24 {
                r : u64 = stbsp__powten[e];
                bits = bits + cast,no_check(s64)(r / 2);
                if cast,no_check(u64)bits >= stbsp__powten[dg]
                    tens += 1;
                bits /= cast,no_check(s64)r;
            }
        }
    }

    // kill long trailing runs of zeros
    if bits {
        done_killing := false;
        while true {
            if bits <= 0xffffffff  break;
            if bits % 1000 {
                done_killing = true;
                break;
            }
            bits /= 1000;
        }
        if !done_killing {
            n := cast,no_check(u32)bits;
            while (n % 1000) == 0
                n /= 1000;
            bits=n;
        }
    }

    // convert to string
    out += 64;
    e = 0;
    while true {
        n : u32 = ---;
        o := out - 8;
        // do the conversion in chunks of U32s (avoid most 64-bit divides, worth it, constant denomiators be damned)
        if bits >= 100000000 {
            n = cast,no_check(u32)(bits % 100000000);
            bits /= 100000000;
        }
        else {
            n = cast,no_check(u32)bits;
            bits = 0;
        }

        while n {
            out -= 2;
            <<cast,no_check(*u16)out = << cast,no_check(*u16) *stbsp__digitpair[(n % 100) * 2];
            n /= 100;
            e += 2;
        }

        if bits == 0 {
            if e && <<out == #char "0" {
                out += 1;
                e -= 1;
            }
            break;
        }

        while out != o {
            out -= 1;
            <<out = #char "0";
            e += 1;
        }
    }

    <<decimal_pos = tens;
    <<start = out;
    <<len = cast,no_check(u32)e;

    return ng;
}
