#pragma once
#include <vector>
#include <cassert>
#include <string>

#include <registry.hpp>
#include <index.hpp>

namespace pt
{
    class CallDef
    {
        public:
        CallDef(std::size_t dims)
        {
            _names.resize(dims);
            _args.resize(dims);
        }

        std::size_t DimensionsCount() const { return _names.size(); }
        std::size_t OperandsCount(std::size_t dimId) const { return _names.at(dimId).size(); }
        const std::vector<int> Args(std::size_t dimId, std::size_t opId) const { return _args.at(dimId).at(opId); }

        const std::string & Name(std::size_t dimId, std::size_t opId)
        {
            return _names.at(dimId).at(opId);
        }

        void Push(std::size_t dimId, std::string name, std::vector<int> args = {})
        {
            assert(dimId < _names.size() && dimId < _args.size());
            _names.at(dimId).emplace_back(std::move(name));
            _args.at(dimId).emplace_back(std::move(args));
        }


        private:
            std::vector<std::vector<std::string>> _names;
            std::vector<std::vector<std::vector<int>>> _args;
    };

    class Operand
    {
        public:
            Operand(pt::Registry & reg, std::string name);
            Operand(Operand && other) = default;
            virtual ~Operand() = default;
            
            virtual Idx operator()(Idx x, const std::vector<int> & args) const = 0;
            const std::string & Name() const;

        private:
            pt::Registry & _reg;
            std::string _name;
    };
}