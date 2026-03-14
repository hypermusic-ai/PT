// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "../connector/IConnector.sol";
import "../registry/IRegistry.sol";
import "../error/Error.sol";
import "../ownable/OwnableBase.sol";

import "@openzeppelin/contracts/utils/Strings.sol";


struct RunningInstance {
    uint32 startPoint;
    uint32 transformShift;
}

struct Particles
{
    string path;
    uint32[] data;
}

struct BindingSet
{
    uint32[] slotIds;
    IConnector[] composites;
}

struct DecomposeContext
{
    RunningInstance[] runningInstances;
    Particles[] outBuffer;
}

interface IRunner
{
    function gen(string memory name, uint32 particlesCount, RunningInstance[] memory runningInstances) external view returns (Particles[] memory);
}

contract Runner is IRunner, OwnableBase
{
    IRegistry private _registry;

    function initialize(address registryAddr) external initializer {
        __OwnableBase_init(msg.sender);
        _registry = IRegistry(registryAddr);
    }

    function genSpace(IConnector connector, uint32 dimId, RunningInstance memory runningInstance, uint32 particlesCount) private view returns (uint32[] memory)
    {
        assert(dimId < connector.getDimensionsCount());

        uint32[] memory space = new uint32[](particlesCount);

        uint32 x = runningInstance.startPoint;
        for(uint32 opId = 0; opId < particlesCount; ++opId)
        {
            space[opId] = x;
            // calculate next element in space
            x = connector.transform(dimId, opId + runningInstance.transformShift, x);
        }

        return space;
    }

    function collectParticleSpace(IConnector connector, uint32 dimId, RunningInstance memory runningInstance, uint32[] memory particleIndexes) private view returns (uint32[] memory)
    {   
        assert(dimId < connector.getDimensionsCount());

        // need to generate space from 0 up to max(particleIndexes) + 1
        // we find the last index which will be collected
        uint32 spaceSize = 0;
        for(uint32 i = 0; i < particleIndexes.length; ++i)
        {
            if(particleIndexes[i] > spaceSize)spaceSize = particleIndexes[i];
        }
        spaceSize += 1;

        // generate space
        uint32[] memory space;
        // because we need to collect up to this space element [max(particleIndexes)]
        space = genSpace(connector, dimId, runningInstance, spaceSize);

        // collect selected indices from space
        uint32[] memory elements = new uint32[](particleIndexes.length);
        for(uint32 i = 0; i < particleIndexes.length; ++i)
        {
            elements[i] = space[particleIndexes[i]];
        }

        return elements;
    }

    function findBoundComposite(BindingSet memory bindings, uint32 slotId) private pure returns (IConnector)
    {
        for(uint32 i = 0; i < bindings.slotIds.length; ++i)
        {
            if(bindings.slotIds[i] == slotId)
            {
                return bindings.composites[i];
            }
        }

        return IConnector(address(0));
    }

    function buildChildBindings(
        IConnector connector,
        uint32 dimId,
        BindingSet memory parentBindings,
        uint32 parentOpenSlotBase,
        uint32 childOpenSlots
    ) private view returns (BindingSet memory childBindings, uint32 parentOpenSlotsConsumed)
    {
        // Parent-visible slot span contributed by this child after applying this connector's
        // static bindings at this dimension.
        uint32 childOpenSlotsInParent = 0;
        uint32 staticBindingCount = 0;

        // Each unbound child slot is projected to exactly one parent-visible slot id.
        uint32[] memory unboundParentSlotIds = new uint32[](childOpenSlots);
        uint32 unboundSlotsCount = 0;

        // Static child slots can contribute more than one parent-visible slot.
        // We keep their projected ranges for fallback mapping when no unbound
        // slot is available for a forwarded binding.
        uint32[] memory staticParentSlotStarts = new uint32[](childOpenSlots);
        uint32[] memory staticParentSlotWidths = new uint32[](childOpenSlots);
        uint32 staticSlotsCount = 0;

        for(uint32 childSlotId = 0; childSlotId < childOpenSlots; ++childSlotId)
        {
            IConnector staticBoundComposite = connector.getBindingComposite(dimId, childSlotId);
            if(address(staticBoundComposite) != address(0))
            {
                staticBindingCount += 1;
                uint32 staticSlots = staticBoundComposite.getOpenSlotsCount();
                staticParentSlotStarts[staticSlotsCount] = childOpenSlotsInParent;
                staticParentSlotWidths[staticSlotsCount] = staticSlots;
                staticSlotsCount += 1;
                childOpenSlotsInParent += staticSlots;
                continue;
            }

            unboundParentSlotIds[unboundSlotsCount] = childOpenSlotsInParent;
            unboundSlotsCount += 1;
            childOpenSlotsInParent += 1;
        }

        // Forwarded bindings from ancestors are matched against unbound child slots.
        // If a forwarded slot lands inside a static range, it falls through to the next
        // unbound child slot in ascending order.
        IConnector[] memory forwardedBindings = new IConnector[](unboundSlotsCount);
        IConnector[] memory staticOverrides = new IConnector[](staticSlotsCount);
        uint32 forwardedBindingCount = 0;

        for(uint32 i = 0; i < parentBindings.slotIds.length; ++i)
        {
            uint32 parentSlotId = parentBindings.slotIds[i];
            if(parentSlotId < parentOpenSlotBase)
            {
                continue;
            }

            uint32 localSlotId = parentSlotId - parentOpenSlotBase;
            if(localSlotId >= childOpenSlotsInParent)
            {
                continue;
            }

            bool assignedToUnbound = false;
            for(uint32 j = 0; j < unboundSlotsCount; ++j)
            {
                if(address(forwardedBindings[j]) != address(0))
                {
                    continue;
                }

                if(unboundParentSlotIds[j] < localSlotId)
                {
                    continue;
                }

                forwardedBindings[j] = parentBindings.composites[i];
                forwardedBindingCount += 1;
                assignedToUnbound = true;
                break;
            }

            if(assignedToUnbound)
            {
                continue;
            }

            // No unbound child slot could accept this forwarded slot. Fall back to the
            // first static slot range that intersects or follows the requested slot.
            bool assignedToStatic = false;
            for(uint32 j = 0; j < staticSlotsCount; ++j)
            {
                if(address(staticOverrides[j]) != address(0))
                {
                    continue;
                }

                uint32 staticRangeWidth = staticParentSlotWidths[j];
                if(staticRangeWidth == 0)
                {
                    continue;
                }

                uint32 staticRangeStart = staticParentSlotStarts[j];
                uint32 staticRangeEnd = staticRangeStart + staticRangeWidth - 1;
                if(staticRangeEnd < localSlotId)
                {
                    continue;
                }

                staticOverrides[j] = parentBindings.composites[i];
                assignedToStatic = true;
                break;
            }

            if(assignedToStatic)
            {
                continue;
            }
        }

        childBindings = BindingSet({
            slotIds: new uint32[](staticBindingCount + forwardedBindingCount),
            composites: new IConnector[](staticBindingCount + forwardedBindingCount)
        });

        uint32 childBindingIndex = 0;
        uint32 unboundCursor = 0;
        uint32 staticCursor = 0;
        for(uint32 childSlotId = 0; childSlotId < childOpenSlots; ++childSlotId)
        {
            IConnector staticBoundComposite = connector.getBindingComposite(dimId, childSlotId);
            if(address(staticBoundComposite) != address(0))
            {
                IConnector selectedStaticComposite = staticBoundComposite;
                if(staticCursor < staticSlotsCount)
                {
                    IConnector staticOverride = staticOverrides[staticCursor];
                    if(address(staticOverride) != address(0))
                    {
                        selectedStaticComposite = staticOverride;
                    }
                }

                childBindings.slotIds[childBindingIndex] = childSlotId;
                childBindings.composites[childBindingIndex] = selectedStaticComposite;
                childBindingIndex += 1;
                staticCursor += 1;
                continue;
            }

            if(unboundCursor < unboundSlotsCount)
            {
                IConnector forwardedComposite = forwardedBindings[unboundCursor];
                if(address(forwardedComposite) != address(0))
                {
                    childBindings.slotIds[childBindingIndex] = childSlotId;
                    childBindings.composites[childBindingIndex] = forwardedComposite;
                    childBindingIndex += 1;
                }
            }

            unboundCursor += 1;
        }

        parentOpenSlotsConsumed = childOpenSlotsInParent;
    }

    function decomposeWithoutBindings(
        string memory path,
        IConnector connector,
        uint32 runningInstanceId,
        uint32[] memory indexes,
        uint32 dest,
        DecomposeContext memory context
    ) private view returns (uint32)
    {
        BindingSet memory emptyBindings = BindingSet({
            slotIds: new uint32[](0),
            composites: new IConnector[](0)
        });

        return decompose(path, connector, runningInstanceId, indexes, dest, context, emptyBindings);
    }

    function decompose(
        string memory path,
        IConnector connector,
        uint32 runningInstanceId,
        uint32[] memory indexes,
        uint32 dest,
        DecomposeContext memory context,
        BindingSet memory bindings
    ) view private returns (uint32)
    {
        assert(dest < context.outBuffer.length);

        if(connector.checkCondition() == false)
        {
            revert ConditionNotMet(keccak256(bytes(connector.getName())));
        }

        string memory basePath = string(abi.encodePacked(path, "/", connector.getName()));

        // from which starting point should we generate actual composite dimension
        RunningInstance memory runningInstance;

        // buffer for indexes
        uint32[] memory compositeIndexes;

        uint32 openSlotId = 0;

        // for every dimension run decompose at designated buffer index
        for(uint32 dimId = 0; dimId < connector.getDimensionsCount(); ++dimId)
        {
            string memory compositePath = string(abi.encodePacked(basePath, ":", Strings.toString(dimId)));

            // calculate running instance values first
            if(runningInstanceId < context.runningInstances.length)
            {
                runningInstance = context.runningInstances[runningInstanceId];
                // shift running instance
                runningInstanceId += 1;
            }
            else
            {
                runningInstance.startPoint = 0;
                runningInstance.transformShift = 0;
            }

            // we always need to calculate elements from dimension
            // when compound connector is present it passes it as indexes to further decompose
            // when scalar we can fill out buffer
            compositeIndexes = collectParticleSpace(connector, dimId, runningInstance, indexes);

            IConnector compositeConnector = connector.getComposite(dimId);

            if(address(compositeConnector) == address(0))
            {
                IConnector replacement = findBoundComposite(bindings, openSlotId);
                openSlotId += 1;

                if(address(replacement) == address(0))
                {
                    assert(dest < context.outBuffer.length);
                    // scalar, we can fill out buffer
                    assert(compositeIndexes.length == context.outBuffer[dest].data.length);

                    context.outBuffer[dest].path = compositePath;
                    context.outBuffer[dest].data = compositeIndexes;

                    // shift buffer index
                    dest += 1;
                    continue;
                }

                // slot is bound to a connector, recurse into it
                dest = decomposeWithoutBindings(
                    compositePath,
                    replacement,
                    runningInstanceId,
                    compositeIndexes,
                    dest,
                    context);

                continue;
            }

            uint32 childOpenSlots = compositeConnector.getOpenSlotsCount();
            (BindingSet memory childBindings, uint32 childOpenSlotsConsumed) = buildChildBindings(
                connector,
                dimId,
                bindings,
                openSlotId,
                childOpenSlots);

            // recurse into child with static + forwarded bindings
            dest = decompose(
                compositePath,
                compositeConnector,
                runningInstanceId,
                compositeIndexes,
                dest,
                context,
                childBindings);

            // from parent perspective child contributes all open slots after static bindings are applied
            openSlotId += childOpenSlotsConsumed;
        }

        assert(openSlotId == connector.getOpenSlotsCount());
        return dest;
    }

    function gen(string memory name, uint32 particlesCount, RunningInstance[] memory runningInstances) external view returns (Particles[] memory)
    {
        require(particlesCount > 0, "number of particles must be greater than 0");
        require(_registry.containsConnector(name), "cannot find connector");

        IConnector connector = _registry.getConnector(name);

        uint32 numberOfScalars = connector.getScalarsCount();
        assert(numberOfScalars > 0);

        // allocate memory for scalar data
        Particles[] memory particlesBuffer = new Particles[](numberOfScalars);
        for(uint32 i = 0; i < numberOfScalars; ++i)
        {
            particlesBuffer[i].data = new uint32[](particlesCount);
        }

        // we will generate sequential list of particlesCount objects from actual connector
        // generate 0th element from connector
        // generate 1st el from connector
        //...
        // gen (particlesCount-1)th el from connector
        // to generate 0th element from connector we need to specify from which starting points
        // should it generate all of its composite connectors
        // it will give us the FIRST generated element of that particular generate call
        uint32 start = 0;
        if(runningInstances.length > 0)
        {
            start = runningInstances[0].startPoint;
        }

        uint32[] memory indexes = new uint32[](particlesCount);
        for(uint32 i = 0; i < particlesCount; ++i)
        {
            indexes[i] = i + start;
        }

        DecomposeContext memory context = DecomposeContext({
            runningInstances: runningInstances,
            outBuffer: particlesBuffer
        });
        uint32 endDest = decomposeWithoutBindings("", connector, 1, indexes, 0, context);
        assert(endDest == numberOfScalars);

        return particlesBuffer;
    }
}
