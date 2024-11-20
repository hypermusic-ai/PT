#pragma once

#include <string>
#include <unordered_map>
#include <memory>

#include <concept-fwd.hpp>

namespace pt
{
    class Registry
    {
        public:
            Registry() = default;

            template<class ConceptType>
            bool Register() 
            { 
                auto cn = std::make_unique<ConceptType>(*this);
                return _concept.emplace(cn->Name(), std::move(cn)).second; 
            }

            Concept * At(const std::string & name);

        private:
            std::unordered_map<std::string, std::unique_ptr<Concept>> _concept;
    };
}