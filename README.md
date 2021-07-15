# jai-c-format

This is an implementation of ideas proposed by @RLuba during the beta-tester Q&A stream.  It includes a native jai implementation of stbsprintf, so there are no binary dependencies.  To use copy the two module folders into your jai modules path, then use the `f` function to format a string using standard sprintf code:

```jai
#import "C_Format";

main :: () {
    print(f("First letter is: %c\n", 65));
    print(f("A number is: %07.4f\n", 17.0 / 13.0));
}
```
