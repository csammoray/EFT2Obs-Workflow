#!/bin/bash
# properties = {properties}

set -e

echo "hostname:"
hostname -f

echo "executing"
{exec_job}
