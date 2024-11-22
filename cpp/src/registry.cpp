#include <registry.hpp>

namespace pt
{
    Concept * Registry::At(const std::string & name) 
    { 
        if(_concepts.contains(name) == false)return nullptr;
        return _concepts.at(name).get(); 
    }
}