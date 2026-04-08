# Use the official miniforge image as base
FROM condaforge/miniforge3:latest

# Set working directory
WORKDIR /workspace

# Copy environment file
COPY environment.yml .

# Create conda environment from environment.yml
RUN mamba env create -f environment.yml

# Make RUN commands use the new environment
SHELL ["conda", "run", "-n", "arcdocs-aire-jb", "/bin/bash", "-c"]

# Activate environment in bashrc for interactive sessions
RUN echo "conda activate arcdocs-aire-jb" >> ~/.bashrc

# Set default command to bash
CMD ["/bin/bash"]
