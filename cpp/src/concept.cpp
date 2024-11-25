#include <concept.hpp>

namespace pt
{
    Concept::Concept(pt::Registry & reg, std::string name, std::vector<std::string> composites)
    : _reg{reg}, _name{std::move(name)}, _opsCallDef{composites.size()}
    {
        std::cout << std::format("ctor concept {}", Name()) << std::endl;

        for(const auto & composite : composites)
        {
            auto cn = _reg.ConceptAt(composite);
            std::cout << std::format("fetching composite {} [{}]", composite, (void*)cn) << std::endl;

            _composites.emplace_back(cn);
        }

        _operands.resize(_opsCallDef.DimensionsCount());

        if(_composites.empty())
        {
            _scalars = 1;
            _subTreeSize = 0;
        }
        else 
        {
            _scalars = 0;
            _subTreeSize = _composites.size();
            for(const auto & composite : _composites)
            {
                _scalars += composite->GetScalarsCount();
                _subTreeSize += composite->GetSubTreeCount();
            }
        }
    }
            
    const std::string& Concept::Name() const 
    { 
        return _name;
    }

    CallDef & Concept::OpsCallDef()
    {
        return _opsCallDef;
    }

    void Concept::InitOperands()
    {
        for(std::size_t dimId = 0; dimId < _opsCallDef.DimensionsCount(); ++dimId)
        {
            _operands.at(dimId).reserve(_opsCallDef.OperandsCount(dimId));
            for(std::size_t opId = 0; opId < _opsCallDef.OperandsCount(dimId); ++opId)
            {
                auto op = _reg.OperandAt(_opsCallDef.Name(dimId, opId));
                _operands.at(dimId).emplace_back(std::move(op));
            }
        }
    }

    std::vector<std::vector<Idx>> Concept::Gen(const std::vector<Idx> & startPoints, std::size_t N) const
    {
        std::vector<std::vector<Idx>> outBuffer;
        outBuffer.resize(GetScalarsCount());
        for(auto & row : outBuffer)
        {
            row.resize(N);
            std::fill(row.begin(), row.end(), 0);
        }

        Idx start = 0;
        std::vector<Idx> indexes;
        indexes.reserve(N);
        for(std::size_t i = 0; i < N; ++i)
        {
            indexes.emplace_back(i + start);
        }

        std::cout << std::format("Gen {}, [{}]", Name(), N) << std::endl;

        Decompose(startPoints, 0, indexes, 0, outBuffer);

        return outBuffer;
    }

    bool Concept::isScalar() const
    {
        return _composites.empty();
    }

    std::size_t Concept::GetScalarsCount() const
    {
        return _scalars;
    }
    std::size_t Concept::GetCompositesCount() const
    {
        return _composites.size();
    }

    std::size_t Concept::GetSubTreeCount() const
    {
        return _subTreeSize;
    }

    Idx Concept::Transform(std::size_t dimId, std::size_t opId, Idx x) const
    {
        opId %= _operands.at(dimId).size();
        return (*_operands.at(dimId).at(opId))(x, _opsCallDef.Args(dimId, opId));
    }

    std::vector<Idx> Concept::GenSubconceptSpace(std::size_t dimId, Idx start, std::size_t N) const
    {
        std::cout << std::format("GenSubconceptSpace [{}], with size {}, starting value {} ",  dimId, N, start) << std::endl;

        std::vector<Idx> space;
        space.resize(N);

        Idx x = start;
        for(std::size_t opId = 0; opId < N; ++opId)
        {
            space.at(opId) = x;
            x = Transform(dimId, opId, x);
        }
        return space;
    }

    std::vector<Idx> Concept::GenSubconceptIndexes(std::size_t dimId, Idx start, const std::vector<Idx> & samplesIndexes) const
    {
        std::vector<Idx> compositeIndexes;
        compositeIndexes.resize(samplesIndexes.size());        

        const std::size_t N = *std::ranges::max_element(samplesIndexes) + 1;
        const std::vector<Idx> subspace = GenSubconceptSpace(dimId, start, N);

        // sample composite subspace
        for(std::size_t i = 0; i < compositeIndexes.size(); ++i)
        {
            compositeIndexes.at(i) = subspace.at(samplesIndexes.at(i));
        }

        return compositeIndexes;
    }

    void Concept::Decompose(const std::vector<Idx> & startPoints, std::size_t startPointId, const std::vector<Idx> & samplesIndexes, std::size_t dest, std::vector<std::vector<Idx>> & outBuffer) const
    {
        if(isScalar()){
            std::cout << std::format("Save {}, at dest [{}]", Name(), dest) << std::endl;

            for(std::size_t i = 0; i < outBuffer.at(dest).size(); ++i){
                outBuffer.at(dest).at(i) = samplesIndexes.at(i);
            }
            return;
        }

        std::cout << std::format("Decompose {}, at dest [{}]", Name(), dest) << std::endl;

        Idx start = 0;

        // for every composite run decompose at designated buffer index
        std::vector<Idx> compositeIndexes;
        for(std::size_t dimId = 0; dimId < _composites.size(); ++dimId)
        {
            if(startPointId < startPoints.size())start = startPoints.at(startPointId);

            compositeIndexes = GenSubconceptIndexes(dimId, start, samplesIndexes);

            Concept * subconcept = _composites.at(dimId);
            // recursivly fill out buffer range
            subconcept->Decompose(startPoints, startPointId + 1, compositeIndexes, dest, outBuffer);
            // shift buffer index
            dest += subconcept->GetScalarsCount();
            // shift start point
            startPointId += subconcept->GetSubTreeCount();
        }
    }
}