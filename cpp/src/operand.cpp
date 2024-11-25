#include <operand.hpp>

namespace pt
{
    Operand::Operand(pt::Registry & reg, std::string name)
    : _reg{reg}, _name{std::move(name)}
    {
    }

    const std::string& Operand::Name() const 
    { 
        return _name;
    }
}