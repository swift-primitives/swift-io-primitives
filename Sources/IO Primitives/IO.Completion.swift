// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives
// project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

#if !hasFeature(Embedded)

    extension IO {

        /// A single-owner acknowledgement of physical operation completion.
        ///
        /// A completion acknowledgement carries no result. It exists so an
        /// orderly release path can wait until the operation no longer accesses
        /// its resources without becoming a second consumer of the operation's
        /// output.
        ///
        /// The acknowledgement is linear: consume it with wait() exactly once.
        /// Dropping it without waiting is a programmer error because doing so
        /// would permit resource release without proof of physical completion.
        ///
        /// ## Safety Invariant
        ///
        /// The acknowledgement privately owns a safe async closure. Its
        /// `~Copyable` and consuming interface prevent concurrent or repeated
        /// access to that closure, and no unsafe operation is performed.
        @safe
        public struct Completion: ~Copyable {

            private var wait: (() async -> Void)?

            package init(wait: consuming @escaping () async -> Void) {
                self.wait = wait
            }

            deinit {
                guard case .none = wait else {
                    preconditionFailure(
                        "An IO operation completion acknowledgement must be awaited."
                    )
                }
            }
        }
    }

    extension IO.Completion {

        /// Waits until the operation has physically completed.
        ///
        /// This acknowledgement never owns, stores, or returns the operation
        /// result.
        public consuming func wait() async {
            guard let wait = self.wait.take() else {
                preconditionFailure(
                    "An IO operation completion acknowledgement may be awaited only once."
                )
            }
            await wait()
        }
    }

#endif
