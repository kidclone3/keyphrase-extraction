FROM ubuntu:18.04 

RUN apt-get update && \
    apt-get install -y python3-pip python3-dev build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Java for Stanford Tagger
RUN apt-get update && \
    apt-get install -y openjdk-8-jre && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# Set environment
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH ${PATH}:${JAVA_HOME}/bin

# Download CoreNLP full Stanford Tagger for English
# Uncomment the following lines if you want to download CoreNLP
# RUN wget http://nlp.stanford.edu/software/stanford-corenlp-full-2018-02-27.zip && \
#     unzip stanford-corenlp-full-2018-02-27.zip && \
#     rm stanford-corenlp-full-2018-02-27.zip
ADD stanford-corenlp-4.5.3 stanford-corenlp

ENV PIP_ROOT_USER_ACTION=ignore
# Install sent2vec
RUN apt update && \
    apt-get install -y git g++ make && \
    git clone https://github.com/epfml/sent2vec && \
    cd sent2vec && \
    git checkout 9efbc2dd69f6c737c3a752c9dc5fbb4843d578b6
WORKDIR /sent2vec
RUN apt-get install -y libevent-pthreads-2.1-6
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN pip3 install .
RUN make

# Install requirements
WORKDIR /app
ADD requirements.txt .
# Remove NumPy and SciPy from the requirements before installing the rest
RUN cd /app && \
    # sed -i '/^numpy.*$/d' requirements.txt && \
    # sed -i '/^scipy.*$/d' requirements.txt && \
    pip3 install --no-cache-dir -r requirements.txt

# Download NLTK data
RUN python3 -c "import nltk; nltk.download('punkt')"

# Set the paths in config.ini
ADD config.ini.template config.ini
RUN sed -i '6 c\host = localhost' config.ini && \
    sed -i '7 c\port = 9000' config.ini && \
    sed -i '10 c\model_path = /sent2vec/pretrained_model.bin' config.ini

# Add actual source code
ADD swisscom_ai swisscom_ai/
ADD launch.py .

ENTRYPOINT ["/bin/sh"]