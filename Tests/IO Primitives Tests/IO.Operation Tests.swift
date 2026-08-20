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

import IO_Primitives
import Testing

@Suite("IO operation source laws")
private struct OperationTest {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}

    enum Capabilities: Sendable {}

    enum Failure: Swift.Error {
        case expected
    }

    struct Output: ~Copyable {
        let value: Int
    }

    final class Region {
        let value: Int

        init(value: Int) {
            self.value = value
        }
    }
}

extension OperationTest.Unit {

    @Test("move-only output crosses the consuming result boundary")
    func moveOnlyOutput() async throws(OperationTest.Failure) {
        let (operation, completion) =
            IO<OperationTest.Capabilities>.Operation<
                OperationTest.Output,
                OperationTest.Failure
            >.start(
                cancellation: .init {},
                result: { OperationTest.Output(value: 42) },
                completion: {}
            )

        let output = try await operation.result()
        let value = output.value
        await completion.wait()

        #expect(value == 42)
    }

    @Test("cancellation is independently reachable before result wait")
    func independentCancellation() async throws(OperationTest.Failure) {
        let (operation, completion) =
            IO<OperationTest.Capabilities>.Operation<
                OperationTest.Output,
                OperationTest.Failure
            >.start(
                cancellation: .init {},
                result: { OperationTest.Output(value: 1) },
                completion: {}
            )

        let cancellation = operation.cancellation
        cancellation.cancel()
        let output = try await operation.result()
        let value = output.value
        await completion.wait()

        #expect(value == 1)
    }

    @Test("completion acknowledgement carries no result")
    func resultFreeCompletion() async throws(OperationTest.Failure) {
        let (operation, completion) =
            IO<OperationTest.Capabilities>.Operation<
                OperationTest.Output,
                OperationTest.Failure
            >.start(
                cancellation: .init {},
                result: { OperationTest.Output(value: 7) },
                completion: {}
            )

        await completion.wait()
        operation.cancellation.cancel()
        let output = try await operation.result()
        let value = output.value

        #expect(value == 7)
    }

    @Test("sending capture transfers without a Sendable requirement")
    func sendingCapture() async throws(OperationTest.Failure) {
        let region = OperationTest.Region(value: 9)
        let (operation, completion) = operation(capturing: region)

        let value = try await operation.result()
        await completion.wait()

        #expect(value == 9)
    }

    private func operation(
        capturing region: sending OperationTest.Region
    ) -> (
        operation: IO<OperationTest.Capabilities>.Operation<Int, OperationTest.Failure>,
        completion: IO<OperationTest.Capabilities>.Completion
    ) {
        IO<OperationTest.Capabilities>.Operation<Int, OperationTest.Failure>.start(
            cancellation: .init {},
            result: { region.value },
            completion: {}
        )
    }
}

// MARK: - Rejected source laws
//
// These deliberately non-compiling forms stay as source fixtures. Uncommenting
// any block must be rejected by ownership checking.
//
// Reusing an operation is rejected because the first result() consumes it:
//
// let first = try await operation.result()
// let second = try await operation.result()
//
// Sharing the move-only output is rejected:
//
// let output = try await operation.result()
// consumeFirst(consume output)
// consumeSecond(consume output)
//
// Capturing the operation in a concurrently reusable closure is rejected:
//
// let shared: @Sendable () async -> Void = {
//     _ = try? await operation.result()
// }
//
// No closure other than Cancellation's action carries @Sendable. The result
// and completion closures are privately transferred to their linear owners.
