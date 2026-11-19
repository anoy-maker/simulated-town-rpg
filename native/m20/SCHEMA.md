# M20 packed numerical ABI, version 1

All wire integers are unsigned 32-bit little endian; all reals IEEE754 binary64
little endian. No structs, pointers, ownership, strings or Godot Variants cross
the language ABI. Header: bytes `M20K`, version=1, operation, job count (16 bytes).
An output repeats this header and contains each job's doubles in input order.
Maximum 100000 jobs; exact lengths, finite/bounded inputs and distributions are
validated before computation. Errors return status 1 (schema), 2 (domain), or
3 (internal failure), with no usable output. Inputs remain immutable. Empty
batches are valid. No native code receives a world/ledger/NPC/customer object.

Operation 1, forecast: per job four u32s (price 1..12, carry 0..12, periods=13,
reserved=0), then local alpha[13], local weights[13], visitor alpha[13], visitor
weights[13]. Alphas positive, weights nonnegative and normalized. Minimum future
arrivals=0. First mix weights with the original prior using hazard .02, then
compute each of thirteen daily sales PMFs, each length25. Output 13*25 doubles.
This contains traffic conditioning, beta-binomial tables, ordered component
mixtures and local/visitor sales convolution. Posterior updates and today's
conditional demand remain GDScript to preserve policy separation.

Operation 2, continuation: four u32s (price 1..12, public supply 0..12,
periods=13,reserved=0), then state[4] (cash, flour, bread, retained realized
cash earnings), and 13*25 sales PMF doubles. Cash/flour/bread nonnegative and
<=1e9; retained may be signed within +/-1e9. PMFs nonnegative and normalized.
Output one value/job. State transitions, first-day integration, twelve-day
mean-state tail, payout and .99 discount match M19, including its call-local
full-support means. No native state is authoritative or persistent.

The same C ABI for each independently built library is
`int m20_{cpp|rust}_compute(const uint8_t*, size_t, uint8_t*, size_t)`.
Caller owns all buffers; output length must exactly match schema. The single
Godot C++ bridge supplies borrowed input and fresh owned output, catches C++
exceptions, and rejects nonzero status. Rust validates before indexing and
uses safe arithmetic; its sole unsafe block constructs nonaliasing borrowed
slices at the checked FFI boundary. Libraries are single-threaded.
