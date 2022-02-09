#!/bin/bash

printf "\nBuild fhir ontology dev image\n"
docker build -t fhir-ontology-dev-container .