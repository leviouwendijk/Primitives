public enum TreeExpansionError:
    Error,
    Sendable,
    Equatable
{
    case child_order_count_mismatch(
        parent: TreeAddress,
        expected: Int,
        actual: Int
    )

    case child_order_index_out_of_bounds(
        parent: TreeAddress,
        index: Int,
        child_count: Int
    )

    case duplicate_child_order_index(
        parent: TreeAddress,
        index: Int
    )

    case incomplete_materialization(
        remaining: Set<TreeAddress>
    )
}
