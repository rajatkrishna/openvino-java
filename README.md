# OpenVINO with Java bindings

This image builds OpenVINO from source with the Java API bindings. 

OpenVINO is installed to the `/opt/intel/openvino` directory and the jar file can be located within `/opt/intel/openvino/java` directory. 


### Prerequisites 

- Docker: Installation instructions can be found [here](https://docs.docker.com/engine/install/).

### Usage

To build the image, run the following command from the project root:

```
docker build -t openvino-java .
```

Open a bash shell into the container:

```
docker run -it openvino-java /bin/bash
```

Use the `-v` flag to mount your local project folder to the Docker container:

```
docker run -v /local/path:/path/in/container -it openvino-java
```
