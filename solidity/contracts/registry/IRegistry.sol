// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "../transformation/ITransformation.sol";
import "../condition/ICondition.sol";
import "../connector/IConnector.sol";

interface IRegistry
{
    struct TransformationRegistration {
        address owner;
        uint32 argsCount;
    }

    struct ConditionRegistration {
        address owner;
        uint32 argsCount;
    }

    struct ConnectorRegistration {
        address owner;
        uint32 dimensionsCount;
        uint32[] compositeDimIds;
        string[] compositeNames;
        uint32[] bindingDimIds;
        uint32[] bindingSlotIds;
        string[] bindingNames;
        string conditionName;
        int32[] conditionArgs;
        bytes32 formatHash;
        // Static running instances (parallel arrays keyed by local position id) so that a connector's
        // full state is reconstructable from chain logs alone.
        uint32[] staticRiPositions;
        uint32[] staticRiStartPoints;
        uint32[] staticRiTransformShifts;
        // Per-dimension transformation definitions (parallel arrays ordered by (dimId, indexWithinDim))
        // so that a full ConnectorRecord is reconstructable from chain logs alone.
        // transformationArgs is a single flattened array consumed left-to-right by transformationArgCounts.
        uint32[] transformationDimIds;
        string[] transformationNames;
        uint32[] transformationArgCounts;
        int32[]  transformationArgs;
    }

    event TransformationAdded(address caller, string name, address transformationAddr, address owner, uint32 argsCount);
    event ConditionAdded(address caller, string name, address conditionAddr, address owner, uint32 argsCount);
    event ConnectorAdded(
        address indexed caller,
        address indexed owner,
        string name,
        address connectorAddr,
        uint32 dimensionsCount,
        uint32[] compositeDimIds,
        string[] compositeNames,
        uint32[] bindingDimIds,
        uint32[] bindingSlotIds,
        string[] bindingNames,
        string conditionName,
        int32[] conditionArgs,
        bytes32 formatHash,
        uint32[] staticRiPositions,
        uint32[] staticRiStartPoints,
        uint32[] staticRiTransformShifts,
        uint32[] transformationDimIds,
        string[] transformationNames,
        uint32[] transformationArgCounts,
        int32[] transformationArgs
    );

    event TransformationRemoved(address caller, string name);
    event ConditionRemoved(address caller, string name);
    event ConnectorRemoved(address caller, string name);

    function registerTransformation(
        string calldata name,
        ITransformation transformation,
        TransformationRegistration calldata registration
    ) external;
    function registerCondition(
        string calldata name,
        ICondition condition,
        ConditionRegistration calldata registration
    ) external;
    function registerConnector(
        string calldata name,
        IConnector connector,
        ConnectorRegistration calldata registration
    ) external;

    function getTransformation(string calldata name) external view returns (ITransformation);
    function getCondition(string calldata name) external view returns (ICondition);
    function getConnector(string calldata name) external view returns (IConnector);

    function clearTransformation(string calldata name) external;
    function clearCondition(string calldata name) external;
    function clearConnector(string calldata name) external;

    function containsTransformation(string calldata name) external view returns (bool);
    function containsCondition(string calldata name) external view returns (bool);
    function containsConnector(string calldata name) external view returns (bool);

    function formatConnectorsCount(bytes32 formatHash) external view returns (uint256);
    function getFormatConnector(bytes32 formatHash, uint256 index) external view returns (IConnector);

    function transformationsCount() external view returns (uint);
    function conditionsCount() external view returns (uint);
    function connectorsCount() external view returns (uint);
}
