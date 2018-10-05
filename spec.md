# Secure Scuttlebutt Specification

Secure Scuttlebutt is a bla... TODO High level overview goes here.

## Feeds and Messages

TODO General description of sigchains, how they are constructed and why ssb relies on that particular data structure.

TODO signatures, hashes, cypherlinks, future-proofness

TODO General introduction to free form messages. Differences between abstract data model, signing encodings, transport encodings and database encodings (but stress that db encodings can be freely chosen and are not part of the protocol - in-memory implementations (including pure client-side implementations) don't even need them).

TODO maximum message sizes

### Legacy Messages

This section describes the message format that was originally used for ssb. The protocol has since moved on, everything here should be considered deprecated. But for backwards compatibility, ssb servers still need to understand, verify and relay old messages.

Legacy messages have been deprecated, because their design emerged organically through reliance on the default behavior of certain features of [node js](https://nodejs.org/en/). People (including the authors of this specification) have called the legacy message format "bizarre" and worse, and that is entirely justified. But when during reading you inevitably thing "How could anybody end up with this, I could have done a much better job.", then remember: Maybe you could have, but you didn't.

#### Abstract Data Model

The legacy data model describes all of the free-form data that can be carried in a legacy message. It is close to the [json](http://json.org/) data model, but with a few differences. The definition came about as the set of javascript values created by `JSON.parse(json)` for which [`json === JSON.stringify(JSON.parse(json))`](%EyGGCcjAbaShKFCMxXKYiZjQe17SR298D0SLTuKmZpo=.sha256) (javascript code).

Defined inductively in a language-agnostic way:

###### Base Cases

- `null` is a legacy value, simply called *null*
- `true` and `false` are legacy values, called *booleans*
- an ordered sequence of bytes which form valid [utf8](https://en.wikipedia.org/wiki/UTF-8)  of length between `0` and `2^53 - 1` (inclusive) is a legacy value (may include null bytes, called a *utf8 string*)
- an [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754) double precision (64 bit) floating point number that is none of `Infinity`, `-Infinity`, `-0` or `NaN` is a legacy value, called a *float*

###### Induction Hypotheses

Let `v_0, ..., v_n` be legacy values.

###### Inductive Step

- An ordered sequence `[v_0, ..., v_n]` where `n < 2^32 - 1`, is a legacy value, called an *array*
- An unordered set of at most `2^32 - 1` pairs of strings `s_i` (called *keys*) and legacy values `v_i` (called *values*), where all `s_i, s_j` are pairwise distinct, is a legacy value (called an *object*, written `{ "foo": v_1, "bar": v_2}`, the empty object is written as `{}`)

#### Signing Encoding

The encoding to turn legacy values into a signeable array of bytes is based on json (the set of valid encodings is a subset of [ECMA-404 json](https://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf)). There are multiple valid encodings of a single value, because the entries of an objects can be encoded in an arbitary order. But up to object order, the encoding is unique. When receiving a message over the network, the order of the object entries in the transport encoding is the order that must be used for verifying the signature. Thus the network encoding induces a unique signing encoding to use for signature checking.

The signing encoding is defined inductively as follows:

###### Base Cases

- `null` is encoded as the utf-8 string `null` (`6E 75 6C 6C` in bytes)
- `true` is encoded as the utf-8 string `true` (`74 72 75 65` in bytes)
- `false` is encoded as the utf-8 string `false` (`66 61 6c 73 65` in bytes)
- a utf8-string containing the code points `c_0, ..., c_n` is is encoded as follows:
  - begin with the utf-8 string `"` (`22` in bytes)
  - for each code point `c_i` in `c_0, ..., c_n`:
    - if `c_i` is unicode code point `0x000022` (quotation mark `"`), append the utf-8 string `\"` (`5C 22` in bytes)
    - else if `c_i` is unicode code point `0x00005C` (reverse solidus `\`), append the utf-8 string `\\` (`5C 5C` in bytes)
    - else if `c_i` is unicode code point `0x000008` (backspace), append the utf-8 string `\b` (`5C 62` in bytes)
    - else if `c_i` is unicode code point `0x00000C` (form feed), append the utf-8 string `\f` (`5C 66` in bytes)
    - else if `c_i` is unicode code point `0x00000A` (line feed), append the utf-8 string `\n` (`5C 6E` in bytes)
    - else if `c_i` is unicode code point `0x00000D` (carriage return), append the utf-8 string `\r` (`5C 72` in bytes)
    - else if `c_i` is unicode code point `0x000009` (line tabulation), append the utf-8 string `\t` (`5C 74` in bytes)
    - else if `c_i` is a unicode code point below `0x000020` (space), append the utf-8 string `\u<hex>` (`5C 75 <hex>` in bytes), where `<hex>` are the two utf-8 bytes of the hexadecimal encoding of the code point, using lower-case letters `a` - `f` (bytes `61` to `66`) for alphabetic hex digits
    - else append the utf-8 representation of `c_i` without any modifiations
  - append the utf-8 string `"` (`22` in bytes)
- a float `m` is encoded as follows:
  - if `m == 0`, the encoding is the utf-8 string `0` (`30` in bytes)
  - else if `m` is negative, the encoding is the utf-8 string `-<abs(m)>`(`2d <abs(m)>` in bytes), where `<abs(m)>` is the encoding of the same float with the sign bit flipped
  - else (largely quoting from the [ECMAScript specification, applying NOTE 2](https://www.ecma-international.org/ecma-262/6.0/#sec-tostring-applied-to-the-number-type) from here on):
    - let `n`, `k` and `s` be integers such that:
      - `k >= 1`
      - `10 ^ (k - 1) <= s <= 10 ^ k`
      - `s * (10 ^ (n - k))` is `m` (or [round-to-even-s](https://en.wikipedia.org/wiki/Rounding#Round_half_to_even) to `m` if it is not precisely representable in a 64 bit float)
      - `k` is as small as possible
      - if there are multiple values for `s`, choose the one for which `s * (10 ^ (n - k))` is closest in value to `m`
      - if there are two such possible values of `s`, choose the one that is even
      - Intuitively, `s` is the integer you get by removing the point ad all trailing zeros from the decimal representation of `m`, `k` is the number of digits in the decimal representation of `s`, and `n` specifies how to print the number: If `n` greater than `0`, there are `n` digits left of the point, else there are `abs(n)` many zeros right of the point. The choice of `s` uniquely determines `k` and `n`, the tricky part is finding a the `s` that rounds correctly and for which `k` is minimal.
    - if `k <= n <= 21`, the encoding is the utf-8 string `<k_decimals><trailing_zeros>`, where `<k_decimals>` is the utf-8 encoding of the digits of the decimal representation of `s`, and `<trailing_zeros` are `n - k` zero digits (`30` in bytes)
    - else if `0 <= n <= 21`, the encoding is the utf-8 string `<pre_point>.<post_point>` (`<pre_point> 2E <post_point>` in bytes), where `<pre_point>` is the utf-8 encoding of the most significant `n` digits of the decimal representation of `s`, and `<post_point>` is the utf-8 encoding of the remaining `k - n` digits of the decimal representation of `s`
    - else if `-6 < n <= 0`, the encoding is the utf-8 string `0.<zeros><k_decimals>` (`30 2E <zeros><k_decimals>` in bytes), where `<zeros>` are `-n` many zero digits (`30` in bytes), and `<k_decimals>` is the utf-8 encoding of the digits of the decimal representation of `s`
    - else if `k == 1`, the encoding is `<base>e<sign><exp>` (`<base> 65 <sign><exp>` in bytes), where `<base>` is the utf-8 encoding of the single digit of `s`, `<sign>` is the utf-8 string `+` (`2B` in bytes) if `n - 1` is positive or the utf-8 string `-` (`2D` in bytes) if `n - 1` is negative, and `<exp>` is the utf-8 encoding of the decimal representation of the absolute value of `n - 1`
    - else, the encoding is the utf-8 string `<pre_point>.<post_point>e<sign><exp>` (`<pre_point> 2E <post_point> 65 <sign><exp>`), where `<pre_point>` is the utf-8 encoding of the most significant digit of the decimal representation of `s`, `<post_point>` is the utf-8 encoding of the remaining `k - 1` digits of the decimal representation of `s`, `<sign>` is the utf-8 string `+` (`2B` in bytes) if `n - 1` is positive or the utf-8 string `-` (`2D` in bytes) if `n - 1` is negative, and `<exp>` is the utf-8 encoding of the decimal representation of the absolute value of `n - 1`

###### Induction Hypotheses

Let `v_0, ..., v_n` be legacy values, and let `e_0(indent), ..., e_n(indent)` be the corresponding encodings using an indentation of `indent` many spaces. Initially, `indent` is `0`.

###### Inductive Step

- An array `[v_0, ..., v_n]` is encoded as follows:
  - if the array is empty (`n == 0`), the encoding is the utf-8 string `[]` (`5B 5D` in bytes)
  - else, do the following:
    - begin with the utf-8 string `[<line feed>` (`5B 0A` in bytes)
    - for each `v_i` in `v_0, ..., v_(n - 1)` (so skip this if `n == 1`):
      - append `indent + 2` many space characters (`20` in bytes)
      - append `e_i(indent + 2)`
      - append the utf-8 string `,<line feed>` (`2C 0A` in bytes)
    - append `indent + 2` many space characters (`20` in bytes)
    - append `e_n(indent + 2)`
    - append the utf-8 string `<line feed>` (`0A` in bytes)
    - append `indent` many space characters (`20` in bytes)
    - append the utf-8 string `]` (`5D` in bytes)
- An object `{ s_0: v_0, ..., s_n: v_n}` is encoded as follows:
  - if the object is empty (`n == 0`), the encoding is the utf-8 string `{}` (`7B 7D` in bytes)
  - else, do the following:
    - begin with the utf-8 string `{<line feed>` (`7B 0A` in bytes)
    - for each pair `(s_i, v_i)` for `i` in `0, ..., n - 1` (so skip this if `n == 1`):
      - append `indent + 2` many space characters (`20` in bytes)
      - append the encoding of the string `s_i`
      - append the utf-8 string `:<space>` (`3A 20` in bytes)
      - append `e_i(indent + 2)`
      - append the utf-8 string `,<line feed>` (`2C 0A` in bytes)
    - append `indent + 2` many space characters (`20` in bytes)
    - append the encoding of the string `s_i`
    - append the utf-8 string `:<space>` (`3A 20` in bytes)
    - append `e_i(indent + 2)`
    - append the utf-8 string `<line feed>` (`0A` in bytes)
    - append `indent` many space characters (`20` in bytes)
    - append the utf-8 string `}` (`7D` in bytes)

The string handling is equivalent to [ECMAScript 2015 QuoteJSONString](https://www.ecma-international.org/ecma-262/6.0/#sec-quotejsonstring), but defined over utf-8 strings instead of utf-16 ones.

The float handling is equivalent to (and quotes from) [ECMAScript 2015 ToString Applied to the Number Type](https://www.ecma-international.org/ecma-262/6.0/#sec-tostring-applied-to-the-number-type), with step 5 replaced as specified in NOTE 2 to result in unique encodings. This spec provides a declarative description of the encoding process, for an algorithmic perspective, there are some papers on the subject such as:

- [Steele Jr, Guy L., and Jon L. White. "How to print floating-point numbers accurately." ACM SIGPLAN Notices. Vol. 25. No. 6. ACM, 1990.](https://lists.nongnu.org/archive/html/gcl-devel/2012-10/pdfkieTlklRzN.pdf)
- [Loitsch, Florian. "Printing floating-point numbers quickly and accurately with integers." ACM Sigplan Notices. Vol. 45. No. 6. ACM, 2010.](https://www.cs.tufts.edu/~nr/cs257/archive/florian-loitsch/printf.pdf)
- [Andrysco, Marc, Ranjit Jhala, and Sorin Lerner. "Printing floating-point numbers: a faster, always correct method." ACM SIGPLAN Notices. Vol. 51. No. 1. ACM, 2016.](https://cseweb.ucsd.edu/~lerner/papers/fp-printing-popl16.pdf)
- [Adams, Ulf. "Ryū: fast float-to-string conversion." Proceedings of the 39th ACM SIGPLAN Conference on Programming Language Design and Implementation. ACM, 2018.](https://dl.acm.org/citation.cfm?id=3192369)

The array and object handling is equivalent to `JSON.stringify(value, null, 2)`, specified in [ECMAScript 2015](https://www.ecma-international.org/ecma-262/6.0/#sec-json.stringify).

#### Hash Computation

To compute the hash of a message, you can not use the signing encoding directly, but the hash computation is based on it. The signing encoding always results in valid unicode. Represent this unicode in [utf-16](https://en.wikipedia.org/wiki/UTF-16). This encoding is a sequence of code units, each consisting of two bytes. The data to hash is obtained from these code units by only keeping the less significant byte.

Example: Suppose you want to compute the hash for `"ß"`, the corresponding utf8 is `[22, C3, 9F, 22]`. In big-endian utf16, this is `[(22, 0), (DF, 0), (22, 0)]`, in little-endian utf16, this is `[(0, 22), (0, DF), (0, 22)]`. In both cases, the sequence of less signifiant bytes per code unit is `[22, DF, 22]`. That is the byte array over which to compute the hash.

Note that this means that two strings with different utf-8 encodings can result in the same hash, due to the information in the more significant byte of the utf-16 encoding being dropped.

#### Length Computation

Ssb places a limit on the size of legacy messages. To compute whether a message is too long, compute the signing encoding (which is always valid unicode), reencode that unicode as utf16, then count the number of code units. This number must be smaller then `16385` (`== 8192 * 2 + 1`), or the message is considered too long (16384 is still ok).

#### JSON Transport Format

In addition to the signing format, legacy messages can be encoded as [ECMA-404 json](https://www.ecma-international.org/publications/files/ECMA-ST/ECMA-404.pdf), with the following differences:

- numbers may not be negative zero
- numbers may not round to positive infinity, negative infinity or negative zero IEEE 754 64 bit floating point numbers
- strings may not be longer than `2^53 - 1` bytes
- arrays and object may not contain more than `2^32 - 1` entries
- objects may not contain multiple entries with the same key
- in strings, unicode escape sequences of code points greater than `U+FFFF` must be interpreted as a single code point, not as an explicit surrogate pair

The signing format itself is a subset of this, but this format can be more compact (by omitting all whitespace). This compact form has been used by the first ssb server implementations for message exchange with other servers.

#### CBOR Encoding of Legacy Data

A much more compact encoding for use in inter-server communication is based upon [CBOR (ietf rfc 7049)](https://tools.ietf.org/html/rfc7049), with the following differences:

- The only allowed major types are:
  - `3` (text string)
  - `4` (array)
  - `5` (map)
  - `7` (primitives)
- no indefinite length strings, arrays or maps (additional type `31` is not allowed)
- the key data items in a map must be text strings (have major type `3`)
- primitives are restricted to the following additional types:
  - `20` (`false`)
  - `21` (`true`)
  - `22` (`null`)
  - `27` (64-bit floats)
