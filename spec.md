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
