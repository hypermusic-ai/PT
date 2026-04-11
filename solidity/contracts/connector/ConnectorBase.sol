// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./IConnector.sol";

import "../registry/IRegistry.sol";
import "../transformation/ITransformation.sol";
import "../condition/ICondition.sol";
import "../types/RunningInstance.sol";

import "../ownable/OwnableConstructorBase.sol";
import "../error/Error.sol";
import "../utils/FormatHashLib.sol";

abstract contract ConnectorBase is IConnector, OwnableConstructorBase
{
    IRegistry                private _registry;
    string                   private _name;

    ITransformation[][]      private _transformations;
    CallDef                  private _transformationsCallDef;

    IConnector[]             private _composites;
    uint32[][]               private _bindingSlotIds;
    IConnector[][]           private _bindingComposites;
    mapping(uint32 => bool)  private _hasStaticRunningInstances;
    mapping(uint32 => RunningInstance) private _staticRunningInstances;

    uint32                   private _scalars;
    uint32                   private _openSlots;
    bytes32[]                private _scalarHashes;
    bytes32                  private _formatHash;

    ICondition               private _condition;
    int32[]                  private _conditionCheckArgs;

    bool                     private _finalized;

    constructor(address registryAddr, string memory name, uint32 dimensionsCount)
        OwnableConstructorBase(msg.sender)
    {
        require(registryAddr != address(0), "registry is zero");
        require(dimensionsCount > 0, "dimensions is zero");

        _registry = IRegistry(registryAddr);
        _name = name;

        _transformationsCallDef = new CallDef(dimensionsCount);
        _transformations = new ITransformation[][](dimensionsCount);
    }

    function getCallDef() internal view returns (CallDef)
    {
        return _transformationsCallDef;
    }

    function _findBindingComposite(uint32 dimId, uint32 slotId) internal view returns (IConnector)
    {
        for(uint32 i = 0; i < _bindingSlotIds[dimId].length; ++i)
        {
            if(_bindingSlotIds[dimId][i] == slotId)
            {
                return _bindingComposites[dimId][i];
            }
        }

        return IConnector(address(0));
    }

    function __ConnectorBase_finalizeInit(
        uint32[] memory compositeDimIds,
        string[] memory compositeNames,
        uint32[] memory bindingDimIds,
        uint32[] memory bindingSlotIds,
        string[] memory bindingNames,
        uint32[] memory staticRiPositions,
        uint32[] memory staticRiStartPoints,
        uint32[] memory staticRiTransformShifts,
        string memory conditionName,
        int32[] memory conditionCheckArgs
    ) internal
    {
        require(_finalized == false, "already finalized");
        require(_transformationsCallDef.getDimensionsCount() == _transformations.length, "invalid dimensions");

        for(uint32 dimId = 0; dimId < _transformations.length; ++dimId)
        {
            uint32 opCount = _transformationsCallDef.getTransformationsCount(dimId);

            for(uint32 opId = 0; opId < opCount; ++opId)
            {
                string memory transformationName = _transformationsCallDef.names(dimId, opId);
                if(_registry.containsTransformation(transformationName) == false)
                {
                    revert TransformationMissing(keccak256(bytes(transformationName)));
                }

                ITransformation transformation = _registry.getTransformation(transformationName);

                if(_transformationsCallDef.getArgsCount(dimId, opId) != transformation.getArgsCount())
                {
                    revert TransformationArgumentsMismatch(keccak256(bytes(transformationName)));
                }

                _transformations[dimId].push(transformation);
            }
        }

        if(compositeDimIds.length != compositeNames.length)
        {
            revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
        }

        if(bindingDimIds.length != bindingSlotIds.length || bindingDimIds.length != bindingNames.length)
        {
            revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
        }

        if(
            staticRiPositions.length != staticRiStartPoints.length ||
            staticRiPositions.length != staticRiTransformShifts.length)
        {
            revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
        }

        uint32 dimensionsCount = uint32(_transformations.length);
        _composites = new IConnector[](dimensionsCount);
        _bindingSlotIds = new uint32[][](dimensionsCount);
        _bindingComposites = new IConnector[][](dimensionsCount);

        for(uint32 i = 0; i < compositeNames.length; ++i)
        {
            uint32 dimId = compositeDimIds[i];
            if(dimId >= dimensionsCount)
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
            }

            if(address(_composites[dimId]) != address(0))
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
            }

            if(bytes(compositeNames[i]).length == 0)
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
            }

            if(_registry.containsConnector(compositeNames[i]) == false)
            {
                revert ConnectorMissing(keccak256(bytes(compositeNames[i])));
            }

            IConnector composite = _registry.getConnector(compositeNames[i]);
            _composites[dimId] = composite;
        }

        _scalars = 0;
        _openSlots = 0;
        for(uint32 dimId = 0; dimId < dimensionsCount; ++dimId)
        {
            IConnector composite = _composites[dimId];
            if(address(composite) == address(0))
            {
                _scalars += 1;
                _openSlots += 1;
                continue;
            }

            _scalars += composite.getScalarsCount();
            _openSlots += composite.getOpenSlotsCount();
        }

        for(uint32 i = 0; i < bindingNames.length; ++i)
        {
            uint32 dimId = bindingDimIds[i];
            if(dimId >= dimensionsCount)
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
            }

            IConnector composite = _composites[dimId];
            if(address(composite) == address(0))
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
            }

            uint32 slotId = bindingSlotIds[i];
            if(slotId >= composite.getOpenSlotsCount())
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
            }

            if(bytes(bindingNames[i]).length == 0)
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
            }

            if(address(_findBindingComposite(dimId, slotId)) != address(0))
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
            }

            if(_registry.containsConnector(bindingNames[i]) == false)
            {
                revert ConnectorMissing(keccak256(bytes(bindingNames[i])));
            }

            IConnector bindingComposite = _registry.getConnector(bindingNames[i]);
            _bindingSlotIds[dimId].push(slotId);
            _bindingComposites[dimId].push(bindingComposite);

            _openSlots += bindingComposite.getOpenSlotsCount();
            assert(_openSlots > 0);
            _openSlots -= 1;

            _scalars += bindingComposite.getScalarsCount();
            assert(_scalars > 0);
            _scalars -= 1;
        }

        for(uint32 i = 0; i < staticRiPositions.length; ++i)
        {
            uint32 localPosId = staticRiPositions[i];

            if(_hasStaticRunningInstances[localPosId])
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(_name)));
            }

            _hasStaticRunningInstances[localPosId] = true;
            _staticRunningInstances[localPosId] = RunningInstance({
                startPoint: staticRiStartPoints[i],
                transformShift: staticRiTransformShifts[i]
            });
        }

        if(bytes(conditionName).length != 0)
        {
            if(_registry.containsCondition(conditionName) == false)
            {
                revert ConditionMissing(keccak256(bytes(conditionName)));
            }

            _condition = _registry.getCondition(conditionName);

            if(conditionCheckArgs.length != _condition.getArgsCount())
            {
                revert ConditionArgumentsMismatch(keccak256(bytes(conditionName)));
            }

            _conditionCheckArgs = conditionCheckArgs;
        }


        // Calculating format hash as a set of merged scalar hashes.
        // Duplicate labels do not affect the resulting format hash.
        // Tail-only rule: path prefixes are ignored.
        _scalarHashes = new bytes32[](_scalars);

        uint32 scalarHashId = 0;
        bytes32 localScalarHash = keccak256(bytes(_name));
        for(uint32 dimId = 0; dimId < dimensionsCount; ++dimId)
        {
            bytes32 dimPathHash = FormatHashLib.dimPathHash(dimId);
            IConnector composite = _composites[dimId];
            if(address(composite) == address(0))
            {
                // Case 1: local leaf dimension (no composite).
                // Produced label = H(local scalar kind, local tail path).
                bytes32 labelHash = FormatHashLib.scalarPathLabelHash(localScalarHash, dimPathHash);

                _scalarHashes[scalarHashId] = labelHash;
                scalarHashId += 1;
                continue;
            }

            uint32 childOpenSlots = composite.getOpenSlotsCount();
            uint32 childScalars = composite.getScalarsCount();
            require(childOpenSlots == childScalars, "child scalars/open slots mismatch");

            for(uint32 childSlotId = 0; childSlotId < childOpenSlots; ++childSlotId)
            {
                // getScalarHash now returns merged label hash.
                bytes32 childLabelHash = composite.getScalarHash(childSlotId);

                IConnector bindingComposite = _findBindingComposite(dimId, childSlotId);
                if(address(bindingComposite) == address(0))
                {
                    // Case 2: composite slot without binding.
                    // Tail-only rule: parent prefix is ignored, so child label is reused.
                    _scalarHashes[scalarHashId] = childLabelHash;
                    scalarHashId += 1;
                    continue;
                }

                // Case 3: composite slot with binding.
                // Replace this child slot by the bound subtree.
                // Tail-only rule: parent and slot prefixes are ignored.
                uint32 bindingScalars = bindingComposite.getScalarsCount();
                uint32 bindingOpenSlots = bindingComposite.getOpenSlotsCount();
                require(bindingScalars == bindingOpenSlots, "binding scalars/open slots mismatch");
                for(uint32 bindingScalarId = 0; bindingScalarId < bindingScalars; ++bindingScalarId)
                {
                    bytes32 bindingLabelHash = bindingComposite.getScalarHash(bindingScalarId);

                    _scalarHashes[scalarHashId] = bindingLabelHash;
                    scalarHashId += 1;
                }
            }
        }

        require(scalarHashId == _scalars, "invalid scalar hashes");
        _formatHash = FormatHashLib.computeFormatHash(_scalarHashes);

        IRegistry.ConnectorRegistration memory registration = IRegistry.ConnectorRegistration({
            owner: msg.sender,
            dimensionsCount: dimensionsCount,
            compositeDimIds: compositeDimIds,
            compositeNames: compositeNames,
            bindingDimIds: bindingDimIds,
            bindingSlotIds: bindingSlotIds,
            bindingNames: bindingNames,
            conditionName: conditionName,
            conditionArgs: conditionCheckArgs,
            formatHash: _formatHash
        });

        _registry.registerConnector(_name, this, registration);
        _finalized = true;
    }

    function getName() external view returns(string memory)
    {
        return _name;
    }

    function getScalarsCount() external view returns (uint32)
    {
        return _scalars;
    }

    // Returns merged scalar label hash H(scalar-kind-hash, tail-path-hash).
    function getScalarHash(uint32 scalarId) external view returns (bytes32)
    {
        require(scalarId < _scalarHashes.length, "scalar id out of range");
        return _scalarHashes[scalarId];
    }

    function getFormatHash() external view returns (bytes32)
    {
        return _formatHash;
    }

    function getOpenSlotsCount() external view returns (uint32)
    {
        return _openSlots;
    }

    function getDimensionsCount() external view returns (uint32)
    {
        return uint32(_transformations.length);
    }

    function transform(uint32 dimId, uint32 txId, uint32 x) external view returns (uint32)
    {
        require(dimId < _transformations.length, "invalid dimension id");
        if(_transformations[dimId].length == 0)
        {
            return x;
        }

        txId %= uint32(_transformations[dimId].length);
        return _transformations[dimId][txId].run(x, _transformationsCallDef.getArgs(dimId, txId));
    }

    function getCompositesCount() external view returns (uint32)
    {
        return uint32(_composites.length);
    }

    function getComposite(uint32 dimId) external view returns (IConnector)
    {
        require(dimId < _composites.length, "composite dimension Id out of range");
        return _composites[dimId];
    }

    function getBindingComposite(uint32 dimId, uint32 slotId) external view returns (IConnector)
    {
        require(dimId < _bindingSlotIds.length, "binding dimension Id out of range");
        return _findBindingComposite(dimId, slotId);
    }

    function getStaticRunningInstance(uint32 localPosId) external view returns (bool hasValue, uint32 startPoint, uint32 transformShift)
    {
        if(_hasStaticRunningInstances[localPosId] == false)
        {
            return (false, 0, 0);
        }

        RunningInstance memory runningInstance = _staticRunningInstances[localPosId];
        return (true, runningInstance.startPoint, runningInstance.transformShift);
    }

    function getCondition() external view returns (ICondition)
    {
        return _condition;
    }

    function getConditionArgs() external view returns (int32[] memory)
    {
        return _conditionCheckArgs;
    }

    function checkCondition() external view override returns(bool)
    {
        if(address(_condition) == address(0))
        {
            return true;
        }

        return _condition.check(_conditionCheckArgs);
    }
}
