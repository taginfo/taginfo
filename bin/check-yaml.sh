#!/bin/bash

yamllint \
    -d "{extends: relaxed, rules: {line-length: disable}}" \
    web/i18n/*yml

