# Introduction

TODO (mw) re-write this.

This document is the specification of the [secure-scuttlebutt]((https://www.scuttlebutt.nz/)) protocol (ssb). The primary audience are developers who need a thorough understanding of protocol internals, for example because they want to implement it themselves. The specificaiton is not intended for developers who want to build applications on top of ssb. Ssb provides nice abstractions to those developer, hiding the nitty-gritty details. This spec however is all about those details.

It is possible to read through the spec from end to end, but it's not an easy read. It is structured into different sections, each dealing with a different aspect of the protocol. The sections begin with a high-level overview of the problem space, and then delve into the details. In the description of those details, the highest importance is given to unambiguity. If you can not tell *exactly* how something works, it is a bug in the spec.

<!-- TODO add links to test data and rust reference impl -->
