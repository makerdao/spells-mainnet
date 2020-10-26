#!/usr/bin/env bash

seth block $(seth tx ${1}|grep blockNumber|awk '{print $2}')|grep timestamp|awk '{print $2}'