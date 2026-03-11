#!/bin/bash

if [ -z "$1" ]; then
  echo "Uso: $0 IP_DEL_NODO"
  exit 1
fi

NODE=$1

echo "Probando conectividad con nodo $NODE"
echo "----------------------------------"

echo "TCP 2377 (cluster management)"
nc -zv -w2 $NODE 2377

echo ""
echo "TCP 7946 (node communication)"
nc -zv -w2 $NODE 7946

echo ""
echo "UDP 7946 (node communication)"
nc -zvu -w2 $NODE 7946

echo ""
echo "UDP 4789 (overlay network VXLAN)"
nc -zvu -w2 $NODE 4789

echo ""
echo "Test finalizado"
