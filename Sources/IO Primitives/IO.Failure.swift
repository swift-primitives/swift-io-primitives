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

        /// A terminal failure after an operation's owners have been created.
        ///
        /// Start failures are not represented here. They are thrown before an
        /// operation and completion acknowledgement exist. This sum preserves
        /// whether later failure came from strategy execution or from the
        /// caller-supplied operation.
        public enum Failure<
            Execution: Swift.Error,
            Operation: Swift.Error
        >: Swift.Error {

            /// The strategy could not execute or physically complete the work.
            case strategy(Execution)

            /// The caller-supplied operation failed.
            case operation(Operation)
        }
    }

#endif
