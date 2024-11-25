#pragma once

#include <string>
#include <vector>
#include <algorithm>
#include <functional>
#include <iostream>
#include <format>

#include <registry.hpp>
#include <operand.hpp>
#include <index.hpp>

namespace pt
{
    class Concept
    {
        public:
            Concept(pt::Registry & reg, std::string name, std::vector<std::string> composites = {});
            Concept(Concept &&) = default;
            virtual ~Concept() = default;

            const std::string & Name() const;

            std::vector<std::vector<Idx>> Gen(const std::vector<Idx> & startPoints, std::size_t N) const;

        protected:
            bool isScalar() const;

            std::size_t GetScalarsCount() const;
            std::size_t GetCompositesCount() const;
            std::size_t GetSubTreeCount() const;

            Idx Transform(std::size_t dimId, std::size_t opId, Idx x) const;

            std::vector<Idx> GenSubconceptSpace(std::size_t dimId, Idx start, std::size_t N) const;

            std::vector<Idx> GenSubconceptIndexes(std::size_t dimId, Idx start, const std::vector<Idx> & samplesIndexes) const;

            void Decompose(const std::vector<Idx> & startPoints, std::size_t startPointId, const std::vector<Idx> & samplesIndexes, std::size_t dest, std::vector<std::vector<Idx>> & outBuffer) const;
        
        protected:
            CallDef & OpsCallDef();
            void InitOperands();
        private:
            pt::Registry & _reg;
            std::string _name;
            std::size_t _scalars;
            std::size_t _subTreeSize;
            std::vector<Concept*> _composites;
            std::vector<std::vector<Operand*>> _operands;
            CallDef _opsCallDef;
    };
}