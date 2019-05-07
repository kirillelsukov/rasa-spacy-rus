FROM continuumio/miniconda3
LABEL maintainer="https://github.com/ex00/"

ENV PROJECT_DIR=/example_spacy_ru_project
RUN mkdir $PROJECT_DIR

WORKDIR /
#istall components for ru2 
RUN conda install -y -c conda-forge spacy==2.0.12
RUN pip install pymorphy2==0.8
RUN git clone https://github.com/buriy/spacy-ru.git
RUN cp -r /spacy-ru/ru2/. $PROJECT_DIR/ru2


ADD  ./examples/full_simple_example.py $PROJECT_DIR/
RUN conda install -y -c conda-forge pandas tabulate # install packages for example 
WORKDIR $PROJECT_DIR
CMD python full_simple_example.py

FROM python:3.6-slim as builder

WORKDIR /build
COPY . .
RUN python rasa_setup.py sdist bdist_wheel
RUN find dist -maxdepth 1 -mindepth 1 -name '*.tar.gz' -print0 | xargs -0 -I {} mv {} rasa.tar.gz

FROM python:3.6-slim

SHELL ["/bin/bash", "-c"]

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  build-essential \
  wget \
  openssh-client \
  graphviz-dev \
  pkg-config \
  git-core \
  openssl \
  libssl-dev \
  libffi6 \
  libffi-dev \
  libpng-dev \
  libpq-dev \
  curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  mkdir /install

WORKDIR /install

# Copy as early as possible so we can cache ...
COPY requirements.txt .

RUN pip install -r requirements.txt --no-cache-dir

COPY --from=builder /build/rasa.tar.gz .
RUN pip install ./rasa.tar.gz[sql]

VOLUME ["/app"]
WORKDIR /app

EXPOSE 5005

ENTRYPOINT ["rasa"]

CMD ["--help"]