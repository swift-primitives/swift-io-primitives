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

        /// An independently reachable request to cancel an operation.
        ///
        /// Cancellation is a request, not proof of physical completion. Use the
        /// operation's accompanying Completion acknowledgement before releasing
        /// resources that the operation may still access.
        ///
        /// This endpoint is copyable because an operation owner and a release
        /// path may both need to request cancellation. Its action is the only
        /// concurrently reusable closure in the operation lifecycle algebra.
        ///
        /// ## Safety Invariant
        ///
        /// The endpoint stores only a `@Sendable` closure and invokes it without
        /// any unsafe operation. The supplier's idempotence requirement governs
        /// lifecycle behavior, not memory safety.
        @safe
        public struct Cancellation: Sendable {

            // swift-linter:disable:next sendable sharing requirement
            // REASON: CATEGORY: concurrent-cancellation; SHARING: copies of this endpoint may be invoked independently by the operation owner and an orderly release path.
            private let action: @Sendable () -> Void

            /// Creates an endpoint around an idempotent cancellation request.
            // swift-linter:disable:next sendable sharing requirement
            // REASON: CATEGORY: concurrent-cancellation; SHARING: the supplied action becomes the independently invocable action shared by every endpoint copy.
            public init(action: @escaping @Sendable () -> Void) {
                self.action = action
            }
        }
    }

    extension IO.Cancellation {

        /// Requests cancellation.
        ///
        /// The action must be idempotent. A return from this method does not
        /// mean the operation has physically completed.
        public func cancel() {
            action()
        }
    }

#endif
