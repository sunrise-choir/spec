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

The `type` is an unsigned 64 bit integer, encoded as a [VarU64](https://github.com/AljoschaMeyer/varu64-rs). If `type` is `128` or more, it is followed by another VarU64 encoding the `length`. If `type` is less than `128`, the value of `length` is computed as `2 ^ (type >> 3)`. In both cases, the remainder of the encoding consists of `length` many bytes of payload (the `value`).

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

## Multihash

A multihash is the hash digest of some [cryptographically secure hash function](https://en.wikipedia.org/wiki/Cryptographic_hash_function), annotated with an identifier for the hash function itself. The only currently supported cryptographic primitive is [sha256](https://en.wikipedia.org/wiki/SHA-2) (which has a digest length of 32 bytes).

### Multihash Legacy Encoding

The legacy encoding is necessary to keep backwards-compatibility with old ssb data. The encoding of a multihash is defined as the concatenation of:

- either the character `%` (`0x25`) or the character `&` (`0x26`)
  - this is sometimes used to distinguish between messages and blobs:
    - the encoding using `%` is called a (legacy) message (multi)hash
    - the encoding using `&` is called a (legacy) blob (multi)hash
- the [canonic](https://tools.ietf.org/html/rfc4648#section-3.5) base64 encoding of the digest itself
  - [ietf rfc 4648, section 4](https://tools.ietf.org/html/rfc4648#section-4), disallowing superflous `=` characters inside the data or after the necessary padding `=`s
  - it may not omit `=` characters either - the amount of encoding bytes must always be a multiple of four
- the character `.` (`0x2E`)
- the primitive-specific suffix
  - for sha256, this is `sha256` (`[0x73, 0x68, 0x61, 0x32, 0x35, 0x36]`)

Typically, this encoding is stored in a json string.

### Multihash Compact Encoding

The compact encoding of a multihash is a [binary ctlv encoding](#ctlv-binary-encoding), where the `value` is the raw byte array of the hash, and the type is taken from the following table:

| Cryptographic Primitive | Blob? | Type |
|-------------------------|-------|------|
| sha256                  | no    | 40   |
| sha256                  | yes   | 41   |

## Multibox

A multibox is a cyphertext, annotated with an identifier for the algorithm that produced it. The only currently supported algorithm is [private-box](https://ssbc.github.io/scuttlebutt-protocol-guide/#private-messages).

### Multibox Legacy Encoding

The legacy encoding is necessary to keep backwards-compatibility with old ssb data. The encoding of a multibox is defined as the concatenation of:

- the [canonic](https://tools.ietf.org/html/rfc4648#section-3.5) base64 encoding of the cyphertext
  - [ietf rfc 4648, section 4](https://tools.ietf.org/html/rfc4648#section-4), disallowing superflous `=`
  - it may not omit `=` characters either - the amount of encoding bytes must always be a multiple of four
- the characters `.box` (`[0x2E, 0x62, 0x6F, 0x78]`)
- an algorithm-specific suffix, which may not contain the quote character `"` (`0x22`)
  - for secret-box, this is the empty string

Typically, this encoding is stored in a json string.

**This definition might still change**: %EwwjtvHK7i1MFXnazWTjivGEhdAymQd0xR+BU82XpdM=.sha256

### Multibox Compact Encoding

Depends on %EwwjtvHK7i1MFXnazWTjivGEhdAymQd0xR+BU82XpdM=.sha256
