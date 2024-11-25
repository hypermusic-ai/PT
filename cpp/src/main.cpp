#include <iostream>

#include <PT.hpp>

struct Pitch : pt::Concept
{
    Pitch(pt::Registry & reg) : pt::Concept(reg, "Pitch")
    {}
};

struct Time : pt::Concept
{
    Time(pt::Registry & reg) : pt::Concept(reg, "Time")
    {}
};

struct Duration : pt::Concept
{
    Duration(pt::Registry & reg) : pt::Concept(reg, "Duration")
    {}
};

struct CnA : pt::Concept
{
    CnA(pt::Registry & reg) : pt::Concept(reg, "CnA", {"Pitch", "Time"})
    {
        OpsCallDef().Push(0, "Add", {1});
        OpsCallDef().Push(0, "Mul", {2});
        OpsCallDef().Push(0, "Add", {3});

        OpsCallDef().Push(1, "Add", {1});
        OpsCallDef().Push(1, "Nop");
        OpsCallDef().Push(1, "Add", {3});

        InitOperands();
    }
};

struct CnB : pt::Concept
{
    CnB(pt::Registry & reg) : pt::Concept(reg, "CnB", {"CnA", "Duration"})
    {
        OpsCallDef().Push(0, "Add", {1});
        OpsCallDef().Push(0, "Mul", {2});
        OpsCallDef().Push(0, "Add", {3});

        OpsCallDef().Push(1, "Add", {1});
        OpsCallDef().Push(1, "Nop");
        OpsCallDef().Push(1, "Add", {3});

        InitOperands();
    }
};

struct Nop : public pt::Operand
{
    Nop(pt::Registry & reg) : pt::Operand(reg, "Nop")
    {}

    pt::Idx operator()(pt::Idx x, const std::vector<int> & args) const override
    {
        assert(args.size() == 0);
        return x;
    }
};

struct Add : public pt::Operand
{
    Add(pt::Registry & reg) : pt::Operand(reg, "Add")
    {}

    pt::Idx operator()(pt::Idx x, const std::vector<int> & args) const override
    {
        assert(args.size() == 1);
        return x + args.at(0);
    }
};

struct Mul : public pt::Operand
{
    Mul(pt::Registry & reg) : pt::Operand(reg, "Mul")
    {}

    pt::Idx operator()(pt::Idx x, const std::vector<int> & args) const override
    {
        assert(args.size() == 1);
        return x * args.at(0);
    }
};

void PrintSamples(const std::vector<std::vector<pt::Idx>> & buffer)
{
    for(const auto & row : buffer)
    {
        for(const auto & sample : row)
        {
            std::cout << sample << " ";
        }
        std::cout<<std::endl;
    }
}

int main(int argc, char* argv[])
{
    asio::io_context ioContext;

    pt::Registry reg;

    reg.Register<Nop>();
    reg.Register<Add>();
    reg.Register<Mul>();

    reg.Register<Pitch>();
    reg.Register<Time>();
    reg.Register<Duration>();
    reg.Register<CnA>();
    reg.Register<CnB>();

    auto buffer = pt::Gen(reg, "CnA", {7}, 20);
    PrintSamples(buffer);

    buffer = pt::Gen(reg, "CnB", {7, 0, 0}, 10);
    PrintSamples(buffer);

    return 0;
}