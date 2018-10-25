# Common Datatypes

A few datatypes appear throughout this spec, it makes sense to introduce them in one single place.

An overarching theme of various parts of the ssb protocol(s) is that of future-proofness. The protocol will need to adapt itself to new circumstances, such as new transport channels or broken cryptographic primitives. A simple way to keep flexibility are self-describing multiformats, where the data is prefixed by an identifier (and in some cases its expected length). New data types can be introduced by simply assigning a new identifier. Older software can detect data types it doesn't understand yet, and react accordingly.

Each format consists of some logical data type, and then one or more encodings. These encodings can serve different purposes, for example they might be optimized for machine-readability, human-readability, uniqueness, backwards-compatibility, etc.

## Multikey

A multikey is the public key of some [digital signature](https://en.wikipedia.org/wiki/Digital_signature) scheme, annotated with an identifier for the scheme itself. The only currently supported cryptographic primitive is [ed25519](http://ed25519.cr.yp.to/) (which has a public key length of 32 bytes).

### Multikey Legacy Encoding

The legacy encoding is necessary to keep backwards-compatibility with old ssb data. The encoding of a multikey is defined as the concatenation of:

- the character `@` (`0x40`)
- the [canonic](https://tools.ietf.org/html/rfc4648#section-3.5) base64 encoding of the key itself
  - [ietf rfc 4648, section 4](https://tools.ietf.org/html/rfc4648#section-4), disallowing superflous `=` characters inside the data or after the necessary padding `=`s
- the character `.` (`0x2E`)
- the primitive-specific suffix
  - for ed25519, this is `ed25519` (`[0x65, 0x64, 0x32, 0x35, 0x35, 0x31, 0x39]`)

Typically, this encoding is stored in a json string.

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
- the character `.` (`0x2E`)
- the primitive-specific suffix
  - for sha256, this is `sha256` (`[0x73, 0x68, 0x61, 0x32, 0x35, 0x36]`)

Typically, this encoding is stored in a json string.

## Multibox

A multibox is a cyphertext, annotated with an identifier for the algorithm that produced it. The only currently supported algorithm is [private-box](https://ssbc.github.io/scuttlebutt-protocol-guide/#private-messages).

### Multibox Legacy Encoding

The legacy encoding is necessary to keep backwards-compatibility with old ssb data. The encoding of a multibox is defined as the concatenation of:

- the [canonic](https://tools.ietf.org/html/rfc4648#section-3.5) base64 encoding of the cyphertext
  - [ietf rfc 4648, section 4](https://tools.ietf.org/html/rfc4648#section-4), disallowing superflous `=`
- the characters `.box` (`[0x2E, 0x62, 0x6F, 0x78]`)
- an algorithm-specific suffix, which may not contain the quote character `"` (`0x22`)
  - for secret-box, this is the empty string

Typically, this encoding is stored in a json string.
