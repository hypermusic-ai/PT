// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "../particle/IParticle.sol";
import "../registry/IRegistry.sol";
import "../error/Error.sol";
import "../ownable/OwnableBase.sol";

import "@openzeppelin/contracts/utils/Strings.sol";


struct RunningInstance {
    uint32 startPoint;
    uint32 transformShift;
}

struct Samples
{
    string path;
    uint32[] data;
}

interface IRunner
{
    function gen(string memory name, uint32 samplesCount, RunningInstance[] memory runningInstances) external view returns (Samples[] memory);
}

contract Runner is IRunner, OwnableBase
{
    IRegistry private _registry;

    function initialize(address registryAddr) external initializer {
        __OwnableBase_init(msg.sender);
        _registry = IRegistry(registryAddr);
    }

    function genSpace(IFeature feature, uint32 dimId, RunningInstance memory runningInstance, uint32 samplesCount) private view returns (uint32[] memory)
    {
        assert(dimId < feature.getDimensionsCount());

        uint32[] memory space = new uint32[](samplesCount);

        uint32 x = runningInstance.startPoint;
        for(uint32 opId = 0; opId < samplesCount; ++opId)
        {
            space[opId] = x;
            // calculate next element in space
            x = feature.transform(dimId, opId + runningInstance.transformShift, x);
        }

        return space;
    }

    function sampleSpace(IFeature feature, uint32 dimId, RunningInstance memory runningInstance, uint32[] memory samplesIndexes) private view returns (uint32[] memory)
    {   
        assert(dimId < feature.getDimensionsCount());

        // need to generate space from 0 up to max(samplesIndexes) + 1
        // we find last index which will be sampled
        uint32 spaceSize = 0;
        for(uint32 i = 0; i < samplesIndexes.length; ++i)
        {
            if(samplesIndexes[i] > spaceSize)spaceSize = samplesIndexes[i];
        }
        spaceSize += 1;

        // generate space
        uint32[] memory space;
        // because we need to sample from this space element [max(samplesIndexes)]
        space = genSpace(feature, dimId, runningInstance, spaceSize);

        // perform sampling from space
        uint32[] memory elements = new uint32[](samplesIndexes.length);
        for(uint32 i = 0; i < samplesIndexes.length; ++i)
        {
            elements[i] = space[samplesIndexes[i]];
        }

        return elements;
    }

    function decompose(string memory path, IParticle particle, RunningInstance[] memory runningInstances, uint32 runningInstanceId, uint32[] memory indexes, uint32 dest, Samples[] memory outBuffer) view private
    {
        assert(dest < outBuffer.length);

        if(particle.checkCondition() == false)
        {
            revert ConditionNotMet(keccak256(bytes(particle.getName())));
        }

        string memory basePath = string(abi.encodePacked(path, "/", particle.getName()));

        IFeature rooFeature = particle.getRootFeature();
        
        // from which starting point should we generate actual composite feature
        RunningInstance memory runningInstance;

        // buffer for indexes
        uint32[] memory compositeIndexes;
        
        // for every composite run decompose at designated buffer index
        for(uint32 dimId = 0; dimId < particle.getCompositesCount(); ++dimId)
        {
            string memory compositePath = string(abi.encodePacked(basePath, ":", Strings.toString(dimId)));

            // calculate running instance values first
            if(runningInstanceId < runningInstances.length)
            {
                runningInstance = runningInstances[runningInstanceId];
                // shift running instance
                runningInstanceId += 1;
            }
            else
            {
                runningInstance.startPoint = 0;
                runningInstance.transformShift = 0;
            }

            // we always need to calculate elements from dimension
            // when compound feature is present it passes it as indexes to further decompose 
            // when scalar we can fill out buffer
            compositeIndexes = sampleSpace(rooFeature, dimId, runningInstance, indexes);

            IParticle compositeParticle = particle.getComposite(dimId);

            if(address(compositeParticle) == address(0))
            {
                assert(dest < outBuffer.length);
                // scalar, we can fill out buffer
                assert(compositeIndexes.length == outBuffer[dest].data.length);

                outBuffer[dest].path = compositePath;
                outBuffer[dest].data = compositeIndexes;
            
                // shift buffer index
                dest += 1;

                continue;
            }


            // we are in case in which composite dimension is linked to another particle

            // recursively fill out buffer range
            // runningInstanceId + 1 because we we took current runningInstance for parent feature
            // our generated composite indexes become indexes for child particle
            decompose(compositePath, compositeParticle, runningInstances, runningInstanceId, compositeIndexes, dest, outBuffer);

            dest += compositeParticle.getScalarsCount();
        }
    }

    function gen(string memory name, uint32 samplesCount, RunningInstance[] memory runningInstances) external view returns (Samples[] memory)
    {
        require(samplesCount > 0, "number of samples must be greater than 0");
        require(_registry.containsParticle(name), "cannot find particle");

        IParticle particle = _registry.getParticle(name);

        uint32 numberOfScalars = particle.getScalarsCount();
        assert(numberOfScalars > 0);

        // allocate memory for scalar data
        Samples[] memory samplesBuffer = new Samples[](numberOfScalars);
        for(uint32 i = 0; i < numberOfScalars; ++i)
        {
            samplesBuffer[i].data = new uint32[](samplesCount);
        }

        // we will generate sequential list of samplesCount objects from actual particle
        // generate 0th element from particle
        // generate 1st el from particle
        //...
        // gen (samplesCount-1)th el from particle
        // to generate 0th element from particle we need to specify from which starting points 
        // should it generate all of its composite particles
        // it will give us the FIRST generated element of that particular generate call
        uint32 start = 0;
        if(runningInstances.length > 0) 
        {
            start = runningInstances[0].startPoint;
        }

        uint32[] memory indexes = new uint32[](samplesCount);
        for(uint32 i = 0; i < samplesCount; ++i)
        {
            indexes[i] = i + start;
        }

        decompose("", particle, runningInstances, 1, indexes, 0, samplesBuffer);
        
        return (samplesBuffer);
    }
}
