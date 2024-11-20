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
    CnA(pt::Registry & reg) : pt::Concept(reg, "CnA", {"Pitch", "Time"}, 
    {
        {[](pt::Idx x){return x + 2;}, [](pt::Idx x){return x * 3;}},   // Pitch
        {[](pt::Idx x){return x;}, [](pt::Idx x){return x + 1;}}        // Time
    })
    {}
};

struct CnB : pt::Concept
{
    CnB(pt::Registry & reg) : pt::Concept(reg, "CnB", {"CnA", "Duration"}, 
    {
        {[](pt::Idx x){return x * 2;}},   // CnA
        {[](pt::Idx x){return x + 10;}, [](pt::Idx x){return x;}}       // Duration
    })
    {}
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
    pt::Registry reg;

    reg.Register<Pitch>();
    reg.Register<Time>();
    reg.Register<CnA>();
    reg.Register<Duration>();
    reg.Register<CnB>();

    auto buffer = reg.At("CnA")->Gen({1}, 20);
    PrintSamples(buffer);

    buffer = reg.At("CnB")->Gen({1}, 5);
    PrintSamples(buffer);

    return 0;
}