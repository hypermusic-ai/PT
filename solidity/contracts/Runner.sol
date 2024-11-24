// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Concept.sol";

contract Runner
{
    Registry private _registry;

    constructor(address registryAddr) 
    {
        _registry = Registry(registryAddr);
    }

    function printSamples(uint32[][] memory samplesBuffer)pure private 
    {
        string memory samplesStr;
        for(uint32 i = 0; i < samplesBuffer.length; ++i)
        {
            samplesStr = "";
            for(uint32 n = 0; n < samplesBuffer[i].length; ++n)
            {
                samplesStr = string.concat(samplesStr, " ");
                samplesStr = string.concat(samplesStr, Strings.toString((uint256)(samplesBuffer[i][n])));
            }
            console.log("scalar ID ", i, " = ", samplesStr);
        }
    }

    function decompose(Concept concept, uint32[] memory startPoints, uint32 startPointId, uint32[] memory indexes, uint32 dest, uint32[][] memory outBuffer) view private
    {
        require(dest < outBuffer.length, "buffer to small");
    
        if(concept.isScalar()){
            console.log(concept.getName(), " is scalar concept, saving concept samples on destination ", dest);
            for(uint i = 0; i < outBuffer[dest].length; ++i){
                outBuffer[dest][i] = indexes[i];
            }
            return;
        }

        console.log(concept.getName(), " is a composite concept, perform decomposition");

        // from which starting point should we generate actual composite concept
        uint32 start = 0;

        uint32[] memory compositeIndexes;

        // for every composite run decompose at designated buffer index
        for(uint32 dimId = 0; dimId < concept.getCompositesCount(); ++dimId)
        {
            if(startPointId < startPoints.length)start = startPoints[startPointId];

            // generate given composite concept elements from given starting point
            compositeIndexes = concept.genSubconceptIndexes(dimId, start, indexes);

            Concept subconcept = concept.getComposite(dimId);

            // recursivly fill out buffer range
            decompose(subconcept, startPoints, startPointId, compositeIndexes, dest, outBuffer);

            // shift buffer index
            dest += subconcept.getScalarsCount();

            //shift starting point
            startPointId += subconcept.getSubTreeSize() + 1;
        }
    }

    function gen(string memory name, uint32 N, uint32[] memory startPoints) view external returns (uint32[][] memory)
    {
        require(N > 0, "number of samples must be greater than 0");
        require(_registry.containsConcept(name), "cannot find concept");

        Concept concept = _registry.conceptAt(name);

        uint32 numberOfScalars = concept.getScalarsCount();
        assert(numberOfScalars > 0);

        // allocate memory for scalar data
        uint32[][] memory samplesBuffer = new uint32[][](numberOfScalars);
        for(uint32 i=0; i < numberOfScalars; ++i)
        {
            samplesBuffer[i] = new uint32[](N);
        }

        console.log("buffer allocated ", samplesBuffer.length, "x", samplesBuffer[0].length);

        // we will generate sequential list of N objects from actual concept
        // generate 0th element from conept
        // generate 1st el from cn
        //...
        // gen (N-1)th el from cn
        // to generate 0th element from concept we need to specify from which starting points 
        // should it generate all of its composite concepts
        // it will give us the FIRST generated element of that particular generate call
        uint32 start = 0;
        if(startPoints.length > 0)start = startPoints[0];

        uint32[] memory indexes = new uint32[](N);
        for(uint32 i = 0; i < N; ++i)
        {
            indexes[i] = i + start;
        }

        decompose(concept, startPoints, 1, indexes, 0, samplesBuffer);
        
        printSamples(samplesBuffer);

        return (samplesBuffer);
    }
}