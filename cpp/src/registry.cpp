#include <registry.hpp>

namespace pt
{
    Concept * Registry::At(const std::string & name) 
    { 
        if(_concept.contains(name) == false)return nullptr;
        return _concept.at(name).get(); 
    }
}