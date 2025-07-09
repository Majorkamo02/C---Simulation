#pragma once

#include <SFML/Graphics.hpp>

struct Particle
{
    sf::Vector2f pos;
    sf::Vector2f vel;
    float density;
    int sector;
    float pressure;
    sf::Vertex circle;
    Particle(sf::Vector2f i, sf::Vector2f j):pos(i),vel(j), density(){
        circle.color = sf::Color::White;
        circle.position = pos;
    }


    void updatePos(){
        circle.position = pos;
    }
};

