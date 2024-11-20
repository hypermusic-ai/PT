#pragma once

#include <string>
#include <vector>
#include <algorithm>
#include <functional>
#include <iostream>
#include <format>

#include <registry.hpp>

namespace pt
{
    using Idx = std::size_t;    

    class Concept
    {
        public:
            Concept(pt::Registry & reg, std::string name, std::vector<std::string> composites = {}, std::vector<std::vector<std::function<pt::Idx(pt::Idx)>>> ops = {});
            
            Concept(Concept &&) = default;

            const std::string& Name() const;

            std::vector<std::vector<Idx>> Gen(const std::vector<Idx> & startPoints, std::size_t N);

        protected:
            bool isScalar() const;

            std::size_t GetScalarsCount() const;

            Idx Transform(std::size_t dimId, std::size_t opId, Idx x) const;

            std::vector<Idx> GenSubconceptSpace(std::size_t dimId, Idx start, std::size_t N) const;

            std::vector<Idx> GenSubconceptIndexes(std::size_t dimId, Idx start, const std::vector<Idx> & samplesIndexes) const;

            void Decompose(const std::vector<Idx> & startPoints, const std::vector<Idx> & samplesIndexes, std::size_t dest, std::vector<std::vector<Idx>> & outBuffer) const;

        private:
            std::string _name;
            std::size_t _scalars;
            std::vector<Concept*> _composites;
            std::vector<std::vector<std::function<pt::Idx(pt::Idx)>>> _ops;
    };
}