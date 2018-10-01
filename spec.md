# Secure Scuttlebutt Specification

Secure Scuttlebutt is a bla... TODO High level overview goes here.

## Feeds and Messages

TODO General description of sigchains, how they are constructed and why ssb relies on that particular data structure.

TODO General introduction to free form messages. Differences between abstract data model, signing encodings, transport encodings and database encodings (but stress that db encodings can be freely chosen and are not part of the protocol - in-memory implementations (including pure client-side implementations) don't even need them).

### Legacy Messages

This section describes the message format that was originally used for ssb. The protocol has since moved on, everything here should be considered deprecated. But for backwards compatibility, ssb servers still need to understand, verify and relay old messages.

Legacy messages have been deprecated, because their design emerged organically through reliance on the default behavior of certain features of [node js](https://nodejs.org/en/). People (including the authors of this specification) have called the legacy message format "bizarre" and worse, and that is entirely justified. But when during reading you inevitably thing "How could anybody end up with this, I could have done a much better job.", then remember: Maybe you could have, but you didn't.
