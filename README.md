# C++ Particle Simulation

This is a personal exploration of cuda computation and physics simulations. My goal here is to create a semi optimized particle simulation that somewhat follows the way fluids move.

## Setting up

<span style="color:red">VERY IMPORTANT! THIS WILL ONLY WORK ON A CUDA CAPABLE GPU</span>

For this to run properly you will need to install the cuda toolkit and direct it to your version of the nvcc compiler. On top of this, you will also need SFML installed for rendering.

## Running

To run this the CMakeLists file is provided and should only need to be modified to point to where your sfml cmake lib is. other than that it should build and run once those are setup.

