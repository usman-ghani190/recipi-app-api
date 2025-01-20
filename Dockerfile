# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster
LABEL maintainer="ghani5511"

# Set the Python environment to unbuffered to avoid buffering issues with logs
ENV PYTHONUNBUFFERED=1
ENV DOCKER_VS_CODE_SERVER=false

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    postgresql-client \
    libpq-dev \
    build-essential \
    python3-pip \
    && apt-get clean

# Ensure /tmp exists with proper permissions (world-writable)
RUN mkdir -p /tmp && chmod 1777 /tmp

# Copy the requirements files into the container
COPY requirements.txt /tmp/requirements.txt
COPY requirements.dev.txt /tmp/requirements.dev.txt

# Create a virtual environment
RUN python3 -m venv /py

# Ensure pip is installed in the virtual environment
RUN /py/bin/python -m ensurepip --upgrade && \
    /py/bin/pip install --upgrade pip

# Install the dependencies from requirements.txt
RUN /py/bin/pip install --no-cache-dir -r /tmp/requirements.txt

# If the DEV argument is passed, install the development dependencies as well
ARG DEV=false
RUN if [ "$DEV" = "true" ]; \
    then /py/bin/pip install --no-cache-dir -r /tmp/requirements.dev.txt; \
    fi

# Copy the application code into the container
COPY ./app /app

# Set the working directory inside the container
WORKDIR /app

# Remove the temporary requirements files
RUN rm -rf /tmp

# Clean up unnecessary build dependencies (Ensure /tmp is writable before this step)
RUN mkdir -p /tmp && chmod 1777 /tmp && \
    apt-get remove --purge -y build-essential libpq-dev && apt-get clean

# Create a non-root user to run the app
RUN adduser --disabled-password --no-create-home django-user && \
    mkdir -p /home/django-user && \
    chown -R django-user:django-user /home/django-user /py /app

# Set the path to the virtual environment
ENV PATH="/py/bin:$PATH"

# Switch to the non-root user
USER django-user

# Expose port 8000 for Django development server
EXPOSE 8000

# Start the Django development server
CMD ["/py/bin/python", "manage.py", "runserver", "0.0.0.0:8000"]
