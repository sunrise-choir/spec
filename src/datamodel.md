# Datamodel

Ssb accepts schemaless data, adhering to a certain format specified in this section. This is the data that application developers care about. Internally, ssb then adds some more metadata to maintain the append-only logs, discussed in the [next chapter](./messages). This chapter only describes the data model of the schemaless content data.

It is important to clearly distinguish between the abstract data model of a format, and various encodings. For example, the strings `1`, `1.0` and `0.1e1` are all different [json](http://json.org/) encodings of the same abstract value. And there can even be different encoding formats for the same abstract value, e.g. the bytes `0xf93c00` also encode the floating point number 1.0, but in [cbor](https://tools.ietf.org/html/rfc7049) rather than json.

Ssb messages all use the same abstract data model, but there are different situations where they use different encodings. An encoding used for signing the data has different requirements than an encoding used for transmitting the data, which again has different requirements than an encoding used for persisten storage.

Encodings for persistent storage are not specified in this document, but is crucial for all ssb implementations to compute the exact same signatures, and to send data in a format that can be understood by other implementations. We call these encodings *signing encoding* and *transport encoding* respectively.

The ssb protocol was initially implemented in javascript, and it relied heavily on implicit behavior of the [node js](https://nodejs.org/en/) runtime. It has since switched to a more carefully designed message format, but the old fomat still needs to be supported to keep backwards-compatibility.

## Legacy Data

This section describes the message format that was originally used by ssb. The protocol has since moved on, everything here should be considered deprecated. But for backwards compatibility, ssb servers still need to understand, verify and relay old messages.

Legacy messages have been deprecated because their design emerged organically through reliance on the default behavior of certain features of [node js](https://nodejs.org/en/). People (including the authors of this specification) have called the legacy message format "bizarre" and worse, and that is entirely justified. But when during reading you inevitably thing "How could anybody end up with this, I could have done a much better job.", then remember: Maybe you could have, but you didn't.

### Abstract Data Model

The legacy data model describes all of the free-form data that can be carried in a legacy message. It is close to the [json](http://json.org/) data model, but with a few differences. The definition came about as the set of javascript values created by `JSON.parse(json)` for which [`json === JSON.stringify(JSON.parse(json))`](%EyGGCcjAbaShKFCMxXKYiZjQe17SR298D0SLTuKmZpo=.sha256) (javascript code).

Defined in a language-agnostic way:

###### Null
`null` is a legacy value that carries [no information](https://en.wikipedia.org/wiki/Unit_type).

###### Booleans
`true` and `false` are legacy values, called *booleans*.

###### Strings
An ordered sequence of bytes which form valid [utf8](https://en.wikipedia.org/wiki/UTF-8) of length between `0` and `2^53 - 1` (inclusive) is a legacy value, called a *string*. Such a string may include null bytes.

###### Floats
An [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754) double precision (64 bit) floating point number that is none of `Infinity`, `-Infinity`, `-0` or `NaN` is a legacy value, called a *float*.

###### Arrays
Let `n` be a natural number less than `2^32`, and let `v_0, ..., v_n` be [legacy values](#abstract-data-model).

The ordered sequence `[v_0, ..., v_n]` is a legacy value, called an *array*.

###### Objects
Let `n` be a natural number less than `2^32`, let `s_0, ..., s_n` be pairwise distinct [strings](#strings), and let `v_0, ..., v_n` be [legacy values](#abstract-data-model).

The (unordered) set of pairs `(s_i, s_i)` for all `0 <= i <= n` is a legacy value, called a *object*. The pairs are called *entries*, the strings are called *keys*, and the legacy values are called *values*.

### Signing Encoding

The encoding to turn legacy values into a signeable array of bytes is based on json (the set of valid encodings is a subset of [ECMA-404 json](https://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf)). There are multiple valid encodings of a single value, because some of the entries of an objects can be encoded in an arbitary order. But up to object entry order, the encoding is unique. When receiving a message over the network, the order of the freely-orderable object entries in the transport encoding is the order that must be used for verifying the signature. Thus the network encoding induces a unique signing encoding to use for signature checking.

The signing encoding is defined as follows:

###### Signing Encoding Null
`null` is encoded as the utf-8 string `null` (`[0x6E, 0x75, 0x6C, 0x6C]`).

###### Signing Encoding Booleans
`true` is encoded as the utf-8 string `true` (`[0x74, 0x72, 0x75, 0x65]`).  
`false` is encoded as the utf-8 string `false` (`[0x66, 0x61, 0x6c, 0x73, 0x65]`).

###### Signing Encoding Strings
A string containing the unicode code points `c_0, ..., c_n` is is encoded as follows:

- begin with the utf-8 string `"` (`0x22`)
- for each code point `c_i` in `c_0, ..., c_n`:
  - if `c_i` is unicode code point `0x000022` (quotation mark `"`), append the utf-8 string `\"` (`[0x5C, 0x22]`)
  - else if `c_i` is unicode code point `0x00005C` (reverse solidus `\`), append the utf-8 string `\\` (`[0x5C, 0x5C]`)
  - else if `c_i` is unicode code point `0x000008` (backspace), append the utf-8 string `\b` (`[0x5C, 0x62]`)
  - else if `c_i` is unicode code point `0x00000C` (form feed), append the utf-8 string `\f` (`[0x5C, 0x66]`)
  - else if `c_i` is unicode code point `0x00000A` (line feed), append the utf-8 string `\n` (`[0x5C, 0x6E]`)
  - else if `c_i` is unicode code point `0x00000D` (carriage return), append the utf-8 string `\r` (`[0x5C, 0x72]`)
  - else if `c_i` is unicode code point `0x000009` (line tabulation), append the utf-8 string `\t` (`[0x5C, 0x74]`)
  - else if `c_i` is a unicode code point below `0x000020` (space), append the utf-8 string `\u<hex>` (`[0x5C, 0x75, <hex>]`), where `<hex>` are the two utf-8 bytes of the hexadecimal encoding of the code point, using lower-case letters `a` - `f` (`0x61` - `0x66`) for alphabetic hex digits
  - else append the utf-8 representation of `c_i` without any modifications
- append the utf-8 string `"` (`0x22`)

###### Signing Encoding Floats

A float `m` is encoded as follows:

- if `m == 0`, the encoding is the utf-8 string `0` (`0x30`)
- else if `m` is negative, the encoding is the utf-8 string `-<abs(m)>`(`[0x2d, <abs(m)>]`), where `<abs(m)>` is the encoding of the same float with the sign bit flipped
- else (largely quoting from the [ECMAScript specification, applying NOTE 2](https://www.ecma-international.org/ecma-262/6.0/#sec-tostring-applied-to-the-number-type) from here on):
  - let `n`, `k` and `s` be integers such that:
    - `k >= 1`
    - `10 ^ (k - 1) <= s <= 10 ^ k`
    - `s * (10 ^ (n - k))` is `m` (or [round-to-even-s](https://en.wikipedia.org/wiki/Rounding#Round_half_to_even) to `m` if it is not precisely representable in a 64 bit float)
    - `k` is as small as possible
    - if there are multiple values for `s`, choose the one for which `s * (10 ^ (n - k))` is closest in value to `m`
    - if there are two such possible values of `s`, choose the one that is even
    - Intuitively, `s` is the integer you get by removing the point and all trailing zeros from the decimal representation of `m`, `k` is the number of digits in the decimal representation of `s`, and `n` specifies how to print the number: If `n` is greater than `0`, there are `n` digits left of the point, else there are `abs(n)` many zeros right of the point. The choice of `s` uniquely determines `k` and `n`, the tricky part is finding the unique `s` that rounds correctly and for which `k` is minimal.
  - if `k <= n <= 21`, the encoding is the utf-8 string `<k_decimals><trailing_zeros>`, where `<k_decimals>` is the utf-8 encoding of the digits of the decimal representation of `s`, and `<trailing_zeros` are `n - k` zero digits (`0x30`)
  - else if `0 <= n <= 21`, the encoding is the utf-8 string `<pre_point>.<post_point>` (`[<pre_point>, 0x2E, <post_point>]`), where `<pre_point>` is the utf-8 encoding of the most significant `n` digits of the decimal representation of `s`, and `<post_point>` is the utf-8 encoding of the remaining `k - n` digits of the decimal representation of `s`
  - else if `-6 < n <= 0`, the encoding is the utf-8 string `0.<zeros><k_decimals>` (`[0x30, 0x2E, <zeros>, <k_decimals>]`), where `<zeros>` are `-n` many zero digits (`0x30`), and `<k_decimals>` is the utf-8 encoding of the digits of the decimal representation of `s`
  - else if `k == 1`, the encoding is `<base>e<sign><exp>` (`[<base>, 0x65, <sign>, <exp>]`), where `<base>` is the utf-8 encoding of the single digit of `s`, `<sign>` is the utf-8 string `+` (`0x2B`) if `n - 1` is positive or the utf-8 string `-` (`0x2D`) if `n - 1` is negative, and `<exp>` is the utf-8 encoding of the decimal representation of the absolute value of `n - 1`
  - else, the encoding is the utf-8 string `<pre_point>.<post_point>e<sign><exp>` (`[<pre_point>, 0x2E, <post_point>, 0x65, <sign>, <exp>]`), where `<pre_point>` is the utf-8 encoding of the most significant digit of the decimal representation of `s`, `<post_point>` is the utf-8 encoding of the remaining `k - 1` digits of the decimal representation of `s`, `<sign>` is the utf-8 string `+` (`0x2B`) if `n - 1` is positive or the utf-8 string `-` (`0x2D`) if `n - 1` is negative, and `<exp>` is the utf-8 encoding of the decimal representation of the absolute value of `n - 1`
- good to know: The maximum length for such an encoding is 25 bytes

###### Signing Encoding Arrays

Let `n` be a natural number less than `2^32`, let `v_0, ..., v_n` be [legacy values](#abstract-data-model), and let `e_0, ..., e_n` be functions that take a natural number as an argument and return the [encodings](#signing-encoding) of `v_0, ..., v_n` respectively using the supplied number as the indentation level.

At indentation level `indent`, the array `[v_0, ..., v_n]` is encoded as follows:

- if the array is empty (`n == 0`), the encoding is the utf-8 string `[]` (`[0x5B, 0x5D]`)
- else, do the following:
  - begin with the utf-8 string `[<line feed>` (`[0x5B, 0x0A]`)
  - for each `v_i` in `v_0, ..., v_(n - 1)` (so skip this if `n == 1`):
    - append `indent + 2` many space characters (`0x20`)
    - append `e_i(indent + 2)`
    - append the utf-8 string `,<line feed>` (`[0x2C, 0x0A]`)
  - append `indent + 2` many space characters (`0x20`)
  - append `e_n(indent + 2)`
  - append the utf-8 string `<line feed>` (`0x0A`)
  - append `indent` many space characters (`0x20`)
  - append the utf-8 string `]` (`0x5D`)

###### Signing Encoding Objects

Let `n` be a natural number less than `2^32`, let `s_0, ..., s_n` be pairwise distinct [strings](#strings), let `v_0, ..., v_n` be [legacy values](#abstract-data-model), and let `e_0, ..., e_n` be functions that take a natural number as an argument and return the [encodings](#signing-encoding) of `v_0, ..., v_n` respectively using the supplied number as the indentation level.

At indentation level `indent`, the object `{ s_0: v_0, ..., s_n: v_n}` is encoded as follows:

- if the object is empty (`n == 0`), the encoding is the utf-8 string `{}` (`[0x7B, 0x7D]`)
- else, do the following:
  - begin with the utf-8 string `{<line feed>` (`[0x7B, 0x0A]`)
  - for each pair `(s_i, v_i)` for `i` in `0, ..., n - 1` (so skip this if `n == 1`):
    - append `indent + 2` many space characters (`0x20`)
    - append the encoding of the string `s_i`
    - append the utf-8 string `:<space>` (`[0x3A, 0x20]`)
    - append `e_i(indent + 2)`
    - append the utf-8 string `,<line feed>` (`[0x2C, 0x0A]`)
  - append `indent + 2` many space characters (`0x20`)
  - append the encoding of the string `s_i`
  - append the utf-8 string `:<space>` (`[0x3A, 0x20]`)
  - append `e_i(indent + 2)`
  - append the utf-8 string `<line feed>` (`0x0A`)
  - append `indent` many space characters (`0x20`)
  - append the utf-8 string `}` (`0x7D`)
- The order in which to serialize the entries `s_i: v_i` is not fully specified, but there are some constraints:
  - intuitively: Natural numbers are sorted ascendingly
  - formally:
    - if there is an entry with the key `"0"` (`0x30`), the entry must be the first to be serialized
    - all entries whose keys begin with a nonzero decimal digit (1 - 9 (`0x31` - `0x39`)) followed by zero or more arbitrary decimal digits (0 - 9 (`0x30` - `0x39`)) and consists solely of such digits, must be serialized before all other entries (but after an entry with key `"0"` if one exists). Amongst themselves, these keys are sorted:
      - by length first (ascending), using
      - numeric value as a tie breaker (the key whose raw bytes interpreted as a natural number are larger is serialized later)
        - note that this coincides with sorting the decimally encoded numbers by numeric value
  - all other entries may be serialized in an arbitrary order

The string handling is equivalent to [ECMAScript 2015 QuoteJSONString](https://www.ecma-international.org/ecma-262/6.0/#sec-quotejsonstring), but defined over utf-8 strings instead of utf-16 ones.

The float handling is equivalent to (and quotes from) [ECMAScript 2015 ToString Applied to the Number Type](https://www.ecma-international.org/ecma-262/6.0/#sec-tostring-applied-to-the-number-type), with step 5 replaced as specified in NOTE 2 to result in unique encodings. This spec provides a declarative description of the encoding process, for an algorithmic perspective, there are some papers on the subject such as:

- [Steele Jr, Guy L., and Jon L. White. "How to print floating-point numbers accurately." ACM SIGPLAN Notices. Vol. 25. No. 6. ACM, 1990.](https://lists.nongnu.org/archive/html/gcl-devel/2012-10/pdfkieTlklRzN.pdf)
- [Loitsch, Florian. "Printing floating-point numbers quickly and accurately with integers." ACM Sigplan Notices. Vol. 45. No. 6. ACM, 2010.](https://www.cs.tufts.edu/~nr/cs257/archive/florian-loitsch/printf.pdf)
- [Andrysco, Marc, Ranjit Jhala, and Sorin Lerner. "Printing floating-point numbers: a faster, always correct method." ACM SIGPLAN Notices. Vol. 51. No. 1. ACM, 2016.](https://cseweb.ucsd.edu/~lerner/papers/fp-printing-popl16.pdf)
- [Adams, Ulf. "Ryū: fast float-to-string conversion." Proceedings of the 39th ACM SIGPLAN Conference on Programming Language Design and Implementation. ACM, 2018.](https://dl.acm.org/citation.cfm?id=3192369)

The array and object handling is equivalent to `JSON.stringify(value, null, 2)`, specified in [ECMAScript 2015](https://www.ecma-international.org/ecma-262/6.0/#sec-json.stringify) (except for the object entry ordering, which is not specified in ECMAScript, but implemented this way in v8 and spidermonkey).

### Legacy Hash Computation

To compute the hash of a legacy value, you can not use the signing encoding directly, but the hash computation is based on it. The signing encoding always results in valid unicode. Represent this unicode in [utf-16](https://en.wikipedia.org/wiki/UTF-16). This encoding is a sequence of code units, each consisting of two bytes. The data to hash is obtained from these code units by only keeping the less significant byte.

Example: Suppose you want to compute the hash for `"ß"`, the corresponding utf8 is `[0x22, 0xC3, 0x9F, 0x22]`. In big-endian utf16, this is `[(0x22, 0x00), (0xDF, 0x00), (0x22, 0x00)]`, in little-endian utf16, this is `[(0x00, 0x22), (0x00, 0xDF), (0x00, 0x22)]`. In both cases, the sequence of less signifiant bytes per code unit is `[0x22, 0xDF, 0x22]`. That is the byte array over which to compute the hash.

Note that this means that two strings with different utf-8 encodings can result in the same hash, due to the information in the more significant byte of the utf-16 encoding being dropped.

### Legacy Length Computation

Ssb places a limit on the size of legacy messages. To compute the length of a legacy value, compute the signing encoding (which is always valid unicode), reencode that unicode as utf16, then count the number of code units.

### JSON Transport Encoding

In addition to the signing format, legacy messages can be encoded as [ECMA-404 json](https://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf), with the following differences:

- numbers may not be negative zero
- numbers may not round to positive infinity, negative infinity or negative zero IEEE 754 64 bit floating point numbers
- strings may not be longer than `2^53 - 1` bytes
- arrays and object may not contain more than `2^32 - 1` entries
- objects may not contain multiple entries with the same key
- in strings, unicode escape sequences of code points greater than `U+FFFF` must be interpreted as a single code point, not as an explicit surrogate pair
- escape sequences of surrogate code points must be matched: Each escape sequence for a high surrogate must be followed by an escape sequence for a low surrogate, and any escape sequence for a low surrogate must be preceded by an escape sequence for a high surrogate

The signing format itself is a subset of this, but this format can be more compact (by omitting all whitespace). This compact form has been used by the first ssb server implementations for message exchange with other servers.

### CBOR Encoding

A much more compact encoding for use in inter-server communication is based on [CBOR (ietf rfc 7049)](https://tools.ietf.org/html/rfc7049), with the following differences:

- The only allowed major types are:
  - `3` (text string)
  - `4` (array)
  - `5` (map)
  - `7` (primitives)
- no indefinite length strings, arrays or maps (additional type `31` is not allowed)
- strings, arrays, maps must use the shortest possible encoding of their length
- the key data items in a map must be text strings (have major type `3`)
- primitives are restricted to the following additional types:
  - `20` (`false`)
  - `21` (`true`)
  - `22` (`null`)
  - `27` (64-bit floats)

- `null` is encoded as cbor `null` (`0xF6`)
- `true` is encoded as cbor `true` (`0xF5`)
- `false` is encoded as cbor `false` (`0xF4`)
- strings are encoded as cbor strings (major type 3)
- floats are encoded as cbor 64 bit floats (`0xFB`) followed by the eight bytes of the IEEE 754 float (sign, exponent, fraction in that order)
- arrays are encoded as cbor arrays (major type 4)
- objects are encoded as cbor maps (major type 7), only using strings as keys
