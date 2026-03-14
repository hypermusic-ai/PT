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

struct Binding
{
    uint32 slotId;
    IConnector composite;
    Binding[] forwarded;
}

struct BindingSet
{
    Binding[] entries;
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

    function findBoundBinding(BindingSet memory bindings, uint32 slotId) private pure returns (bool found, Binding memory binding)
    {
        for(uint32 i = 0; i < bindings.entries.length; ++i)
        {
            if(bindings.entries[i].slotId == slotId)
            {
                return (true, bindings.entries[i]);
            }
        }

        Binding[] memory emptyForwarded = new Binding[](0);
        return (false, Binding({
            slotId: 0,
            composite: IConnector(address(0)),
            forwarded: emptyForwarded
        }));
    }

    function buildChildBindings(
        IConnector connector,
        uint32 dimId,
        BindingSet memory parentBindings,
        uint32 parentOpenSlotBase,
        uint32 childOpenSlots
    ) private view returns (BindingSet memory childBindings, uint32 parentOpenSlotsConsumed)
    {
        // Parent-visible slot span contributed by this child after applying
        // this connector's static bindings at this dimension.
        uint32 childOpenSlotsInParent = 0;

        // Per child slot projection into parent-visible local slot space.
        uint32[] memory slotProjectedStarts = new uint32[](childOpenSlots);
        uint32[] memory slotProjectedWidths = new uint32[](childOpenSlots);

        // Child slot bindings selected at this level (static defaults + forwarded exact hits).
        IConnector[] memory slotSelectedComposites = new IConnector[](childOpenSlots);
        IConnector[] memory slotStaticComposites = new IConnector[](childOpenSlots);

        // Forwarded bindings that target inside each static slot's internal open-slot space.
        Binding[][] memory slotForwardedTemp = new Binding[][](childOpenSlots);
        uint32[] memory slotForwardedCounts = new uint32[](childOpenSlots);

        // Forwarded bindings attached to an unbound slot replacement.
        Binding[][] memory unboundReplacementForwarded = new Binding[][](childOpenSlots);

        for(uint32 childSlotId = 0; childSlotId < childOpenSlots; ++childSlotId)
        {
            slotProjectedStarts[childSlotId] = childOpenSlotsInParent;

            IConnector staticBoundComposite = connector.getBindingComposite(dimId, childSlotId);
            if(address(staticBoundComposite) != address(0))
            {
                slotStaticComposites[childSlotId] = staticBoundComposite;
                slotSelectedComposites[childSlotId] = staticBoundComposite;

                uint32 staticSlots = staticBoundComposite.getOpenSlotsCount();
                slotProjectedWidths[childSlotId] = staticSlots;
                slotForwardedTemp[childSlotId] = new Binding[](parentBindings.entries.length);
                childOpenSlotsInParent += staticSlots;
                continue;
            }

            slotProjectedWidths[childSlotId] = 1;
            childOpenSlotsInParent += 1;
        }

        // DFS mapping:
        // - exact hit on unbound point binds that child slot directly
        // - hit inside static range is rebased into that static slot's forwarded bindings
        for(uint32 i = 0; i < parentBindings.entries.length; ++i)
        {
            Binding memory parentBinding = parentBindings.entries[i];
            uint32 parentSlotId = parentBinding.slotId;
            if(parentSlotId < parentOpenSlotBase)
            {
                continue;
            }

            uint32 localSlotId = parentSlotId - parentOpenSlotBase;
            if(localSlotId >= childOpenSlotsInParent)
            {
                continue;
            }

            for(uint32 childSlotId = 0; childSlotId < childOpenSlots; ++childSlotId)
            {
                uint32 rangeStart = slotProjectedStarts[childSlotId];
                uint32 rangeWidth = slotProjectedWidths[childSlotId];
                if(rangeWidth == 0)
                {
                    continue;
                }

                uint32 rangeEndExclusive = rangeStart + rangeWidth;
                if(localSlotId < rangeStart || localSlotId >= rangeEndExclusive)
                {
                    continue;
                }

                IConnector staticComposite = slotStaticComposites[childSlotId];
                if(address(staticComposite) == address(0))
                {
                    // Unbound projected point: direct slot binding.
                    slotSelectedComposites[childSlotId] = parentBinding.composite;
                    unboundReplacementForwarded[childSlotId] = parentBinding.forwarded;
                    break;
                }

                // Static projected range: bind inside static composite by local DFS offset.
                uint32 childForwardedIndex = slotForwardedCounts[childSlotId];
                slotForwardedTemp[childSlotId][childForwardedIndex] = Binding({
                    slotId: localSlotId - rangeStart,
                    composite: parentBinding.composite,
                    forwarded: parentBinding.forwarded
                });
                slotForwardedCounts[childSlotId] = childForwardedIndex + 1;
                break;
            }
        }

        uint32 childBindingCount = 0;
        for(uint32 childSlotId = 0; childSlotId < childOpenSlots; ++childSlotId)
        {
            if(address(slotSelectedComposites[childSlotId]) != address(0))
            {
                childBindingCount += 1;
            }
        }

        childBindings = BindingSet({
            entries: new Binding[](childBindingCount)
        });

        uint32 childBindingIndex = 0;
        for(uint32 childSlotId = 0; childSlotId < childOpenSlots; ++childSlotId)
        {
            IConnector selectedComposite = slotSelectedComposites[childSlotId];
            if(address(selectedComposite) == address(0))
            {
                continue;
            }

            Binding[] memory forwardedBindings;
            if(address(slotStaticComposites[childSlotId]) != address(0))
            {
                uint32 forwardedCount = slotForwardedCounts[childSlotId];
                forwardedBindings = new Binding[](forwardedCount);
                for(uint32 i = 0; i < forwardedCount; ++i)
                {
                    forwardedBindings[i] = slotForwardedTemp[childSlotId][i];
                }
            }
            else
            {
                forwardedBindings = unboundReplacementForwarded[childSlotId];
            }

            childBindings.entries[childBindingIndex] = Binding({
                slotId: childSlotId,
                composite: selectedComposite,
                forwarded: forwardedBindings
            });
            childBindingIndex += 1;
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
            entries: new Binding[](0)
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
                (bool isBound, Binding memory boundBinding) = findBoundBinding(bindings, openSlotId);
                openSlotId += 1;

                if(isBound == false)
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

                // Slot is bound to a connector. Recurse with bindings forwarded
                // specifically to this replacement.
                BindingSet memory replacementBindings = BindingSet({
                    entries: boundBinding.forwarded
                });
                dest = decompose(
                    compositePath,
                    boundBinding.composite,
                    runningInstanceId,
                    compositeIndexes,
                    dest,
                    context,
                    replacementBindings);

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
