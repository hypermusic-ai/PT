// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "../connector/IConnector.sol";
import "../registry/IRegistry.sol";
import "../error/Error.sol";
import "../ownable/OwnableBase.sol";
import "../types/RunningInstance.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

struct PositionedRunningInstance {
    uint32 position;
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
    PositionedRunningInstance[] dynamicRi;
    uint32 dynamicRiIndex;
    Particles[] outBuffer;
    IConnector staticScopeConnector;
    uint32 staticScopeStartPositionId;
}

struct DecomposeResult
{
    uint32 dest;
    uint32 nextPositionId;
}

interface IRunner
{
    function gen(string memory name, uint32 particlesCount, PositionedRunningInstance[] memory dynamicRi) external view returns (Particles[] memory);
}

contract Runner is IRunner, OwnableBase
{
    IRegistry private _registry;

    function initialize(address registryAddr) external initializer {
        __OwnableBase_init(msg.sender);
        _registry = IRegistry(registryAddr);
    }

    function collectParticleSpace(IConnector connector, uint32 dimId, RunningInstance memory runningInstance, uint32[] memory particleIndexes) private view returns (uint32[] memory)
    {
        assert(dimId < connector.getDimensionsCount());

        uint32 length = uint32(particleIndexes.length);
        if(length == 0)
        {
            return new uint32[](0);
        }

        // Detect the strongest property the selection has:
        //  - contiguous: particleIndexes[i] = first + i (stride 1)
        //  - sorted:     particleIndexes[i] >= particleIndexes[i-1]
        // Both let us avoid allocating a dense space[0..max] inside the
        // runner. Contiguous is the common case at the root of gen().
        bool contiguous = true;
        bool sorted = true;
        uint32 firstIndex = particleIndexes[0];
        uint32 maxIndex = firstIndex;
        for(uint32 i = 1; i < length; ++i)
        {
            uint32 cur = particleIndexes[i];
            uint32 prev = particleIndexes[i - 1];
            if(cur != firstIndex + i)
            {
                contiguous = false;
            }
            if(cur < prev)
            {
                sorted = false;
            }
            if(cur > maxIndex)
            {
                maxIndex = cur;
            }
            if(!contiguous && !sorted)
            {
                break;
            }
        }

        if(contiguous && firstIndex == 0)
        {
            return connector.transformRange(
                dimId,
                runningInstance.transformShift,
                runningInstance.startPoint,
                length);
        }

        if(sorted)
        {
            return connector.transformAt(
                dimId,
                runningInstance.transformShift,
                runningInstance.startPoint,
                particleIndexes);
        }

        // Fallback for unsorted selections: materialize space up to
        // max(particleIndexes)+1 via a single batched CALL, then pick
        // the requested indices.
        uint32[] memory space = connector.transformRange(
            dimId,
            runningInstance.transformShift,
            runningInstance.startPoint,
            maxIndex + 1);
        
        uint32[] memory elements = new uint32[](length);
        for(uint32 i = 0; i < length; ++i)
        {
            elements[i] = space[particleIndexes[i]];
        }
        
        return elements;
    }

    function resolveDynamicRunningInstance(
        PositionedRunningInstance[] memory dynamicRi,
        uint32 position,
        uint32 dynamicRiIndex
    ) private pure returns (bool found, RunningInstance memory runningInstance, uint32 nextDynamicRiIndex)
    {
        uint32 i = dynamicRiIndex;
        while(i < dynamicRi.length && dynamicRi[i].position < position)
        {
            i += 1;
        }

        if(i < dynamicRi.length && dynamicRi[i].position == position)
        {
            RunningInstance memory resolved = RunningInstance({
                startPoint: dynamicRi[i].startPoint,
                transformShift: dynamicRi[i].transformShift
            });
            return (true, resolved, i + 1);
        }

        RunningInstance memory emptyRunningInstance;
        return (false, emptyRunningInstance, i);
    }

    function resolveRootRunningInstance(
        IConnector connector,
        PositionedRunningInstance[] memory dynamicRi,
        uint32 dynamicRiIndex
    ) private view returns (RunningInstance memory runningInstance, uint32 nextDynamicRiIndex)
    {
        (bool hasDynamic, RunningInstance memory dynamicRunningInstance, uint32 resolvedDynamicRiIndex) = resolveDynamicRunningInstance(dynamicRi, 0, dynamicRiIndex);
        (bool hasStatic, uint32 staticStartPoint, uint32 staticTransformShift) = connector.getStaticRunningInstance(0);

        if(hasDynamic && hasStatic)
        {
            revert RunningInstanceStaticOverride(0);
        }

        if(hasDynamic)
        {
            return (dynamicRunningInstance, resolvedDynamicRiIndex);
        }

        if(hasStatic)
        {
            return (RunningInstance({
                startPoint: staticStartPoint,
                transformShift: staticTransformShift
            }), resolvedDynamicRiIndex);
        }

        runningInstance.startPoint = 0;
        runningInstance.transformShift = 0;
        return (runningInstance, resolvedDynamicRiIndex);
    }

    function resolveDimensionRunningInstance(
        IConnector connector,
        uint32 dimId,
        uint32 positionId,
        DecomposeContext memory context,
        IConnector fallbackCompositeConnector
    ) private view returns (RunningInstance memory runningInstance)
    {
        (bool hasDynamic, RunningInstance memory dynamicRunningInstance, uint32 resolvedDynamicRiIndex) = resolveDynamicRunningInstance(
            context.dynamicRi,
            positionId,
            context.dynamicRiIndex
        );
        context.dynamicRiIndex = resolvedDynamicRiIndex;
        IConnector staticScopeConnector = context.staticScopeConnector;
        assert(positionId >= context.staticScopeStartPositionId);
        uint32 staticScopePositionId = positionId - context.staticScopeStartPositionId + 1;
        bool isStaticScopeRoot = address(staticScopeConnector) == address(connector);
        (bool hasStaticLocal, uint32 staticStartPoint, uint32 staticTransformShift) = isStaticScopeRoot
            ? connector.getStaticRunningInstance(staticScopePositionId)
            : connector.getStaticRunningInstance(dimId + 1);

        bool hasStaticScope = false;
        uint32 staticScopeStartPoint = 0;
        uint32 staticScopeTransformShift = 0;
        if(isStaticScopeRoot == false)
        {
            (hasStaticScope, staticScopeStartPoint, staticScopeTransformShift) =
                staticScopeConnector.getStaticRunningInstance(staticScopePositionId);
        }

        if(hasDynamic && (hasStaticLocal || hasStaticScope))
        {
            revert RunningInstanceStaticOverride(positionId);
        }

        if(hasDynamic)
        {
            return dynamicRunningInstance;
        }

        if(hasStaticLocal)
        {
            return RunningInstance({
                startPoint: staticStartPoint,
                transformShift: staticTransformShift
            });
        }

        if(hasStaticScope)
        {
            return RunningInstance({
                startPoint: staticScopeStartPoint,
                transformShift: staticScopeTransformShift
            });
        }

        if(address(fallbackCompositeConnector) != address(0))
        {
            (bool hasChildRoot, uint32 childRootStartPoint, uint32 childRootTransformShift) = fallbackCompositeConnector.getStaticRunningInstance(0);
            if(hasChildRoot)
            {
                return RunningInstance({
                    startPoint: childRootStartPoint,
                    transformShift: childRootTransformShift
                });
            }
        }

        runningInstance.startPoint = 0;
        runningInstance.transformShift = 0;
        return runningInstance;
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

        Binding memory emptyBinding;
        return (false, emptyBinding);
    }

    function findProjectedChildSlot(
        uint32 localSlotId,
        uint32[] memory projectedStarts,
        uint32[] memory projectedWidths,
        uint32[] memory projectedChildSlotIds,
        uint32 projectedCount
    ) private pure returns (bool found, uint32 childSlotId, uint32 rangeStart)
    {
        if(projectedCount == 0)
        {
            return (false, 0, 0);
        }

        // Binary search for right-most projected start <= localSlotId.
        uint32 low = 0;
        uint32 high = projectedCount;
        while(low < high)
        {
            uint32 mid = low + (high - low) / 2;
            if(projectedStarts[mid] <= localSlotId)
            {
                low = mid + 1;
            }
            else
            {
                high = mid;
            }
        }

        if(low == 0)
        {
            return (false, 0, 0);
        }

        uint32 projectedIndex = low - 1;
        uint32 start = projectedStarts[projectedIndex];
        uint32 width = projectedWidths[projectedIndex];
        uint32 endExclusive = start + width;
        if(localSlotId < start || localSlotId >= endExclusive)
        {
            return (false, 0, 0);
        }

        return (true, projectedChildSlotIds[projectedIndex], start);
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

        // Child slot bindings selected at this level (static defaults + forwarded exact hits).
        IConnector[] memory slotSelectedComposites = new IConnector[](childOpenSlots);
        IConnector[] memory slotStaticComposites = new IConnector[](childOpenSlots);

        // Forwarded bindings attached to an unbound slot replacement.
        Binding[][] memory unboundReplacementForwarded = new Binding[][](childOpenSlots);

        // Only non-empty projected ranges are included here.
        // Arrays are sorted by projectedStarts and used for binary search lookup.
        uint32[] memory projectedChildSlotIds = new uint32[](childOpenSlots);
        uint32[] memory projectedStarts = new uint32[](childOpenSlots);
        uint32[] memory projectedWidths = new uint32[](childOpenSlots);
        uint32 projectedCount = 0;

        for(uint32 childSlotId = 0; childSlotId < childOpenSlots; ++childSlotId)
        {
            uint32 slotProjectedStart = childOpenSlotsInParent;

            IConnector staticBoundComposite = connector.getBindingComposite(dimId, childSlotId);
            if(address(staticBoundComposite) != address(0))
            {
                slotStaticComposites[childSlotId] = staticBoundComposite;
                slotSelectedComposites[childSlotId] = staticBoundComposite;

                uint32 staticSlots = staticBoundComposite.getOpenSlotsCount();
                if(staticSlots > 0)
                {
                    projectedChildSlotIds[projectedCount] = childSlotId;
                    projectedStarts[projectedCount] = slotProjectedStart;
                    projectedWidths[projectedCount] = staticSlots;
                    projectedCount += 1;
                }
                childOpenSlotsInParent += staticSlots;
                continue;
            }

            projectedChildSlotIds[projectedCount] = childSlotId;
            projectedStarts[projectedCount] = slotProjectedStart;
            projectedWidths[projectedCount] = 1;
            projectedCount += 1;
            childOpenSlotsInParent += 1;
        }

        // Count forwarded bindings per static slot to allocate exact-sized arrays.
        uint32[] memory slotForwardedCounts = new uint32[](childOpenSlots);

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

            (bool found, uint32 childSlotId, ) = findProjectedChildSlot(
                localSlotId,
                projectedStarts,
                projectedWidths,
                projectedChildSlotIds,
                projectedCount);
            if(found == false)
            {
                continue;
            }

            IConnector staticComposite = slotStaticComposites[childSlotId];
            if(address(staticComposite) == address(0))
            {
                // Unbound projected point: direct slot binding.
                // Preserve first assignment to keep consistency with
                // findBoundBinding (first match wins).
                if(address(slotSelectedComposites[childSlotId]) == address(0))
                {
                    slotSelectedComposites[childSlotId] = parentBinding.composite;
                    unboundReplacementForwarded[childSlotId] = parentBinding.forwarded;
                }
                continue;
            }

            // Static projected range: bind inside static composite by local DFS offset.
            slotForwardedCounts[childSlotId] += 1;
        }

        // Allocate exact-sized forwarded arrays only for static slots.
        Binding[][] memory slotForwardedTemp = new Binding[][](childOpenSlots);
        for(uint32 childSlotId = 0; childSlotId < childOpenSlots; ++childSlotId)
        {
            if(address(slotStaticComposites[childSlotId]) == address(0))
            {
                continue;
            }

            slotForwardedTemp[childSlotId] = new Binding[](slotForwardedCounts[childSlotId]);
        }

        // Fill forwarded arrays in a second pass, preserving parent binding order.
        uint32[] memory slotForwardedWriteIndices = new uint32[](childOpenSlots);
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

            (bool found, uint32 childSlotId, uint32 rangeStart) = findProjectedChildSlot(
                localSlotId,
                projectedStarts,
                projectedWidths,
                projectedChildSlotIds,
                projectedCount);
            if(found == false || address(slotStaticComposites[childSlotId]) == address(0))
            {
                continue;
            }

            uint32 writeIndex = slotForwardedWriteIndices[childSlotId];
            slotForwardedTemp[childSlotId][writeIndex] = Binding({
                slotId: localSlotId - rangeStart,
                composite: parentBinding.composite,
                forwarded: parentBinding.forwarded
            });
            slotForwardedWriteIndices[childSlotId] = writeIndex + 1;
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
                forwardedBindings = slotForwardedTemp[childSlotId];
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
        uint32 runningInstancePositionId,
        uint32[] memory indexes,
        uint32 dest,
        DecomposeContext memory context
    ) private view returns (DecomposeResult memory)
    {
        BindingSet memory emptyBindings = BindingSet({
            entries: new Binding[](0)
        });

        return decompose(
            path,
            connector,
            runningInstancePositionId,
            indexes,
            dest,
            context,
            emptyBindings);
    }

    function decompose(
        string memory path,
        IConnector connector,
        uint32 runningInstancePositionId,
        uint32[] memory indexes,
        uint32 dest,
        DecomposeContext memory context,
        BindingSet memory bindings
    ) view private returns (DecomposeResult memory)
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

            IConnector directCompositeConnector = connector.getComposite(dimId);
            bool isBound = false;
            Binding memory boundBinding;
            IConnector fallbackCompositeConnector = directCompositeConnector;
            if(address(directCompositeConnector) == address(0))
            {
                // Scalar slot may be replaced by a bound connector.
                // Use that effective connector for static child-root RI fallback.
                (isBound, boundBinding) = findBoundBinding(bindings, openSlotId);
                if(isBound)
                {
                    fallbackCompositeConnector = boundBinding.composite;
                }
            }

            uint32 positionId = runningInstancePositionId;
            runningInstancePositionId += 1;
            runningInstance = resolveDimensionRunningInstance(
                connector,
                dimId,
                positionId,
                context,
                fallbackCompositeConnector);

            // we always need to calculate elements from dimension
            // when compound connector is present it passes it as indexes to further decompose
            // when scalar we can fill out buffer
            compositeIndexes = collectParticleSpace(connector, dimId, runningInstance, indexes);

            if(address(directCompositeConnector) == address(0))
            {
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
                DecomposeResult memory replacementResult = decompose(
                    compositePath,
                    boundBinding.composite,
                    runningInstancePositionId,
                    compositeIndexes,
                    dest,
                    context,
                    replacementBindings);
                dest = replacementResult.dest;
                runningInstancePositionId = replacementResult.nextPositionId;

                continue;
            }

            uint32 childOpenSlots = directCompositeConnector.getOpenSlotsCount();
            (BindingSet memory childBindings, uint32 childOpenSlotsConsumed) = buildChildBindings(
                connector,
                dimId,
                bindings,
                openSlotId,
                childOpenSlots);

            // recurse into child with static + forwarded bindings
            DecomposeResult memory childResult = decompose(
                compositePath,
                directCompositeConnector,
                runningInstancePositionId,
                compositeIndexes,
                dest,
                context,
                childBindings);
            dest = childResult.dest;
            runningInstancePositionId = childResult.nextPositionId;

            // from parent perspective child contributes all open slots after static bindings are applied
            openSlotId += childOpenSlotsConsumed;
        }

        assert(openSlotId == connector.getOpenSlotsCount());
        return DecomposeResult({
            dest: dest,
            nextPositionId: runningInstancePositionId
        });
    }

    function gen(string memory name, uint32 particlesCount, PositionedRunningInstance[] memory dynamicRi) external view returns (Particles[] memory)
    {
        require(particlesCount > 0, "number of particles must be greater than 0");
        require(_registry.containsConnector(name), "cannot find connector");

        for(uint32 i = 1; i < dynamicRi.length; ++i)
        {
            uint32 previousPosition = dynamicRi[i - 1].position;
            uint32 position = dynamicRi[i].position;
            if(previousPosition == position)
            {
                revert RunningInstanceDuplicate(position);
            }
            if(previousPosition > position)
            {
                revert RunningInstanceNotSorted(previousPosition, position);
            }
        }

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
        (RunningInstance memory rootRunningInstance, uint32 dynamicRiIndex) = resolveRootRunningInstance(connector, dynamicRi, 0);
        uint32 start = rootRunningInstance.startPoint;

        uint32[] memory indexes = new uint32[](particlesCount);
        for(uint32 i = 0; i < particlesCount; ++i)
        {
            indexes[i] = i + start;
        }

        DecomposeContext memory context = DecomposeContext({
            dynamicRi: dynamicRi,
            dynamicRiIndex: dynamicRiIndex,
            outBuffer: particlesBuffer,
            staticScopeConnector: connector,
            staticScopeStartPositionId: 1
        });
        DecomposeResult memory result = decomposeWithoutBindings("", connector, 1, indexes, 0, context);
        assert(result.dest == numberOfScalars);

        return particlesBuffer;
    }
}
