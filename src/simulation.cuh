#pragma once

#include <vector>
#include <cuda_runtime.h>
#include "particle.h"
#include <SFML/Graphics.hpp>

void compute(std::vector<Particle>& particles, int screenSize, int totalParticles, sf::Vector2i mousePos);

std::vector<Particle> createParticles(int totalParticles, int screenSize);