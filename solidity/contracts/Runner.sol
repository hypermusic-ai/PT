// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./feature/IFeature.sol";
import "./registry/IRegistry.sol";

struct RunningInstance {
    uint32 startPoint;
    uint32 transformShift;
}

struct Samples
{
    string feature_path;
    uint32[] data;
}

interface IRunner
{
    function gen(string memory name, uint32 N, RunningInstance[] memory runningInstances) external returns (Samples[] memory);
}

event Debug(string label, string value);

contract Runner is IRunner
{
    IRegistry private _registry;

    constructor(address registryAddr) 
    {
        _registry = IRegistry(registryAddr);
    }

    function generateSubfeatureSpace(IFeature feature, uint32 dimId, RunningInstance memory runningInstance, uint32 N) private returns (uint32[] memory)
    {
        emit Debug("generateSubfeatureSpace", "");

        require(dimId < feature.getCompositesCount(), "invalid dimension id");

        uint32[] memory space = new uint32[](N);

        uint32 x = runningInstance.startPoint;
        for(uint32 opId = 0; opId < N; ++opId)
        {
            space[opId] = x;
            x = feature.transform(dimId, opId + runningInstance.transformShift, x);
        }

        return space;
    }

    function genSubfeatureIndexes(IFeature feature, uint32 dimId, RunningInstance memory runningInstance, uint32[] memory samplesIndexes) private returns (uint32[] memory)
    {
        uint32[] memory subspace;
        uint32[] memory compositeIndexes = new uint32[](samplesIndexes.length);
        
        // need to generate subspace from 0 up to max(samplesIndexes) + 1
        uint32 subspaceSize = 0;
        for(uint32 i = 0; i < samplesIndexes.length; ++i)
        {
            if(samplesIndexes[i] > subspaceSize)subspaceSize = samplesIndexes[i];
        }
        subspaceSize += 1;
        emit Debug("genSubfeatureIndexes subspaceSize", Strings.toString(subspaceSize));

        // because we need to sample from this space element [max(samplesIndexes)]
        subspace = generateSubfeatureSpace(feature, dimId, runningInstance, subspaceSize);

        // sample composite subspace
        for(uint32 i = 0; i < compositeIndexes.length; ++i)
        {
            compositeIndexes[i] = subspace[samplesIndexes[i]];
        }

        return compositeIndexes;
    }

    function decompose(string memory path, IFeature feature, RunningInstance[] memory runningInstances, uint32 runningInstanceId, uint32[] memory indexes, uint32 dest, Samples[] memory outBuffer) private
    {
        require(dest < outBuffer.length, "buffer to small");
        require(feature.checkCondition(), "feature condition not met"); // feature check condition

        string memory current_path = string(abi.encodePacked(path, "/", feature.getName()));

        if(feature.isScalar())
        {
            outBuffer[dest].feature_path = current_path;
            for(uint i = 0; i < outBuffer[dest].data.length; ++i){
                outBuffer[dest].data[i] = indexes[i];
            }
            // feature condition update
            return;
        }

        // from which starting point should we generate actual composite feature
        RunningInstance memory runningInstance;

        uint32[] memory compositeIndexes;
        
        emit Debug("decompose loop start", feature.getName());

        require(runningInstances.length == 0 ||  runningInstances.length >= feature.getTreeSize(),
            "wrong number of running instances");
        
        // for every composite run decompose at designated buffer index
        for(uint32 dimId = 0; dimId < feature.getCompositesCount(); ++dimId)
        {
            IFeature subfeature = feature.getComposite(dimId);
            emit Debug("decompose subfeature", subfeature.getName());
            emit Debug("runningInstanceId", Strings.toString(runningInstanceId));

            if(runningInstanceId < runningInstances.length)
            {
                runningInstance = runningInstances[runningInstanceId];
            }
            else
            {
                emit Debug("runningInstanceId to big!", Strings.toString(runningInstanceId));
                runningInstance.startPoint = 0;
                runningInstance.transformShift = 0;
            }

            // generate given composite feature elements from given starting point
            compositeIndexes = genSubfeatureIndexes(feature, dimId, runningInstance, indexes);

            // recursivly fill out buffer range
            // runningInstanceId + 1 because we we took current runningInstance for parent feature
            decompose(current_path, subfeature, runningInstances, runningInstanceId + 1, compositeIndexes, dest, outBuffer);

            // shift buffer index
            dest += subfeature.getScalarsCount();
            // 
            runningInstanceId += subfeature.getTreeSize();
        }
        
        emit Debug("decompose loop end", feature.getName());

        // feature condition update
        //feature.updateCondition();
    }

    function gen(string memory name, uint32 N, RunningInstance[] memory runningInstances) external returns (Samples[] memory)
    {
        emit Debug("gen called", Strings.toString(N));

        require(N > 0, "number of samples must be greater than 0");
        require(_registry.containsFeature(name), "cannot find feature");

        IFeature feature = _registry.getFeature(name);

        uint32 numberOfScalars = feature.getScalarsCount();
        assert(numberOfScalars > 0);
        emit Debug("numberOfScalars", Strings.toString(numberOfScalars));

        if(runningInstances.length != 0)require(runningInstances.length == feature.getTreeSize(), "wrong number of running instances");
        emit Debug("getTreeSize", Strings.toString(feature.getTreeSize()));

        // allocate memory for scalar data
        Samples[] memory samplesBuffer = new Samples[](numberOfScalars);
        for(uint32 i = 0; i < numberOfScalars; ++i)
        {
            samplesBuffer[i].data = new uint32[](N);
        }

        // we will generate sequential list of N objects from actual feature
        // generate 0th element from conept
        // generate 1st el from cn
        //...
        // gen (N-1)th el from cn
        // to generate 0th element from feature we need to specify from which starting points 
        // should it generate all of its composite features
        // it will give us the FIRST generated element of that particular generate call
        uint32 start = 0;
        if(runningInstances.length > 0) 
        {
            start = runningInstances[0].startPoint;
        }

        uint32[] memory indexes = new uint32[](N);
        for(uint32 i = 0; i < N; ++i)
        {
            indexes[i] = i + start;
        }

        decompose("", feature, runningInstances, 1, indexes, 0, samplesBuffer);
        
        return (samplesBuffer);
    }
}