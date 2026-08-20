# IO operation source laws

These fixtures record compile-time ownership and region laws. They are
documentation inputs, not an executable test target.

- positive-move-only-output.swift.fixture records transfer of a move-only
  result.
- positive-sending-capture.swift.fixture records transfer of a non-Sendable
  capture into the privately owned one-shot result closure.
- positive-start.swift.fixture records the generic strategy-start requirement,
  exact pre-owner failure, and returned linear owners.
- positive-start-nonsendable.swift.fixture records a non-Sendable resource,
  non-Sendable operation capture, and move-only output without constraint
  escalation.
- positive-failure-sum.swift.fixture records exhaustive post-owner strategy
  execution versus caller-operation failure.
- negative-repeat-wait.swift.fixture records that the result wait consumes its
  operation.
- negative-share-result.swift.fixture records that the move-only result cannot
  be given to two consumers.
- negative-sendable-operation.swift.fixture records that the operation is not a
  concurrently reusable closure capture.
- negative-retain-borrow.swift.fixture records that an escaping owner cannot
  retain the caller's borrowed resource.

The executable lifecycle fixtures record cancellation before waiting and
physical completion before cancellation. The public lifecycle article states
the cancellation-during-wait and drop-without-wait laws because their concrete
scheduling mechanics belong to the strategy that supplies the closures.
