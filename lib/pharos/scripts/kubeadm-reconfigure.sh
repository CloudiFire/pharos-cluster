#!/bin/sh

set -eu

kubeadm alpha phase certs apiserver --config "${CONFIG}"
kubeadm alpha phase controlplane all --config "${CONFIG}"
kubeadm alpha phase mark-master --config "${CONFIG}"
