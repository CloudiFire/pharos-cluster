#!/bin/sh

set -eu

kubeadm init --ignore-preflight-errors all --skip-token-print --config "${CONFIG}"
