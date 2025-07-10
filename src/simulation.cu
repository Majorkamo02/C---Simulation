#include <iostream>
#include <cuda_runtime.h>
#include <vector>
#include <random>
#include <iostream>
#include <chrono>
#include <SFML/Graphics.hpp>
#include "particle.h"
#include <algorithm>
#include <math_constants.h>

using namespace std;
__global__ void resetDensity(Particle* particles, int size)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index >= size) return;
    particles[index].density = 0;
}

//__________________________________________________________________________________________________________________________________________________________________________________
// Kernel to compute interactions of every particle to every other particle using parallel computation
__global__ void collisionKernel(Particle* particles, int size)
{
    int threadNum = blockIdx.x * blockDim.x + threadIdx.x;                                      // Set the index of own particle and other particle
    int i = threadNum / size;                                                                   
    int j = threadNum % size;

    if (i >= size || j >= size || i == j) return;                                               // Checking if out of range or self

    float dx = particles[i].pos.x - particles[j].pos.x;                                         // Diff in x
    float dy = particles[i].pos.y - particles[j].pos.y;                                         // Diff in y

    float r2 = dx * dx + dy * dy;                                                         //
    float h = 20.0f;                                                                            // Radius of effect
    float h2 = h * h;                                                                           //

    if (r2 < h2) {
        float diff = h2 - r2;
        float poly6Coeff = 4.0f / (CUDART_PI_F * powf(h, 8.0f));
        float influence = poly6Coeff * powf(h2,3);

        atomicAdd(&particles[i].density, influence);
    }
}

//__________________________________________________________________________________________________________________________________________________________________________________
// Kernel to compute local physics like wall collisions or gravity to save on resources
__global__ void generalKenel(Particle* particles, int size, int threadPerBlock, int screenSize, int mouseX, int mouseY)
{
    float gravity = 0;
    int index = blockIdx.x * blockDim.x + threadIdx.x;                                          // Compute index (directly correlated to particle in particles)
    if(index<size){
        // Keep particles in bounds
        if (particles[index].pos.x <= 0){
            particles[index].pos.x = 0;
            particles[index].vel.x *= -.9;
        }else if (particles[index].pos.x >= screenSize)
        {
            particles[index].pos.x = screenSize;
            particles[index].vel.x *= -.9;
        }else if (particles[index].pos.y <= 0)
        {
            particles[index].pos.y = 0;
            particles[index].vel.y *= -.9;
        }else if (particles[index].pos.y >= screenSize-1)
        {
            particles[index].pos.y = screenSize-1;
            particles[index].vel.y *= -.9;
        }
        // Apply Gravity
        particles[index].vel.y -= gravity;
        //update position based on velocity
        particles[index].pos.x += particles[index].vel.x;   
        particles[index].pos.y += particles[index].vel.y; 
    }  
}

//__________________________________________________________________________________________________________________________________________________________________________________

void compute(vector<Particle>& particles, int screenSize, int totalParticles, sf::Vector2i mousePos){

    int size = particles.size();


    Particle* dParticles;                                                                   // Create empty pointer that will hold pointer to gpu mem
    cudaMalloc(&dParticles, size*sizeof(Particle));                                         // Allocate space in gpu mem and store pointer to it in dParticles
    cudaMemcpy(dParticles,particles.data(),size*sizeof(Particle),cudaMemcpyHostToDevice);   // Copy over data into space allocated at the space dParticles points to 
    

    // Compute how many threads/blocks will be needed
    int threadPerBlock = 1024;
    int numBlocksCollision = totalParticles*totalParticles/threadPerBlock+1;
    int numBlocksGen = totalParticles/threadPerBlock+1;


    // Send to gpu to compute
    resetDensity<<<numBlocksGen, threadPerBlock>>>(dParticles, size);
    cudaDeviceSynchronize();

    collisionKernel<<<numBlocksCollision, threadPerBlock>>>(dParticles, size);
    cudaDeviceSynchronize();

    generalKenel<<<numBlocksGen, threadPerBlock>>>(dParticles, size,threadPerBlock, screenSize, mousePos.x, mousePos.y);
    cudaDeviceSynchronize();                                                                // Wait for GPU to finish before accessing results
    

    cudaMemcpy(particles.data(),dParticles,size*sizeof(Particle),cudaMemcpyDeviceToHost);
    cudaFree(dParticles);

    for (size_t i = 0; i < particles.size(); i++)
    {
        float normalizedDensity = min(particles[i].density*4000.0f, 255.0f);
        unsigned char colorValue = static_cast<unsigned char>(normalizedDensity);

        // Set color: Red base, green intensity changes with density
        particles[i].circle.color.r = 255;
        particles[i].circle.color.g = colorValue;
        particles[i].circle.color.b = 0;
    }
}

//__________________________________________________________________________________________________________________________________________________________________________________

vector<Particle> createParticles(int totalParticles, int screenSize){
    random_device rd;
    mt19937 gen(rd());
    uniform_real_distribution<float> posDistrib(0, screenSize); // random positions
    uniform_real_distribution<float> velDistrib(-1.f, 1.f);   // random velocities

    vector<Particle> particles;
    particles.reserve(totalParticles);

    for (int i = 0; i < totalParticles; i++) {

        float xpos = posDistrib(gen);
        float ypos = posDistrib(gen);
        float xvel = velDistrib(gen);
        float yvel = velDistrib(gen);
        particles.emplace_back(Particle({xpos, ypos}, {xvel, yvel}));
    }

    return particles;
}

// vector<Particle> createParticles(int totalParticles, int screenSize) {
//     const int spacing = 7; // space between particles in pixels

//     // Estimate grid size (try to make it as square as possible)
//     int cols = static_cast<int>(sqrt(totalParticles));
//     int rows = (totalParticles + cols - 1) / cols; // round up

//     vector<Particle> particles;
//     particles.reserve(totalParticles);

//     // Center the grid on screen
//     int gridWidth = cols * spacing;
//     int gridHeight = rows * spacing;
//     int startX = (screenSize - gridWidth) / 2;
//     int startY = (screenSize - gridHeight) / 2;

//     for (int i = 0; i < totalParticles; ++i) {
//         int row = i / cols;
//         int col = i % cols;

//         float xpos = startX + col * spacing;
//         float ypos = startY + row * spacing;

//         float xvel = 0;
//         float yvel = 0;

//         particles.emplace_back(Particle({xpos, ypos}, {xvel, yvel}));
//     }

//     return particles;
// }
//__________________________________________________________________________________________________________________________________________________________________________________