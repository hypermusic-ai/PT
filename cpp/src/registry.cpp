#include <registry.hpp>

namespace pt
{
    Concept * Registry::ConceptAt(const std::string & name) 
    { 
        if(_concepts.contains(name) == false)return nullptr;
        return _concepts.at(name).get(); 
    }

    Concept const * Registry::ConceptAt(const std::string & name)  const
    { 
        if(_concepts.contains(name) == false)return nullptr;
        return _concepts.at(name).get(); 
    }

    Operand * Registry::OperandAt(const std::string & name)
    {
        if(_operands.contains(name) == false)return nullptr;
        return _operands.at(name).get(); 
    }
    Operand const * Registry::OperandAt(const std::string & name) const
    {
        if(_operands.contains(name) == false)return nullptr;
        return _operands.at(name).get(); 
    }
}