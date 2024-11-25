#pragma once

#include <string>
#include <unordered_map>
#include <memory>
#include <concepts>

#include <concept-fwd.hpp>
#include <operand-fwd.hpp>

namespace pt
{
    class Registry
    {
        public:
            Registry() = default;

            template<class ConceptType> requires std::is_base_of<Concept, ConceptType>::value
            bool Register() 
            { 
                auto cn = std::make_unique<ConceptType>(*this);
                return _concepts.emplace(cn->Name(), std::move(cn)).second; 
            }

            template<class OperandType> requires std::is_base_of<Operand, OperandType>::value
            bool Register() 
            { 
                auto op = std::make_unique<OperandType>(*this);
                return _operands.emplace(op->Name(), std::move(op)).second; 
            }

            Concept * ConceptAt(const std::string & name);
            Concept const * ConceptAt(const std::string & name) const;

            Operand * OperandAt(const std::string & name);
            Operand const * OperandAt(const std::string & name) const;
        private:
            std::unordered_map<std::string, std::unique_ptr<Operand>> _operands;
            std::unordered_map<std::string, std::unique_ptr<Concept>> _concepts;
    };
}