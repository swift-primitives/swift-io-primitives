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

        /// A single-owner asynchronous IO operation.
        ///
        /// Operation transfers one Output or throws its exact Failure. It never
        /// requires Output to be Sendable: consuming the operation transfers
        /// the output's region to the caller.
        ///
        /// ## Lifecycle laws
        ///
        /// - **One terminal owner:** result() consumes the operation, so no
        ///   second caller can wait for or observe the result.
        /// - **Cancellation before waiting:** a copied cancellation endpoint may
        ///   request cancellation before the operation is consumed.
        /// - **Cancellation while waiting:** another endpoint copy may request
        ///   cancellation concurrently with result().
        /// - **Completion before cancellation:** cancellation remains an
        ///   idempotent request after physical completion and cannot create a
        ///   second terminal result.
        /// - **Drop without waiting:** dropping a live operation requests
        ///   cancellation synchronously. The separately returned Completion
        ///   must still be consumed before its release path frees resources.
        /// - **Physical completion:** Cancellation alone is insufficient
        ///   evidence for release. Only consuming Completion.wait() provides
        ///   the result-free acknowledgement.
        ///
        /// ## Safety Invariant
        ///
        /// The operation privately owns its safe result closure. Its
        /// `~Copyable` and consuming interface prevent concurrent or repeated
        /// access to that closure, and dropping a live operation invokes only
        /// the safe cancellation endpoint.
        @safe
        public struct Operation<Output: ~Copyable, Failure: Swift.Error>: ~Copyable {

            /// The independently reachable cancellation request.
            public let cancellation: Cancellation

            private var wait: (() async throws(Failure) -> sending Output)?

            private init(
                cancellation: Cancellation,
                wait: consuming @escaping () async throws(Failure) -> sending Output
            ) {
                self.cancellation = cancellation
                self.wait = wait
            }

            deinit {
                guard case .some = wait else {
                    return
                }
                cancellation.cancel()
            }
        }
    }

    extension IO.Operation {

        /// Creates a live operation and its result-free completion
        /// acknowledgement.
        ///
        /// The result closure is privately owned by the returned operation. The
        /// completion closure is privately owned by the returned acknowledgement.
        /// Neither closure is concurrently reusable, and the acknowledgement has
        /// no path to Output.
        public static func start(
            cancellation: IO<Capabilities>.Cancellation,
            result: consuming @escaping () async throws(Failure) -> sending Output,
            completion: consuming @escaping () async -> Void
        ) -> (
            operation: IO<Capabilities>.Operation<Output, Failure>,
            completion: IO<Capabilities>.Completion
        ) {
            (
                operation: .init(
                    cancellation: cancellation,
                    wait: result
                ),
                completion: .init(wait: completion)
            )
        }

        /// Waits for and transfers the operation's single result.
        ///
        /// The operation is consumed whether the closure returns or throws. Its
        /// separately owned completion acknowledgement remains the only path by
        /// which an orderly release owner can prove physical completion.
        public consuming func result() async throws(Failure) -> sending Output {
            guard let wait = self.wait.take() else {
                preconditionFailure("An IO operation may be awaited only once.")
            }
            return try await wait()
        }
    }

#endif
