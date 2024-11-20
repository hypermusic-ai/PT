#include <concept.hpp>


namespace pt
{
    Concept::Concept(pt::Registry & reg, std::string name, std::vector<std::string> composites, std::vector<std::vector<std::function<pt::Idx(pt::Idx)>>> ops)
    : _name{std::move(name)}, _ops {std::move(ops)}
    {
        std::cout << std::format("ctor concept {}", Name()) << std::endl;

        for(const auto & composite : composites)
        {
            auto cn = reg.At(composite);
            std::cout << std::format("fetching composite {} [{}]", composite, (void*)cn) << std::endl;

            _composites.emplace_back(cn);
        }
    
        if(_composites.empty())
        {
            _scalars = 1;
        }
        else 
        {
            _scalars = 0;
            for(const auto & composite : _composites)
            {
                _scalars += composite->GetScalarsCount();
            }
        }
    }
            
    const std::string& Concept::Name() const 
    { 
        return _name;
    }

    std::vector<std::vector<Idx>> Concept::Gen(const std::vector<Idx> & startPoints, std::size_t N)
    {
        std::vector<std::vector<Idx>> outBuffer;
        outBuffer.resize(GetScalarsCount());
        for(auto & row : outBuffer)
        {
            row.resize(N);
            std::fill(row.begin(), row.end(), 0);
        }

        // generate indexes range [startPoints[0],  N-1]
        std::vector<Idx> indexes;
        indexes.reserve(N);
        for(std::size_t i = 0; i < N; ++i)
        {
            indexes.emplace_back(startPoints[0] + i);
        }

        std::cout << std::format("Gen {}, [{}]", Name(), N) << std::endl;

        Decompose(startPoints, indexes, 0, outBuffer);

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

    Idx Concept::Transform(std::size_t dimId, std::size_t opId, Idx x) const
    {
        opId %= _ops.at(dimId).size();
        return _ops[dimId][opId](x);
    }

    std::vector<Idx> Concept::GenSubconceptSpace(std::size_t dimId, Idx start, std::size_t N) const
    {
        std::cout << std::format("GenSubconceptSpace [{}], from [{}] with size [{}]",  dimId, start, N) << std::endl;

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

        // need to generate subspace containing at least max_element
        
        const std::size_t N = (*std::ranges::max_element(samplesIndexes) - start) + 1;
        std::cout << std::format("GenSubconceptIndexes {}, need to generate subspace from [{}] with {} elements (up to [{}])", dimId, start, N, start + N) << std::endl;

        const std::vector<Idx> subspace = GenSubconceptSpace(dimId, start, N);

        // sample composite subspace
        for(std::size_t i = 0; i < compositeIndexes.size(); ++i)
        {
            compositeIndexes.at(i) = subspace.at(samplesIndexes.at(i) - start);
        }
        return compositeIndexes;
    }

    void Concept::Decompose(const std::vector<Idx> & startPoints, const std::vector<Idx> & samplesIndexes, std::size_t dest, std::vector<std::vector<Idx>> & outBuffer) const
    {
        std::cout << std::format("Decompose {}, at dest [{}]", Name(), dest) << std::endl;

        if(isScalar()){
            for(std::size_t i = 0; i < outBuffer.at(dest).size(); ++i){
                outBuffer.at(dest).at(i) = samplesIndexes.at(i);
            }
            return;
        }

        // for every composite run decompose at designated buffer index
        Idx start = 0;
        if(dest < startPoints.size())start = startPoints.at(dest);

        std::vector<Idx> compositeIndexes;
        for(std::size_t dimId = 0; dimId < _composites.size(); ++dimId)
        {
            compositeIndexes = GenSubconceptIndexes(dimId, start, samplesIndexes);

            Concept * subconcept = _composites.at(dimId);
            // recursivly fill out buffer range
            subconcept->Decompose(startPoints, compositeIndexes, dest, outBuffer);
            // shift buffer index
            dest += subconcept->GetScalarsCount();
        }
    }
}