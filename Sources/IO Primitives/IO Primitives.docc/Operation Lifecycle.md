# Single-owner operation lifecycle

An IO operation separates result ownership, cancellation requests, and physical
completion.

Use IO.Operation as the sole result owner. Calling result() consumes the
operation and transfers its output to the caller, so the output does not need
to conform to Sendable. Exact typed failure is preserved.

The operation exposes a copyable IO.Cancellation endpoint. Cancellation is an
idempotent request that may be made before the result wait, while it is
suspended, or after physical completion. Returning from cancel() is never proof
that the work has stopped.

Operation.start(cancellation:result:completion:) also returns a linear
IO.Completion acknowledgement. Give that acknowledgement to the owner that
must release resources. It carries no output and therefore cannot become a
second result consumer. That owner must consume wait() before releasing
anything the operation may still access.

Dropping an operation without calling result() requests cancellation
synchronously. Synchronous destruction cannot await physical completion, so
the completion acknowledgement deliberately traps if it is dropped without
being awaited. A strategy must not create a live operation without retaining
both returned linear values until their respective owners accept them.

## Terminal races

The same laws apply in every ordering:

- cancellation before result wait requests termination; result wait remains the
  only terminal result path;
- cancellation during result wait races only with physical work, never with a
  second result consumer;
- physical completion before cancellation makes later cancellation an
  idempotent no-op at the strategy boundary;
- dropping the operation requests cancellation, while the separate completion
  owner still joins physical work;
- exactly one consuming result call transfers either one output or one exact
  failure.

The lifecycle types contain no result-sharing storage. Strategy implementations
provide the three closures and remain responsible for making cancellation
idempotent and making the completion closure return only after physical work
has ended.

## Starting through a strategy

A Startable strategy creates the operation and completion owners. Its start
requirement is generic over the IO capability set, output, and caller failure,
so one strategy conformer can serve multiple domains without type erasure or a
stored higher-rank closure.

Start borrows the caller's resource only while owners are constructed. The
returned owners escape that call, so neither may retain or capture the borrowed
resource. A strategy establishes any separately owned execution resource it
needs before returning. The generic contract does not prescribe how.

Failure has two phases. Startable.StartFailure is thrown before owners exist.
After owners exist, IO.Failure preserves whether terminal failure came from
strategy execution or the caller-supplied operation. Resource, output, and the
one-shot operation closure have no Sendable requirement.
