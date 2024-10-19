// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "./Concept.sol";

contract Runner
{
    Registry private _registry;

    constructor(address registryAddr) 
    {
        _registry = Registry(registryAddr);
    }

    function generateConceptSubspace(Concept concept, uint32 dimId, uint32 maxIndex) private view returns (uint32[] memory)
    {
        uint32[] memory space = new uint32[](maxIndex + 1);

        uint32 x = 0;
        // generate space including maxIndex
        for(uint32 opId = 0; opId <= maxIndex; ++opId)
        {
            space[opId] = x;
            x = concept.transform(dimId, opId, x);
        }

        return space;
    }

    function decompose(Concept concept, uint32[] memory indexes, uint32 dest, uint32[][] memory outBuffer) view private
    {
        console.log("decompose ", concept.getName());
    
        if(concept.isScalar()){
            console.log("decompose scalar, saving samples in buffer at location [", dest, "]");

            // store samples for dimension at buffer index
            for(uint i = 0; i < outBuffer[dest].length; ++i){
                outBuffer[dest][i] = indexes[i];
                console.log("saving sample ", concept.getName(), " with value ", outBuffer[dest][i]);
            }
            return;
        }

        // calculate space requirements
        uint32 maxIndex = 0;
        for(uint32 i = 0; i < indexes.length; ++i)
        {
            console.log("sample ", concept.getName(), "at", indexes[i]);
            if(indexes[i] > maxIndex){maxIndex = indexes[i];}
        }
        console.log(concept.getName(), "is a composite concept");

        uint32[] memory subspace;
        uint32[] memory compositeIndexes = new uint32[](indexes.length);

        // for every composite run decompose at designated buffer index
        for(uint32 dimId = 0; dimId < concept.getCompositesCount(); ++dimId)
        {
            console.log("generate subspace up to index [", maxIndex, "] for composite", concept.getComposite(dimId).getName());
            // generate subspace for composite concept, up to its maxIndex sample
            subspace = generateConceptSubspace(concept, dimId, maxIndex);

            // sample subspace of composite
            for(uint32 i = 0; i < indexes.length; ++i)
            {
                compositeIndexes[i] = subspace[indexes[i]];
            }

            // recursivly fill out buffer range
            decompose(concept.getComposite(dimId), compositeIndexes, dest, outBuffer);

            // shift buffer index
            dest += concept.getComposite(dimId).getScalarsCount();
        }

    }

    function gen(uint32 N, Concept concept) view external returns (uint32[][] memory)
    {
        require(N > 0, "number of samples must be greater than 0");
        
        uint32 numberOfScalars = concept.getScalarsCount();
        assert(numberOfScalars > 0);

        uint32[][] memory samplesBuffer = new uint32[][](numberOfScalars);
        // allocate memory for scalar data
        for(uint32 i=0; i < numberOfScalars; ++i)
        {
            samplesBuffer[i] = new uint32[](N);
        }

        console.log("buffer allocated ", samplesBuffer.length, "x", samplesBuffer[0].length);

        // TODO 
        uint32[] memory indexes = new uint32[](N);
        for(uint32 i=0; i<N; ++i)
        {
            indexes[i] = i;
        }

        decompose(concept, indexes, 0, samplesBuffer);
        
        for(uint32 i = 0; i < numberOfScalars; ++i)
        {
            console.log("scalar ID ", i);
            for(uint32 n = 0; n < N; ++n)
            {
                console.log(samplesBuffer[i][n]);
            }
        }

        return (samplesBuffer);
    }
}