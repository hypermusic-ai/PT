// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/// @notice Entity kind ids. The values match the ordinals of IRegistry.EntityKind,
/// which is the on-chain and off-chain wire form.
library PTEntityKind
{
    uint8 internal constant CONNECTOR = 0;
    uint8 internal constant TRANSFORMATION = 1;
    uint8 internal constant CONDITION = 2;
}

/// @notice Identity every published PT entity exposes. The registry reads these
/// after CREATE2 returns and requires exact agreement with the signed publication,
/// so the event, the registered address and the deployed runtime all describe the
/// same publication.
interface IPTEntity
{
    function ptKind() external pure returns (uint8);

    function ptVersion() external pure returns (uint64);

    function getName() external view returns (string memory);

    /// @notice keccak256 of the exact published artifact bundle bytes.
    function contentHash() external view returns (bytes32);

    /// @notice keccak256 of the published metadata document.
    function metadataHash() external view returns (bytes32);
}

abstract contract PTEntityBase is IPTEntity
{
    uint64 internal constant PT_ENTITY_VERSION = 1;

    string internal _name;

    bytes32 private _contentHash;
    bytes32 private _metadataHash;

    constructor(string memory name_, bytes32 contentHash_, bytes32 metadataHash_)
    {
        require(bytes(name_).length != 0, "name is empty");
        require(contentHash_ != bytes32(0), "content hash is zero");
        require(metadataHash_ != bytes32(0), "metadata hash is zero");

        _name = name_;
        _contentHash = contentHash_;
        _metadataHash = metadataHash_;
    }

    function ptVersion() external pure virtual override returns (uint64)
    {
        return PT_ENTITY_VERSION;
    }

    function getName() external view virtual override returns (string memory)
    {
        return _name;
    }

    function contentHash() external view virtual override returns (bytes32)
    {
        return _contentHash;
    }

    function metadataHash() external view virtual override returns (bytes32)
    {
        return _metadataHash;
    }
}
