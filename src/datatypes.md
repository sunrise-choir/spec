# Common Datatypes

A few datatypes appear throughout this spec, it makes sense to introduce them in one single place.

An overarching theme of various parts of the ssb protocol(s) is that of future-proofness. The protocol will need to adapt itself to new circumstances, such as new transport channels or broken cryptographic primitives. A simple way to keep flexibility are self-describing multiformats, where the data is prefixed by an identifier (and in some cases its expected length). New data types can be introduced by simply assigning a new identifier. Older software can detect data types it doesn't understand yet, and react accordingly.

Each format consists of some logical data type, and then one or more encodings. These encodings can serve different purposes, for example they might be optimized for machine-readability, human-readability, uniqueness, backwards-compatibility, etc.

## VarU64

A VarU64 is an unsigned 64 bit integer (a natural number between 0 and 2^64 - 1 inclusive), to be stored in a variable-length encoding.

### VarU64 Binary Encoding

The binary encoding of a VarU64 is easiest defined by giving the decoding process:

To decode a VarU64, look at the first byte. If its value is below 248, the value itself is the encoded number. Else, the first byte determines the further `length` of the encoding:

| first byte | number of additional bytes |
|------------|----------------------------|
| 248 | 1 |
| 249 | 2 |
| 250 | 3 |
| 251 | 4 |
| 252 | 5 |
| 253 | 6 |
| 254 | 7 |
| 255 | 8 |

Following the first byte are `length` many bytes. These bytes are the big-endian representation of the encoded number.

Of all possible representations for a number that this scheme admits, the shortest one is its unique, valid encoding. Decoders must indicate an error if a value uses an encoding that is longer than necessary.

Further information on the VarU64 format can be found [here](https://github.com/AljoschaMeyer/varu64-rs).

## CTLV

A *compact type-length-value* encoding. A ctlv consists of a `type` (unsigned 64 bit integer), a `length` (unsigned 64 bit integer), and a `value` (a sequence of `length` many bytes).

### CTLV Binary Encoding

The binary encodings is the concatenation of an encoding of the type, an encoding of the length (sometimes omitted) and the raw bytes of the value.

The `type` is an unsigned 64 bit integer, encoded as a [VarU64](#varu64-binary-encoding). If `type` is `128` or more, it is followed by another VarU64 encoding the `length`. If `type` is less than `128`, the value of `length` is computed as `2 ^ (type >> 3)`. In both cases, the remainder of the encoding consists of `length` many bytes of payload (the `value`).

Further information on the ctlv format can be found [here](https://github.com/AljoschaMeyer/ctlv).

## Multikey

A multikey is the public key of some [digital signature](https://en.wikipedia.org/wiki/Digital_signature) scheme, annotated with an identifier for the scheme itself. The only currently supported cryptographic primitive is [ed25519](http://ed25519.cr.yp.to/) (which has a public key length of 32 bytes).

### Multikey Legacy Encoding

The legacy encoding is necessary to keep backwards-compatibility with old ssb data. The encoding of a multikey is defined as the concatenation of:

- the character `@` (`0x40`)
- the [canonic](https://tools.ietf.org/html/rfc4648#section-3.5) base64 encoding of the key itself
  - [ietf rfc 4648, section 4](https://tools.ietf.org/html/rfc4648#section-4), disallowing superflous `=` characters inside the data or after the necessary padding `=`s
  - it may not omit `=` characters either - the amount of encoding bytes must always be a multiple of four
- the character `.` (`0x2E`)
- the primitive-specific suffix
  - for ed25519, this is `ed25519` (`[0x65, 0x64, 0x32, 0x35, 0x35, 0x31, 0x39]`)

Typically, this encoding is stored in a json string.

### Multikey Compact Encoding

The compact encoding of a multikey is a [binary ctlv encoding](#ctlv-binary-encoding), where the `value` is the raw byte array of the key, and the type is taken from the following table:

| Cryptographic Primitive | Type |
|-------------------------|------|
| ed25519                 | 40   |

## Multifeed

A multifeed represents a scuttlebutt feed. It consists of a feed kind indicator and some additional data depending on the feed kind. The only currently supported feed kind is `multikey`, whose additional data surprisingly enough is a multikey.

### Multifeed Legacy Encoding

The legacy encoding of a multikey multifeed is the same as the legacy encoding of the multikey. The legacy encoding of possible future multifeed kinds will use a different first char than `@`.

### Multifeed Compact Encoding

The compact encoding of a multihash is a [VarU64](#varu64-binary-encoding) indicating the feed kind, followed by a [binary ctlv encoding](#ctlv-binary-encoding) for the kind-specific data.

The VarU64 for the feed kind is taken from the following table:

| Feed Kind | Int |
|-----------|-----|
| multikey  | 0   |

For the `multikey` feed kind, the kind-specific data is simply the compact encoding of the multikey.

## Multihash

A multihash is a pair of:

- the hash target
- the hash digest of some [cryptographically secure hash function](https://en.wikipedia.org/wiki/Cryptographic_hash_function), annotated with an identifier for the hash function itself.

The only currently supported hash targets are `Message` and `Blob`

The only currently supported cryptographic primitive is [sha256](https://en.wikipedia.org/wiki/SHA-2) (which has a digest length of 32 bytes).

### Multihash Legacy Encoding

The legacy encoding is necessary to keep backwards-compatibility with old ssb data. The encoding of a multihash is defined as the concatenation of:

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

### Multihash Compact Encoding

The compact encoding of a multihash is a [VarU64](#varu64-binary-encoding) indicating the hash target, followed by a [binary ctlv encoding](#ctlv-binary-encoding) for the digest, where the `value` is the raw byte array of the hash, and the type is taken from the following table:

| Cryptographic Primitive | Type |
|-------------------------|------|
| sha256                  | 40   |

The VarU64 for the hash target is taken from the following table:

| Hash Target | Int |
|-------------|-----|
| Message     | 0   |
| Blob        | 1   |

## Multibox

A multibox is a cyphertext, annotated with an identifier for the algorithm that produced it. The algorithm identifiers are natural numbers between 0 and 2^64 - 1 (inclusive). Even identifiers are reserved for assignment by the ssb protocol devs, odd identifiers are open for experimentation and/or custom usage.

The only currently specified algorithm is [private-box](https://ssbc.github.io/scuttlebutt-protocol-guide/#private-messages), using the identifier 0.

### Multibox Legacy Encoding

The legacy encoding is necessary to keep backwards-compatibility with old ssb data. The encoding of a multibox is defined as the concatenation of:

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

### Multibox Compact Encoding

The compact encoding of a multiboxh is the [VarU64](#varu64-binary-encoding) binary encoding of the algorithm identifier, followed by a [VarU64](#varu64-binary-encoding) indicating the remaining length, followed by that many bytes of data.

For multibox, the remaining data is simply the cyphertext (*not* base64 encoded).
