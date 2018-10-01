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

Assume `v_1, ..., v_n` are legacy values

###### Inductive Step

- An ordered sequence `[v_1, ..., v_n]` where `n <= 2^32 - 1`, is a legacy value, called an *array*
- An unordered set of at most `2^32 - 1` pairs of strings `s_i` (called *keys*) and legacy values `v_i` (called *values*), where all `s_i, s_j` are pairwise distinct, is a legacy value (called an *object*, written `{ "foo": v_1, "bar": v_2}`, the empty object is written as `{}`)

#### Signing Encoding
TODO

#### Hash Computation

To compute the hash of a message, you can not use the signing encoding, but the hash computation is based on it. The signing encoding always results in valid unicode. Represent this unicode in [utf-16](https://en.wikipedia.org/wiki/UTF-16). This encoding is a sequence of code units, each consisting of two bytes. The data to hash is obtained from these code units by only keeping the less significant byte.

Example: Suppose you want to compute the hash for `"ß"`, the corresponding utf8 is `[22, C3, 9F, 22]`. In big-endian utf16, this is `[(22, 0), (DF, 0), (22, 0)]`, in little-endian utf16, this is `[(0, 22), (0, DF), (0, 22)]`. In both cases, the sequence of less signifiant bytes per code unit is `[22, DF, 22]`. That is the byte array over which to compute the hash.

Note that this means that two strings with different utf-8 encodings can result in the same hash, due to the information in the more significant byte of the utf-16 encoding being dropped.

#### Length Computation

Ssb places a limit on the size of legacy messages. To compute whether a message is too long, compute the signing format (which is always valid unicode), encode that unicode as utf16, then count the number of code units. This number must be smaller then `16385` (`== 8192 * 2 + 1`), or the message is considered too long (16384 is still ok).

#### Transport Format

I'm not going to specify this. The transport format can currently be arbitrary json, including stuff that is ruled out for the signing format due to canonicty requirements. There'll be a few breaking changes to the server-to-server rpc protocol anyways (muxrpc, plugin architecture), so I'd strongly prefer to take that opportunity to remove the ability to send json in an arbitrary way.
