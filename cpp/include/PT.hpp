#pragma once

#if defined _WIN32 || defined _WIN64
    #define WIN32_LEAN_AND_MEAN
    #include <windows.h>
#endif

#include <asio.hpp>

#include <concept.hpp>
#include <operand.hpp>
#include <registry.hpp>

namespace pt
{
    std::vector<std::vector<Idx>> Gen(const pt::Registry & reg, const std::string & name, const std::vector<pt::Idx> startPoints, std::size_t N)
    {
        const Concept * const cn = reg.ConceptAt(name);
        if(cn == nullptr)return {};
        return cn->Gen(startPoints, N);
    }
}