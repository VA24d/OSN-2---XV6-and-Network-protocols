# Mini Project 2: Operating Systems and Networks

## Overview

This mini-project consists of two main parts:

1. XV6 File Management
2. Networking
    - Part A: Local network TCP and UDP communication
    - Part B: Implementing partial TCP functionality with UDP

- More details about each part are in the dedicated readme files in the respective directories.
- For specs visit the website (Open `.html` file in the `website` directory.)

## Part 1: XV6 File Management

### Description

This part involves working with the XV6 operating system, specifically focusing on file management. The implementation is done in the `src` directory of the `initial-xv6` folder.

### Assumptions

- RISC-V XV6 is used for the implementation.
- All specifications are implemented as per the project requirements.

### Building and Running XV6

To build and run XV6, follow these steps:

1. Ensure you have a RISC-V "newlib" toolchain and QEMU compiled for riscv64-softmmu.
2. Run the following commands:

```sh
make clean
make qemu
```

### Files and Directories

- `initial-xv6/src/`: Contains the source code for the XV6 operating system.
- `README.md`: Provides additional information about the XV6 implementation.

## Part 2: Networks

### Description

#### Part A: Local network TCP and UDP communication

Implementation of a simple tic-tac-toe game using TCP and UDP communication protocols. The implementation is done in the `PART A` directory of the `networks` folder.

#### Part B: Implementing partial TCP functionality with UDP

Implementation of a simple chat using UDP. The implementation is done in the `PART B` directory of the `networks` folder.

### Assumptions

- The implementation is done using C.
- All specifications are implemented as per the project requirements.
