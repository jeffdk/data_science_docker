#!/bin/bash


sudo docker run --env-file ./envfile -it -v `pwd`/tosin:/home/rstudio jeffdk/test:v7
