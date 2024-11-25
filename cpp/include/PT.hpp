#pragma once

#include <native.hpp>
#include <concept.hpp>
#include <operand.hpp>
#include <registry.hpp>
#include <network.hpp>

#include <asio.hpp>

namespace pt
{
    std::vector<std::vector<Idx>> Gen(const pt::Registry & reg, const std::string & name, const std::vector<pt::Idx> startPoints, std::size_t N)
    {
        const Concept * const cn = reg.ConceptAt(name);
        if(cn == nullptr)return {};
        return cn->Gen(startPoints, N);
    }
}