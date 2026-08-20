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

    /// A strategy capable of starting generic single-owner IO operations.
    ///
    /// This is a pure capability protocol rather than a protocol nested under
    /// generic IO. One conformer can therefore start operations for multiple
    /// capability sets while preserving their exact result and failure types.
    ///
    /// The borrowed resource exists only for construction. Because this method
    /// returns escaping operation owners, a conformer must not retain or capture
    /// that borrow. Before returning, it establishes any separately owned
    /// execution resource its strategy needs. How it establishes that ownership
    /// is deliberately outside this generic law.
    public protocol Startable<Resource, Interest>: ~Copyable {

        /// The resource borrowed while the strategy creates operation owners.
        associatedtype Resource: ~Copyable

        /// Strategy-specific selection data for the operation.
        associatedtype Interest

        /// A failure before operation owners exist.
        associatedtype StartFailure: Swift.Error

        /// A failure while the strategy executes or physically completes work.
        associatedtype ExecutionFailure: Swift.Error

        /// Starts one operation and returns its two linear owners.
        ///
        /// The caller operation is transferred once and is not concurrently
        /// reusable. Resource, Output, and the operation closure do not require
        /// Sendable conformance. Cancellation remains the sole independently
        /// concurrent endpoint of the returned lifecycle.
        ///
        /// A thrown StartFailure means no owners were created. After this method
        /// returns, result failure distinguishes strategy execution from the
        /// caller operation through IO.Failure.
        func start<
            Capabilities: Sendable,
            Output: ~Copyable,
            Failure: Swift.Error
        >(
            borrowing resource: borrowing Resource,
            interest: Interest,
            operation: sending @escaping (
                borrowing Resource
            ) throws(Failure) -> sending Output
        ) async throws(StartFailure) -> sending (
            operation: IO<Capabilities>.Operation<
                Output,
                IO<Capabilities>.Failure<ExecutionFailure, Failure>
            >,
            completion: IO<Capabilities>.Completion
        )
    }

#endif
