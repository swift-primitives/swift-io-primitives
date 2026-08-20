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

// `UnownedSerialExecutor` and `async` closures live in `_Concurrency`, which is
// unavailable in Embedded Swift.
#if !hasFeature(Embedded)

    extension IO {

        /// The scheduling evidence carried alongside an ``IO`` bundle.
        ///
        /// A ``Runner`` exposes the executor the bundle is pinned to and a
        /// shutdown hook for releasing the underlying OS resources. It is
        /// produced by a strategy (blocking thread pool, kernel readiness
        /// reactor, kernel completion queue) at construction time and
        /// passed into the ``IO`` initializer.
        ///
        /// ## Why the runner is separate from capabilities
        ///
        /// Capabilities describe *what* operations exist; the runner
        /// describes *where* they run. Separating the two lets one strategy
        /// implementation (for example the blocking thread pool) back
        /// capability sets from many different domains — the strategy
        /// does not need to know whether it is dispatching file I/O,
        /// socket I/O, or timer I/O.
        ///
        /// ## TCA26 shared-executor pattern
        ///
        /// Consumer actors should forward their `unownedExecutor` to the
        /// runner's executor so that per-operation calls do not incur an
        /// executor hop:
        ///
        /// ```swift
        /// actor Worker {
        ///     let io: IO<Socket.Capabilities>
        ///     nonisolated var unownedExecutor: UnownedSerialExecutor {
        ///         io.runner.executor()
        ///     }
        /// }
        /// ```
        ///
        /// ## Phantom generic parameter
        ///
        /// Because ``IO`` is generic, ``Runner`` nested inside it technically
        /// carries the ``Capabilities`` parameter even though its storage
        /// does not depend on it. In practice the parameter is inferred from
        /// the surrounding construction site — strategies construct runners
        /// inside per-(domain × strategy) factories where the domain's
        /// ``Capabilities`` type is already named.
        ///
        /// ## Unsafe executor seam
        ///
        /// The executor closure deliberately returns an
        /// `UnownedSerialExecutor`. The strategy that creates the runner must
        /// keep the executor alive while the runner or any consumer actor can
        /// use that unowned reference. ``Runner`` cannot enforce that lifetime,
        /// so it is not an `@safe` boundary.
        public struct Runner: Sendable {

            /// The underlying serial executor the ``IO`` is pinned to.
            ///
            /// A `@Sendable` closure rather than a stored `UnownedSerialExecutor`
            /// so the runner can lazily resolve the executor if the backing
            /// actor is constructed asynchronously.
            public let executor: @Sendable () -> UnownedSerialExecutor

            /// Release the runner's OS resources (joins the polling thread,
            /// tears down the kernel handle, drains pending submissions,
            /// etc., as appropriate for the strategy that produced it).
            ///
            /// Idempotent by convention: calling shutdown after shutdown is
            /// a no-op. Concrete strategies are responsible for upholding
            /// this contract.
            public let shutdown: @Sendable () async -> Void

            /// Creates a runner from the two closures a strategy supplies.
            public init(
                executor: @Sendable @escaping () -> UnownedSerialExecutor,
                shutdown: @Sendable @escaping () async -> Void
            ) {
                unsafe self.executor = executor
                self.shutdown = shutdown
            }
        }
    }

#endif
