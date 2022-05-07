#!/bin/bash
find ./gcf-minecraft-starter -type f | sort | xargs sha256sum | md5sum | awk '{ print $1 }'