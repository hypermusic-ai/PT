// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

library FormatHashLib
{
    uint256 private constant _MASK64 = 0xFFFFFFFFFFFFFFFF;
    bytes1 private constant _PATH_DIM_DOMAIN = 0x10;
    bytes1 private constant _PATH_CONCAT_DOMAIN = 0x11;
    bytes1 private constant _SCALAR_PATH_LABEL_DOMAIN = 0x12;

    function _packLanes(
        uint64 lane0,
        uint64 lane1,
        uint64 lane2,
        uint64 lane3
    ) private pure returns (bytes32)
    {
        uint256 packed = uint256(lane0);
        packed |= uint256(lane1) << 64;
        packed |= uint256(lane2) << 128;
        packed |= uint256(lane3) << 192;
        return bytes32(packed);
    }

    // lane0 = least-significant 64 bits
    // lane3 = most-significant 64 bits
    // compose(lhs, rhs) performs lane-wise uint64 additions with wraparound.
    function compose(bytes32 lhs, bytes32 rhs) internal pure returns (bytes32)
    {
        uint256 lhsWord = uint256(lhs);
        uint256 rhsWord = uint256(rhs);

        uint64 lhs0 = uint64(lhsWord & _MASK64);
        uint64 lhs1 = uint64((lhsWord >> 64) & _MASK64);
        uint64 lhs2 = uint64((lhsWord >> 128) & _MASK64);
        uint64 lhs3 = uint64((lhsWord >> 192) & _MASK64);

        uint64 rhs0 = uint64(rhsWord & _MASK64);
        uint64 rhs1 = uint64((rhsWord >> 64) & _MASK64);
        uint64 rhs2 = uint64((rhsWord >> 128) & _MASK64);
        uint64 rhs3 = uint64((rhsWord >> 192) & _MASK64);

        unchecked {
            return _packLanes(
                lhs0 + rhs0,
                lhs1 + rhs1,
                lhs2 + rhs2,
                lhs3 + rhs3
            );
        }
    }

    // Hashes one dimension-id segment for path labeling.
    function dimPathHash(uint32 dimId) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_PATH_DIM_DOMAIN, dimId));
    }

    // Concatenates two path hashes into a longer deterministic path hash.
    function concatPathHash(bytes32 left, bytes32 right) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_PATH_CONCAT_DOMAIN, left, right));
    }

    // Labels one produced scalar by (scalar-kind-hash, full-path-hash).
    function scalarPathLabelHash(bytes32 scalarHash, bytes32 pathHash) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_SCALAR_PATH_LABEL_DOMAIN, scalarHash, pathHash));
    }

    // Turns a scalar-path label hash into a 4-lane format contribution.
    // Each lane is seeded by a distinct domain byte.
    function labelHashToFormatHash(bytes32 labelHash) internal pure returns (bytes32)
    {
        uint64 lane0 = uint64(uint256(keccak256(abi.encodePacked(bytes1(0x00), labelHash))));
        uint64 lane1 = uint64(uint256(keccak256(abi.encodePacked(bytes1(0x01), labelHash))));
        uint64 lane2 = uint64(uint256(keccak256(abi.encodePacked(bytes1(0x02), labelHash))));
        uint64 lane3 = uint64(uint256(keccak256(abi.encodePacked(bytes1(0x03), labelHash))));

        return _packLanes(lane0, lane1, lane2, lane3);
    }

    // Computes order-independent multiset hash from merged scalar label hashes.
    // Multiplicity is preserved by repeated compose operations.
    function computeFormatHash(bytes32[] memory scalarLabelHashes) internal pure returns (bytes32)
    {
        bytes32 formatHash = bytes32(0);
        for(uint256 i = 0; i < scalarLabelHashes.length; ++i)
        {
            formatHash = compose(formatHash, labelHashToFormatHash(scalarLabelHashes[i]));
        }

        return formatHash;
    }
}
