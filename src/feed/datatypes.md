# Common Datatypes

A few datatypes appear throughout this spec, it makes sense to introduce them in one single place.

An overarching theme of various parts of the ssb protocol(s) is that of future-proofness. The protocol will need to adapt itself to new circumstances, such as new transport channels or broken cryptographic primitives. A simple way to keep flexibility are self-describing multiformats, where the data is prefixed by an identifier (and in some cases its expected length). New data types can be introduced by simply assigning a new identifier. Older software can detect data types it doesn't understand yet, and react accordingly.

Each format consists of some logical data type, and then one or more encodings. These encodings can serve different purposes, for example they might be optimized for machine-readability, human-readability, uniqueness, backwards-compatibility, etc.

## Multikey

A multikey is the public key of some [digital signature](https://en.wikipedia.org/wiki/Digital_signature) scheme, annotated with an identifier for the scheme itself. The only currently supported cryptographic primitive is [ed25519](http://ed25519.cr.yp.to/) (which has a public key length of 32 bytes).

### Multikey Encoding

The encoding of a multikey is defined as the concatenation of:

- the character `@` (`0x40`)
- the [canonic](https://tools.ietf.org/html/rfc4648#section-3.5) base64 encoding of the key itself
  - [ietf rfc 4648, section 4](https://tools.ietf.org/html/rfc4648#section-4), disallowing superflous `=` characters inside the data or after the necessary padding `=`s
  - it may not omit `=` characters either - the amount of encoding bytes must always be a multiple of four
- the character `.` (`0x2E`)
- the primitive-specific suffix
  - for ed25519, this is `ed25519` (`[0x65, 0x64, 0x32, 0x35, 0x35, 0x31, 0x39]`)

Typically, this encoding is stored in a json string.

## Multifeed

A multifeed represents a scuttlebutt feed. It consists of a feed kind indicator and some additional data depending on the feed kind. The only currently supported feed kind is `multikey`, whose additional data surprisingly enough is a multikey.

### Multifeed Encoding

The encoding of a multikey multifeed is the same as the encoding of the multikey. The encoding of possible future multifeed kinds will use a different first char than `@`.

## Multihash

A multihash is a pair of:

- the hash target
- the hash digest of some [cryptographically secure hash function](https://en.wikipedia.org/wiki/Cryptographic_hash_function), annotated with an identifier for the hash function itself.

The only currently supported hash targets are `Message` and `Blob`

The only currently supported cryptographic primitive is [sha256](https://en.wikipedia.org/wiki/SHA-2) (which has a digest length of 32 bytes).

### Multihash Encoding

The encoding of a multihash is defined as the concatenation of:

- depending on the hash target:
  - `Message`: the character `%` (`0x25`)
  - `Blob`: the character `&` (`0x26`)
- the [canonic](https://tools.ietf.org/html/rfc4648#section-3.5) base64 encoding of the digest itself
  - [ietf rfc 4648, section 4](https://tools.ietf.org/html/rfc4648#section-4), disallowing superflous `=` characters inside the data or after the necessary padding `=`s
  - it may not omit `=` characters either - the amount of encoding bytes must always be a multiple of four
- the character `.` (`0x2E`)
- the primitive-specific suffix
  - for sha256, this is `sha256` (`[0x73, 0x68, 0x61, 0x32, 0x35, 0x36]`)

Typically, this encoding is stored in a json string.

## Multibox

A multibox is a cyphertext, annotated with an identifier for the algorithm that produced it. The algorithm identifiers are natural numbers between 0 and 2^64 - 1 (inclusive). Even identifiers are reserved for assignment by the ssb protocol devs, odd identifiers are open for experimentation and/or custom usage.

The only currently specified algorithm is [private-box](https://ssbc.github.io/scuttlebutt-protocol-guide/#private-messages), using the identifier 0.

### Multibox Encoding

The encoding of a multibox is defined as the concatenation of:

- the [canonic](https://tools.ietf.org/html/rfc4648#section-3.5) base64 encoding of the cyphertext
  - [ietf rfc 4648, section 4](https://tools.ietf.org/html/rfc4648#section-4), disallowing superflous `=`
  - it may not omit `=` characters either - the amount of encoding bytes must always be a multiple of four
- the characters `.box` (`[0x2E, 0x62, 0x6F, 0x78]`)
- the uppercase [base32](https://tools.ietf.org/html/rfc4648#section-6) encoding without padding of the identifier, without leading zeros, using the following table (the canonic subset of [Crockford's base32](http://www.crockford.com/wrmg/base32.html)):

| Value | Symbol |
|-------|--------|
| 0     | 0      |
| 1     | 1      |
| 2     | 2      |
| 3     | 3      |
| 4     | 4      |
| 5     | 5      |
| 6     | 6      |
| 7     | 7      |
| 8     | 8      |
| 9     | 9      |
| 10    | A      |
| 11    | B      |
| 12    | C      |
| 13    | D      |
| 14    | E      |
| 15    | F      |
| 16    | G      |
| 17    | H      |
| 18    | J      |
| 19    | K      |
| 20    | M      |
| 21    | N      |
| 22    | P      |
| 23    | Q      |
| 24    | R      |
| 25    | S      |
| 26    | T      |
| 27    | V      |
| 28    | W      |
| 29    | X      |
| 30    | Y      |
| 31    | Z      |

Due to omitting leading zeros, the suffix for private box (identifier 0) is simply `"box"`.

For large identifiers (between 2^60 and 2^64 - 1 inclusive), 13 characters are needed, and the most-significant bit of the leftmost character does not contribute to the decoded value. Identifiers must be encoded such that this ignored bit is set to zero. Put another way: If the identifier encoding takes up 13 characters, it must begin with one of `(1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F)`.
